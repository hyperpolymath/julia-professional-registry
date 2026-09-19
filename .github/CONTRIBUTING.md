# Contributing

Thank you for your interest in contributing! We follow a “Dual-Track”
architecture where human-readable documentation lives in the root and
machine-readable policies live in `.machine_readable/`.

## How to Contribute

We welcome contributions in many forms:

- **Code:** Improving the core stack or extensions

- **Documentation:** Enhancing docs or AI manifests

- **Testing:** Adding property-based tests or formal proofs

- **Bug reports:** Filing clear, reproducible issues

## Getting Started

1.  **Read the AI Manifest:** Start with `0-AI-MANIFEST.a2ml` to
    understand the repository structure.

2.  **Environment:** Use `guix` `shell` `-D` `-f` `guix.scm` (or
    `direnv` `allow` if the `.envrc` is honoured) to set up your tools.
    Guix is the canonical packager per
    <a href="https://github.com/hyperpolymath/standards/issues/101"
    id="101">standards</a>; the prior `nix` `develop` fallback was
    retired estate-wide.

3.  **Task Runner:** Use `just` to see available commands (`just`
    `--list`).

## Registering a Package

This repo is a Julia package registry. To register a new package or a
new version:

1.  Confirm the upstream package meets the registry’s quality bar (see
    GOVERNANCE.adoc — SPDX headers, REUSE-compliant `LICENSES/`, OpenSSF
    Scorecard baseline, no banned-language files).

2.  Add or update the relevant per-letter directory (e.g. a new package
    `Foo` lives under `F/Foo/`). Each version directory contains the
    standard Julia registry files: `Package.toml`, `Versions.toml`,
    `Deps.toml`, `Compat.toml`, `WeakCompat.toml`.

3.  Update the top-level `Registry.toml` index.

4.  Open a PR titled `feat(registry):` `register` `<Package>` `v<X.Y.Z>`
    (or `feat(registry):` `add` `<Package>` `v<X.Y.Z>`).

## Development Workflow

### Branch Naming

    docs/short-description       # Documentation
    test/what-added              # Test additions
    feat/short-description       # New features
    fix/issue-number-description # Bug fixes
    refactor/what-changed        # Code improvements
    security/what-fixed          # Security fixes

### Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

    <type>(<scope>): <description>

    [optional body]

    [optional footer]

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `ci`, `chore`,
`security`

## Reporting Bugs

Before reporting: 1. Search existing issues 2. Check if it’s already
fixed in `main`

When reporting, include: - Clear, descriptive title - Environment
details (OS, versions, toolchain) - Steps to reproduce - Expected vs
actual behaviour

## Code of Conduct

All contributors are expected to adhere to our [Code of
Conduct](CODE_OF_CONDUCT.md).

## License

By contributing, you agree that your contributions will be licensed
under the same license as the project (see LICENSE).
