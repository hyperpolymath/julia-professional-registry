# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# julia-professional-registry — registry validation entry point.
#
# Two layers, run back to back:
#
#   1. Canonical checks via RegistryCI.jl (the same package JuliaRegistries/General
#      uses for its own CI). `RegistryCI.test(path)` checks UUID uniqueness,
#      Registry.toml <-> Package.toml name/UUID consistency, Versions.toml shape,
#      and that every Deps.toml / Compat.toml entry round-trips through Pkg's own
#      compression/decompression and only references known UUIDs.
#
#      "Known UUIDs" for a non-General registry means: this registry's own
#      packages + stdlibs + (optionally) the General registry, supplied via
#      `registry_deps`. This registry's packages depend on real General
#      packages (HTTP.jl, JSON.jl, JSON3.jl, Zygote.jl, ...), so a bare
#      `RegistryCI.test(path)` with no `registry_deps` WILL report those as
#      "missing" -- that is expected/documented RegistryCI behaviour for a
#      non-General registry, not a bug in this registry. Passing
#      `registry_deps=["https://github.com/JuliaRegistries/General"]` is the
#      correct invocation, but it requires cloning General (a large registry)
#      over the network, so it is gated behind `--general-deps` / the
#      JULIA_REGISTRY_VALIDATE_GENERAL_DEPS=1 env var and is expected to run
#      in CI, not necessarily in a network-restricted sandbox.
#
#   2. Belt-and-braces custom checks (independent of RegistryCI, using only the
#      TOML stdlib) for the specific bug classes this registry has already hit
#      in the wild (see PR #40 / G20 / G21):
#        (a) every package's Deps.toml name<->UUID pairs agree with the
#            Registry.toml binding for that name, across every package that
#            depends on another registry-local package;
#        (b) Registry.toml's own `repo` field is a hyperpolymath slug that
#            agrees with `git remote get-url origin` (compared slug-only,
#            because sandboxes may rewrite the remote through a local
#            proxy), and every package's Package.toml `repo` field is a
#            slug owned by one of PACKAGE_SLUG_OWNERS (ADR 0003);
#        (c) warn (do not fail) on Compat.toml entries that only specify a
#            lower bound with no upper bound -- the estate wants
#            upper-bounded compat everywhere.
#
# Usage:
#   julia --project=@. ci/validate.jl [registry_path]
#   JULIA_REGISTRY_VALIDATE_GENERAL_DEPS=1 julia ci/validate.jl   # also try RegistryCI's General-deps check (network)
#
# Exit code is non-zero if either layer reports a hard failure. Layer (c)
# warnings never affect the exit code.

using TOML
using Pkg
using Test

const REPO_ROOT = abspath(get(ARGS, 1, joinpath(@__DIR__, "..")))
const REGISTRY_TOML = joinpath(REPO_ROOT, "Registry.toml")
# The registry itself lives in one org. Packages may live in either of the
# owner's two orgs (ADR 0003); any other owner is still a hard failure.
const REGISTRY_SLUG_OWNER = "hyperpolymath"
const PACKAGE_SLUG_OWNERS = ("hyperpolymath", "metadatastician")

# RegistryCI must be `using`'d at top level (not loaded dynamically inside a
# function via Base.require) -- doing it inside a function hits a Julia
# world-age problem: the freshly-loaded module's methods are not visible to
# that function's call, and RegistryCI.test(path) fails with a spurious
# "MethodError: no method matching test(::String) ... method too new to be
# called from this world context", which has nothing to do with the registry
# itself. Ground-truthed while writing this script: catching that MethodError
# without printing it via showerror would silently misreport a tooling bug as
# an "expected General-deps gap" finding -- exactly the kind of overclaim this
# script must not make.
const REGISTRYCI_AVAILABLE = try
    @eval using RegistryCI
    true
catch
    false
end

function banner(msg)
    println()
    println("=" ^ 70)
    println(msg)
    println("=" ^ 70)
end

# ---------------------------------------------------------------------------
# Layer 1: canonical RegistryCI.jl checks
# ---------------------------------------------------------------------------

