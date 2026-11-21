#!/usr/bin/env bash
# Regenerates parity/cases/shell_a_orig.json: the ORIGINAL side of the parity cases of shell_a.exs. It renders
# the same cases with the pre-migration library (commit 3506478, lu-* classes and inline styles), to be shown
# on the legacy stylesheet (reference bundle + the lib's companion CSS).
# Usage (repo root, MIX_DEPS_PATH set):  bash parity/cases/shell_a_snapshot.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BASE="${BASE_COMMIT:-3506478}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git -C "$ROOT" archive "$BASE" | tar -x -C "$TMP"
mkdir -p "$TMP/parity/cases"
cp "$ROOT/parity/cases.exs" "$TMP/parity/cases.exs"
cp "$ROOT/parity/cases/shell_a.exs" "$TMP/parity/cases/"
(cd "$TMP" && MIX_BUILD_PATH="${SNAP_BUILD:-$TMP/_build}" LANG=C.UTF-8 OUT="$ROOT/parity/cases/shell_a_orig.json" mix run parity/cases.exs)
echo "ok: $ROOT/parity/cases/shell_a_orig.json"
