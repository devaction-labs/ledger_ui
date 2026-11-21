#!/usr/bin/env bash
# Design System export -> out/publish/design-system/project/  (idempotent: wipes and recreates project/)
#   scripts/publish/design_system.sh
# Reads the design data from ${LEDGER_DESIGN:-<root>/../ledger_ui_design}, falling back to <root>/design.
# Needs the vitrine export (runs vitrine.sh when out/publish/vitrine is missing; REBUILD_VITRINE=1 forces it),
# node >= 22 + npm (esbuild is installed once under out/publish/_cache/esbuild; ESBUILD_DIR overrides),
# the Tailwind v4 binary of showcase/_build (TAILWIND overrides) and python with playwright (PYTHON overrides;
# default: the .venv-ledger next to the checkouts, else python3). CHECK=0 skips the browser check.
# env: MIX_DEPS_PATH (default: showcase/deps)
set -euo pipefail
cd "$(dirname "$0")/../.."
ROOT=$PWD
export MIX_DEPS_PATH=${MIX_DEPS_PATH:-$ROOT/showcase/deps}
DESIGN=${LEDGER_DESIGN:-$ROOT/../ledger_ui_design}
[ -d "$DESIGN/system" ] || DESIGN=$ROOT/design
echo "design data: $DESIGN"
PYTHON=${PYTHON:-}
if [ -z "$PYTHON" ]; then
  for v in "${LEDGER_VENV:-}" "$ROOT/../../.venv-ledger" "$ROOT/../.venv-ledger"; do
    [ -n "$v" ] && [ -x "$v/bin/python" ] && PYTHON=$v/bin/python && break
  done
  PYTHON=${PYTHON:-python3}
fi

if [ "${REBUILD_VITRINE:-0}" = 1 ] || [ ! -f out/publish/vitrine/c/button.html ]; then
  scripts/publish/vitrine.sh
fi

ESB=${ESBUILD_DIR:-$ROOT/out/publish/_cache/esbuild/node_modules/esbuild}
if [ ! -d "$ESB" ]; then
  mkdir -p out/publish/_cache/esbuild
  npm install --no-save --no-audit --no-fund --prefix out/publish/_cache/esbuild esbuild@0.27.4 >/dev/null
fi

"$PYTHON" scripts/publish/design_system.py "$ROOT" "$DESIGN" "$ESB"
[ "${CHECK:-1}" = 0 ] || "$PYTHON" scripts/publish/check_ds.py