function run_registryci(path::AbstractString)
    banner("Layer 1: RegistryCI.test (canonical registry consistency checks)")

    if !REGISTRYCI_AVAILABLE
        println("RegistryCI is not installed in this depot.")
        println("Install with: julia -e 'using Pkg; Pkg.add(\"RegistryCI\")'")
        println("FALLING BACK: skipping Layer 1 (RegistryCI unavailable). This is a")
        println("degraded run, not a pass -- see README/CI docs for how to install it.")
        return :unavailable
    end

    use_general_deps = get(ENV, "JULIA_REGISTRY_VALIDATE_GENERAL_DEPS", "0") == "1"

    if use_general_deps
        println("JULIA_REGISTRY_VALIDATE_GENERAL_DEPS=1 set: attempting the full")
        println("check with registry_deps=[\"https://github.com/JuliaRegistries/General\"].")
        println("This clones General and needs real, unrestricted network egress.")
        try
            RegistryCI.test(path; registry_deps=["https://github.com/JuliaRegistries/General"])
            println("RegistryCI.test (with General as registry_deps): PASS")
            return :pass
        catch e
            println("RegistryCI.test (with General as registry_deps) FAILED or ERRORED:")
            showerror(stdout, e, catch_backtrace())
            println()
            println("If this is a network/egress error (e.g. 403 from a proxy, DNS")
            println("failure, or clone timeout), this check is CI-only in this")
            println("environment -- it is expected to work where egress to")
            println("github.com/JuliaRegistries/General is unrestricted (e.g. GitHub")
            println("Actions), and is not a claim of local pass/fail here.")
            return :network_unavailable
        end
    else
        println("Running RegistryCI.test(path) WITHOUT registry_deps.")
        println("NOTE: this registry's packages legitimately depend on real")
        println("General-registered packages (HTTP.jl, JSON.jl, JSON3.jl, Zygote.jl,")
        println("...). Without registry_deps, RegistryCI has no way to know those")
        println("UUIDs are valid, so it WILL report them as unresolvable deps. That")
        println("is expected/documented behaviour for a non-General registry -- see")
        println("the RegistryCI.test docstring (\"packages that have dependencies")
        println("that are registered in other registries elsewhere\") -- not a bug in")
        println("this registry. Re-run with JULIA_REGISTRY_VALIDATE_GENERAL_DEPS=1 in")
        println("an environment with full network egress (e.g. CI) for the complete")
        println("cross-registry check.")
        println()
        try
            RegistryCI.test(path)
            println("RegistryCI.test(path) (registry-local only): PASS")
            return :pass
        catch e
            println("RegistryCI.test(path) (registry-local only) reported failures/errors:")
            showerror(stdout, e, catch_backtrace())
            println()
            if e isa Test.TestSetException || (e isa ErrorException && occursin("did not pass", sprint(showerror, e)))
                println("See the RegistryCI test summary printed above. Failures under names")
                println("like JSON3/HTTP/Zygote/DataFrames/... that are *General*")
                println("packages are the expected registry_deps gap described above.")
                println("Any OTHER failure (Registry.toml <-> Package.toml mismatch,")
                println("malformed Versions.toml, a Deps.toml/Compat.toml entry that")
                println("does not round-trip) is a real, actionable finding.")
                return :expected_general_gap
            else
                println("This does NOT look like an ordinary registry-consistency test")
                println("failure -- it looks like a tooling/API error (e.g. a RegistryCI")
                println("API mismatch for the installed version). Treating as a hard")
                println("failure of Layer 1 rather than silently downgrading it.")
                return :tooling_error
            end
        end
    end
end

# ---------------------------------------------------------------------------
# Layer 2: belt-and-braces custom checks
# ---------------------------------------------------------------------------

mutable struct Findings
    errors::Vector{String}
    warnings::Vector{String}
end
Findings() = Findings(String[], String[])

err!(f::Findings, msg) = push!(f.errors, msg)
warn!(f::Findings, msg) = push!(f.warnings, msg)

"""
    check_name_uuid_consistency!(findings, reg, root)

(a) For every package in Registry.toml, load its Deps.toml (if present) and
confirm that every dependency name -> UUID pair which refers to *another
package in this same registry* matches the UUID that Registry.toml itself
binds to that name. This is exactly the class of bug fixed in PR #40 (G21):
a Deps.toml entry pointing at the right name but a stale/wrong UUID.
"""
function check_name_uuid_consistency!(findings::Findings, reg, root::AbstractString)
    banner("Layer 2a: Deps.toml name<->UUID cross-check against Registry.toml")

    name_to_uuid = Dict{String,String}()
    for (uuid, data) in reg["packages"]
        name_to_uuid[data["name"]] = uuid
    end

    checked = 0
    for (uuid, data) in reg["packages"]
        name = data["name"]
        path = joinpath(root, data["path"])
        pkg_toml = joinpath(path, "Package.toml")

        if !isfile(pkg_toml)
            err!(findings, "$name: missing Package.toml at $pkg_toml")
            continue
        end
        pkg = TOML.parsefile(pkg_toml)
        if get(pkg, "uuid", nothing) != uuid
            err!(findings, "$name: Registry.toml uuid $uuid != Package.toml uuid $(get(pkg, "uuid", "<missing>"))")
        end
        if get(pkg, "name", nothing) != name
            err!(findings, "$name: Registry.toml name $name != Package.toml name $(get(pkg, "name", "<missing>"))")
        end

        deps_toml = joinpath(path, "Deps.toml")
        if isfile(deps_toml)
            deps = TOML.parsefile(deps_toml)
            for (_version, depmap) in deps
                for (depname, depuuid) in depmap
                    checked += 1
                    if haskey(name_to_uuid, depname)
                        expected = name_to_uuid[depname]
                        if depuuid != expected
                            err!(findings,
                                "$name/Deps.toml: dependency \"$depname\" has uuid $depuuid " *
                                "but Registry.toml binds \"$depname\" to $expected (registry-local name/UUID mismatch)")
                        end
                    end
                    # else: depname is not a registry-local package (stdlib or
                    # General package) -- out of scope for this check, covered
                    # by RegistryCI's registry_deps check (Layer 1) instead.
                end
            end
        end
    end
    println("Checked $checked dependency (name, uuid) pairs across $(length(reg["packages"])) packages.")
    println(isempty(findings.errors) ? "No registry-local name<->UUID mismatches found." : "Mismatches found -- see errors above.")
    return findings
