<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk> -->

# Copilot Instructions

## Before Writing Code

- Read `0-AI-MANIFEST.a2ml` in the repo root for canonical file locations.
- State files (`*.a2ml`) live in `.machine_readable/6a2/` ONLY, never the root.
- Registry data is structured per the Julia package registry format: `Registry.toml` at the root, per-letter directories (`A/`, `B/`, ...) each containing per-package subdirs with `Package.toml` / `Versions.toml` / `Deps.toml` / `Compat.toml`.

## License

- SPDX: `MPL-2.0` on all new files.
- Never use AGPL-3.0.
- Copyright: `Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>`.

## Code Style

- Annotate and document all files.
- Add SPDX header to every source file (Julia, AsciiDoc, Markdown, TOML where comments are supported).
- Use `just` for build/test/lint commands.

## Banned Languages (estate-wide)

- No TypeScript (use AffineScript).
- No Node.js / npm (use Bun first).
- No Go (use Rust).
- No Python (use Julia or Rust).

## Containers

- Use Podman, never Docker.
- Name the file `Containerfile`, never `Dockerfile`.
- Base image: `cgr.dev/chainguard/wolfi-base:latest`.

## State Files

Never create these in the repo root:
`STATE.a2ml`, `META.a2ml`, `ECOSYSTEM.a2ml`, `AGENTIC.a2ml`, `NEUROSYM.a2ml`, `PLAYBOOK.a2ml`.
They belong in `.machine_readable/6a2/` only.

## Workflow Pins

All wrapper workflows in `.github/workflows/` must pin the upstream standards reusable to a SHA (40-hex), never `@main` or `@v1`. Use the standards repo's current `main` HEAD SHA for new wrappers; let dependabot or rhodibot update the pin afterwards.

## Registration PRs

A package registration PR title follows: `feat(registry): register <Package> v<X.Y.Z>` (or `add <Package>` for first registration). It updates `Registry.toml` plus the relevant per-package directory atomically.
