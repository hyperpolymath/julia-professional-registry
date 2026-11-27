<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
## Summary

<!-- Briefly describe what this PR does and why. Link to related issues with "Closes #N". -->

## Changes

<!-- List the key changes introduced by this PR. -->

-

## RSR Quality Checklist

<!-- Check all that apply. PRs that fail required checks will not be merged. -->

### Required

- [ ] No banned language patterns (no TypeScript, no Node.js/yarn (Bun first; Deno, pnpm, npm as fallbacks), no Go, no Python)
- [ ] SPDX license headers present on all new/modified source files
- [ ] No secrets, credentials, or `.env` files included
- [ ] CI is green (governance, hypatia-scan, codeql, scorecard, secret-scanner)

### As Applicable — Registry Changes

- [ ] `Registry.toml` index updated when a package or version was added
- [ ] Per-package `Package.toml` / `Versions.toml` / `Deps.toml` / `Compat.toml` consistent
- [ ] Upstream package meets the quality bar in [GOVERNANCE.adoc](../GOVERNANCE.adoc)
- [ ] Upstream tag exists and matches the registered version

### As Applicable — Documentation / Infra Changes

- [ ] `.machine_readable/6a2/STATE.a2ml` updated (if project state changed)
- [ ] `.machine_readable/6a2/ECOSYSTEM.a2ml` updated (if integrations changed)
- [ ] `.machine_readable/6a2/META.a2ml` updated (if architectural decisions changed)
- [ ] `TOPOLOGY.md` updated (if architecture changed)
- [ ] `CHANGELOG.md` updated (or pending auto-generation from conventional commits)
- [ ] Wiki updated for user-facing changes

## Testing

<!-- Describe how you tested these changes. For registrations, include the `Pkg.Registry.add` + `Pkg.add` sequence you used. -->