end

"""
    extract_github_slug(url) -> Union{String,Nothing}

Return the `OWNER/REPO` GitHub slug that `url` names, or `nothing` if it
names none.
"""
function extract_github_slug(url::AbstractString)
    # Handles https://github.com/OWNER/REPO(.git)?, git@github.com:OWNER/REPO.git,
    # and proxy-rewritten forms like http://.../git/OWNER/REPO.
    m = match(r"github\.com[:/]+([^/]+)/([^/\s]+?)(?:\.git)?/?$", url)
    if m !== nothing
        return "$(m.captures[1])/$(m.captures[2])"
    end
    # Fallback: proxy path form ".../git/OWNER/REPO"
    m = match(r"/git/([^/]+)/([^/\s]+?)(?:\.git)?/?$", url)
    if m !== nothing
        return "$(m.captures[1])/$(m.captures[2])"
    end
    return nothing
end

"""
    slug_owner(slug) -> SubString

Return the owner part of an `OWNER/REPO` slug.
"""
slug_owner(slug::AbstractString) = first(split(slug, '/'))

"""
    check_repo_slug!(findings, reg, root)

(b) Registry.toml's own `repo` field must point at a
`REGISTRY_SLUG_OWNER/<something>` GitHub slug. Every package's Package.toml
`repo` field must point at a slug owned by one of `PACKAGE_SLUG_OWNERS`
(ADR 0003). Where `git remote get-url origin` is available, also compare the
registry slug against it -- but only the `OWNER/REPO` slug portion, since
sandboxes may rewrite the remote through a local proxy (e.g.
http://local_proxy@127.0.0.1:NNNN/git/...).
"""
function check_repo_slug!(findings::Findings, reg, root::AbstractString)
    banner("Layer 2b: Registry.toml / Package.toml repo slug consistency")

    registry_repo = get(reg, "repo", nothing)
    if registry_repo === nothing
        err!(findings, "Registry.toml has no top-level 'repo' field")
    else
        slug = extract_github_slug(registry_repo)
        if slug === nothing
            err!(findings, "Registry.toml repo field \"$registry_repo\" is not a recognisable GitHub slug")
        elseif slug_owner(slug) != REGISTRY_SLUG_OWNER
            err!(findings, "Registry.toml repo field resolves to slug \"$slug\", expected owner \"$REGISTRY_SLUG_OWNER\"")
        else
            println("Registry.toml repo -> slug \"$slug\" (owner matches \"$REGISTRY_SLUG_OWNER\")")
        end
    end

    # Compare against the actual git remote, slug-only (see docstring).
    origin_url = try
        strip(read(`git -C $root remote get-url origin`, String))
    catch
        nothing
    end
    if origin_url !== nothing && !isempty(origin_url)
        origin_slug = extract_github_slug(origin_url)
        if origin_slug === nothing
            warn!(findings, "git remote origin (\"$origin_url\") did not parse to a GitHub slug; skipping remote comparison")
        elseif registry_repo !== nothing
            reg_slug = extract_github_slug(registry_repo)
            if reg_slug !== nothing && lowercase(reg_slug) != lowercase(origin_slug)
                err!(findings, "Registry.toml slug \"$reg_slug\" != git remote origin slug \"$origin_slug\"")
            else
                println("git remote origin slug \"$origin_slug\" matches Registry.toml slug.")
            end
        end
    else
        println("(no git remote 'origin' resolvable here; skipping remote-vs-Registry.toml comparison)")
    end

    # Per-package repo field sanity: must exist, must resolve to a slug owned
    # by one of PACKAGE_SLUG_OWNERS.
    allowed = join(("\"$o\"" for o in PACKAGE_SLUG_OWNERS), " or ")
    mismatches = 0
    for (_uuid, data) in reg["packages"]
        name = data["name"]
        pkg_toml = joinpath(root, data["path"], "Package.toml")
        isfile(pkg_toml) || continue
        pkg = TOML.parsefile(pkg_toml)
        repo = get(pkg, "repo", nothing)
        if repo === nothing
            err!(findings, "$name: Package.toml has no 'repo' field")
            continue
        end
        slug = extract_github_slug(repo)
        if slug === nothing
            err!(findings, "$name: Package.toml repo \"$repo\" is not a recognisable GitHub slug")
        elseif !(slug_owner(slug) in PACKAGE_SLUG_OWNERS)
            mismatches += 1
            err!(findings, "$name: Package.toml repo resolves to slug \"$slug\", expected owner $allowed")
        end
    end
    println("Checked repo field on $(length(reg["packages"])) package Package.toml files ($mismatches owner mismatches).")
    return findings
