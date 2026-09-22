#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK="$REPO_ROOT/scripts/check-lock-sync.sh"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

write_workflow() {
  local workflow_dir="$1"

  mkdir -p "$workflow_dir"
  cat >"$workflow_dir/example.yml" <<'YAML'
name: Parser regression
on: push
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - 'uses': owner/single-quoted@v1
      - "uses": owner/double-quoted@v1
      - uses   : owner/spaced-colon@v1
      - uses: $/path/to/local-action@v1
YAML
}

pass_dir="$TMP_ROOT/pass"
write_workflow "$pass_dir"
cat >"$pass_dir/actions.lock" <<'YAML'
workflows:
    '.github/workflows/example.yml':
        - 'owner/single-quoted@v1'
        - 'owner/double-quoted@v1'
        - 'owner/spaced-colon@v1'
dependencies:
    'owner/single-quoted@v1':
    'owner/double-quoted@v1':
    'owner/spaced-colon@v1':
YAML

pass_output="$($CHECK "$pass_dir" 2>&1)" || {
  printf 'expected quoted and spaced uses keys to satisfy orphan checks\n%s\n' "$pass_output" >&2
  exit 1
}
if grep -q 'stale lockfile entries' <<<"$pass_output"; then
  printf 'quoted or spaced uses key was incorrectly reported as an orphan\n%s\n' "$pass_output" >&2
  exit 1
fi

missing_dir="$TMP_ROOT/missing"
write_workflow "$missing_dir"
cat >"$missing_dir/actions.lock" <<'YAML'
workflows:
    '.github/workflows/example.yml': []
dependencies:
YAML

if missing_output="$($CHECK "$missing_dir" 2>&1)"; then
  printf 'expected unlocked references with quoted and spaced uses keys to fail\n' >&2
  exit 1
fi
for ref in owner/single-quoted@v1 owner/double-quoted@v1 owner/spaced-colon@v1; do
  if ! grep -q "step-level refs missing from the lockfile:.*$ref" <<<"$missing_output"; then
    printf 'missing-reference output did not include %s\n%s\n' "$ref" "$missing_output" >&2
    exit 1
  fi
done

printf 'check-lock-sync parser regressions passed\n'
