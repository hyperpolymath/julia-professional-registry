# SPDX-License-Identifier: PMPL-1.0-or-later
# Justfile — UX recipes

import? 'contractile.just'

# Default: list recipes
default:
    @just --list

# Self-diagnostic: check required tools
doctor:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  doctor — Self-Diagnostic"
    echo "═══════════════════════════════════════════════════"
    passed=0; failed=0; warn=0
    if command -v just >/dev/null 2>&1; then echo "[OK]   just"; passed=$((passed+1)); else echo "[FAIL] just"; failed=$((failed+1)); fi
    if command -v git >/dev/null 2>&1; then echo "[OK]   git"; passed=$((passed+1)); else echo "[FAIL] git"; failed=$((failed+1)); fi
    if command -v panic-attack >/dev/null 2>&1; then echo "[OK]   panic-attack"; passed=$((passed+1)); else echo "[WARN] panic-attack (optional)"; warn=$((warn+1)); fi
    # Check for hardcoded paths
    hc=$(grep -rn "/home/" --include="*.rs" --include="*.res" --include="*.gleam" --include="*.ex" --include="*.exs" --include="*.zig" . 2>/dev/null | grep -v node_modules | grep -v .git | wc -l)
    if [ "$hc" -eq 0 ]; then echo "[OK]   no hardcoded paths"; passed=$((passed+1)); else echo "[WARN] $hc hardcoded paths found"; warn=$((warn+1)); fi
    echo "═══════════════════════════════════════════════════"
    echo "  $passed passed, $failed failed, $warn warnings"
    if [ "$failed" -gt 0 ]; then exit 1; fi

# Show install instructions for missing tools
heal:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  heal — Install Missing Tools"
    echo "═══════════════════════════════════════════════════"
    if ! command -v just >/dev/null 2>&1; then echo "Install just: https://just.systems/man/en/installation.html"; fi
    if ! command -v panic-attack >/dev/null 2>&1; then echo "Install panic-attack: cargo install panic-attacker"; fi
    echo "Run 'just doctor' to verify."

# Guided project walkthrough
tour:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  tour — Project Walkthrough"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo "Project structure:"
    ls -la --color=never | head -25
    echo ""
    echo "Key files:"
    for f in README.adoc README.md EXPLAINME.adoc LICENSE SECURITY.md; do
      [ -f "$f" ] && echo "  ✓ $f"
    done
    echo ""
    echo "Available recipes: just --list"
    echo "Self-check: just doctor"

# Show common workflows and get help
help-me:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  help-me — Common Workflows"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo "FIRST TIME:"
    echo "  just doctor          Check everything works"
    echo "  just heal            Fix missing tools"
    echo "  just tour            Guided walkthrough"
    echo ""
    echo "PRE-COMMIT:"
    echo "  just assail          Security scan"
    echo "  just must-check      Policy check"
    echo ""
    echo "LEARN:"
    echo "  cat README.adoc      Project overview"
    echo "  cat EXPLAINME.adoc   Deeper explanation"
    echo ""
    echo "BUG REPORT:"
    echo "  Platform: $(uname -s) $(uname -m)"
    echo "  Shell: $SHELL"
    echo "  Include 'just doctor' output in your issue."

# Pre-commit security scan
assail:
    panic-attack assail .

