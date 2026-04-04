# CRG Grade C Test Coverage

## CRG Grade: C — ACHIEVED 2026-04-04

**Repository:** HyperpolymathRegistry  
**Grade:** C  
**Last Updated:** 2026-04-04

## Overview

This repository is a custom Julia package registry containing all hyperpolymath Julia packages. As a registry/data repository with no executable code, tests focus on:
- Registry structure and validity (TOML format)
- Package entry completeness
- Directory structure consistency
- Package enumeration and naming conventions

## Test Categories

| Category | Count | Status | Notes |
|----------|-------|--------|-------|
| Unit Tests | 4 | ✓ PASS | Registry.toml, README, package directories, LICENSES |
| Smoke Tests | 3 | ✓ PASS | Package entries, TOML structure, README content |
| Contract Tests | 2 | ✓ PASS | Package TOML files, file presence |
| Aspect Tests | 3 | ✓ PASS | Naming conventions, path structure, directory existence |
| Property-Based Tests | 3 | ✓ PASS | TOML parseability, UUID format, name uniqueness |
| E2E/Reflexive Tests | 3 | ✓ PASS | Registry parsing, consistency checks, doc-registry alignment |
| Benchmarks | 2 | ✓ PASS | Registry parsing performance, size baseline |

**Total Test Count:** 20  
**All Tests Passing:** Yes

## Running Tests

```bash
deno test --allow-read tests/validate.test.ts
```

## Test Details

### Unit Tests (4)
- Validates Registry.toml exists and contains registry metadata
- Confirms README.adoc documentation file
- Checks all expected package letter directories (A-Z)
- Verifies LICENSES directory

### Smoke Tests (3)
- Verifies Registry.toml contains package entries (≥ 20)
- Checks package entries have required fields (name, path, UUID)
- Validates README references packages

### Contract Tests (2)
- Package directories must contain standard TOML files (Package.toml, Versions.toml)
- Package.toml files must have valid TOML structure

### Aspect Tests (3)
- Package names follow convention (start with uppercase)
- Package paths in registry match actual directories
- All registry paths point to existing directories

### Property-Based Tests (3)
- Registry.toml is valid TOML with [packages] section
- All package UUIDs follow UUID format (8-4-4-4-12 hex)
- No duplicate package names in registry

### E2E/Reflexive Tests (3)
- Registry entries can be parsed (UUID, name, path extraction)
- Package directories exist and match registry paths
- README documentation mentions packages from registry

### Benchmarks (2)
- Registry.toml parsing completes in < 100ms
- Registry size baseline (≥ 10KB, indicating substantial content)

## Registry Structure

```
HyperpolymathRegistry/
├── Registry.toml              # Registry manifest
├── README.adoc                # User documentation
├── A/
│   ├── AcceleratorGate/
│   ├── Axiom/
│   ├── Axiology/
│   └── ...
├── B/
│   └── ...
├── ... (C, E, F, H, I, J, K, L, M, P, Q, S, T, V, Z)
└── LICENSES/
    └── (license files)
```

Each package directory contains:
- `Package.toml` - Package metadata (name, uuid)
- `Versions.toml` - Version history
- `Deps.toml` - Dependencies
- `Compat.toml` - Compatibility constraints
- `WeakDeps.toml` (optional) - Weak dependencies

## Package Count

The registry currently contains 50+ Julia packages, including:
- Axiom (ML framework with formal verification)
- Lithoglyph (format system)
- SMTLib (SMT solver bindings)
- And many domain-specific packages in economics, game theory, risk analysis, etc.

## Registry Usage

Users can add this registry to their Julia environment:

```julia
using Pkg
Pkg.Registry.add(RegistrySpec(url="https://github.com/hyperpolymath/HyperpolymathRegistry"))
```

Then install packages:

```julia
pkg> add Axiom
pkg> add Lithoglyph
```

## Dependencies

- Deno 1.40+
- deno_std (assert module)

## Future Enhancements

- [ ] Validate Package.toml TOML syntax
- [ ] Check version number formats
- [ ] Verify dependency references are valid
- [ ] Test registry as Julia package registry
- [ ] Validate package descriptions