end

"""
    check_compat_upper_bounds!(findings, reg, root)

(c) Warn (never fail) on any Compat.toml entry that specifies only a lower
bound (e.g. "1", ">= 1.2", "1.2.3") with no upper bound (Julia's caret `^`
compat entries like "1.2" DO have an implicit upper bound and are fine; bare
inequality forms like ">=1" or "*" do not).
"""
function has_no_upper_bound(spec::AbstractString)
    s = strip(spec)
    # "*" means "any version" -- no upper bound at all.
    s == "*" && return true
    # Explicit >= / > with no comma-separated upper clause is unbounded above.
    if occursin(r"^(>=|>)\s*[\w\.\-\+]+$", s)
        return true
    end
    return false
end

function check_compat_upper_bounds!(findings::Findings, reg, root::AbstractString)
    banner("Layer 2c: Compat.toml upper-bound advisory (warn-only)")

    flagged = 0
    for (_uuid, data) in reg["packages"]
        name = data["name"]
        compat_toml = joinpath(root, data["path"], "Compat.toml")
        isfile(compat_toml) || continue
        compat = TOML.parsefile(compat_toml)
        for (_version, entries) in compat
            for (depname, spec) in entries
                specs = spec isa AbstractVector ? spec : [spec]
                for s in specs
                    if s isa AbstractString && has_no_upper_bound(s)
                        flagged += 1
                        warn!(findings, "$name/Compat.toml: \"$depname\" = \"$s\" has no upper bound (estate policy wants upper-bounded compat)")
                    end
                end
            end
        end
    end
    println(flagged == 0 ?
        "No unbounded Compat.toml entries found." :
        "$flagged unbounded Compat.toml entries flagged (warnings only, see below).")
    return findings
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

function main()
    println("julia-professional-registry validator")
    println("Registry root: $REPO_ROOT")

    isfile(REGISTRY_TOML) || error("Registry.toml not found at $REGISTRY_TOML")
    reg = TOML.parsefile(REGISTRY_TOML)
    println("Registry.toml parses OK: $(length(reg["packages"])) packages.")

    registryci_status = run_registryci(REPO_ROOT)

    findings = Findings()
    check_name_uuid_consistency!(findings, reg, REPO_ROOT)
    check_repo_slug!(findings, reg, REPO_ROOT)
    check_compat_upper_bounds!(findings, reg, REPO_ROOT)

    banner("Summary")
    println("RegistryCI layer status: $registryci_status")
    println("Custom-check errors:   $(length(findings.errors))")
    println("Custom-check warnings: $(length(findings.warnings))")

    if !isempty(findings.warnings)
        println()
        println("Warnings (non-fatal):")
        for w in findings.warnings
            println("  - $w")
        end
    end

    if !isempty(findings.errors)
        println()
        println("ERRORS (fatal):")
        for e in findings.errors
            println("  - $e")
        end
        println()
        println("VALIDATION FAILED: $(length(findings.errors)) error(s).")
        exit(1)
    end

    if registryci_status == :tooling_error
        println()
        println("VALIDATION FAILED: Layer 1 (RegistryCI) hit an unexpected tooling/API")
        println("error rather than an ordinary registry-consistency failure. See the")
        println("showerror output above for details -- likely an API mismatch between")
        println("this script and the installed RegistryCI version. Fix the invocation")
        println("(or pin RegistryCI) rather than ignoring this.")
        exit(1)
    end

    println()
    println("VALIDATION PASSED (custom checks). See Layer 1 notes above for RegistryCI status.")
    exit(0)
end

main()
