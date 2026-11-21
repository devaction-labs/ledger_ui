#!/usr/bin/env bash
# Visual comparison canvas x showcase, per section. Usage: scripts/visual/run.sh [scratch_dir]
#
# Pairing: showcase examples/<id>/NN.heex (NN-th `.d-ex` of /full/<id>) x the canvas demo of the same section (see visual.mjs).
# Output: <scratch>/out/report.json (per section %), <scratch>/out/report.html (worst first, with montages), raw shots in <scratch>/out/raw.
#
# env (everything is overridable so several agents can run in parallel: use a distinct scratch dir + CANVAS_PORT each):
#   ONLY=button,badge      section ids (default: all)           THEMES=light,dark     (default)
#   THRESHOLD=0.6  INK_THRESHOLD=15   max % diff of the box / of the inked pixels per section STRICT=1              exit 1 when a section is over / missing
#   SHOW_URL=http://localhost:4223   running showcase (cd showcase && PORT=4223 mix phx.server)
#   CANVAS_PORT=4623       static canvas server port (must be free; default 4600 + random)
#   TEMPLATES=1            also compare /templates/* pages (default: components only)
#   DESIGN=design          dir with canvas/*.dc.html + canvas/canvas.css + vitrine/
# Needs: chromium, node >= 22, python3 (static server), a running showcase.
set -euo pipefail
cd "$(dirname "$0")/../.."
S=${1:-/tmp/lu-visual}; export DESIGN=${DESIGN:-design}
export SHOW_URL=${SHOW_URL:-http://localhost:4500}
CANVAS_PORT=${CANVAS_PORT:-$((4600 + RANDOM % 300))}
export CANVAS_URL=${CANVAS_URL:-http://127.0.0.1:$CANVAS_PORT}
mkdir -p "$S"; rm -rf "$S/canvas-site"; node scripts/visual/build_canvas.mjs "$DESIGN" "$S/canvas-site" >/dev/null
(cd "$S/canvas-site" && exec python3 -m http.server "$CANVAS_PORT" --bind 127.0.0.1 >/dev/null 2>&1) & SRV=$!
trap 'kill $SRV 2>/dev/null || true' EXIT; sleep 1
mkdir -p "$S/out"
# a full run replaces the results; with ONLY the other ids keep their previous results (visual.mjs merges)
[ -z "${ONLY:-}" ] && rm -f "$S/out/results.json" "$S/out/manifest.json" "$S/out/showcase_meta.json"
phases=(canvas showcase)
[ "${TEMPLATES:-0}" = 1 ] && phases=(canvas tcanvas showcase tshowcase)
for m in "${phases[@]}" diff; do node scripts/visual/visual.mjs $m "$S/out"; done
node scripts/visual/visual.mjs report "$S/out"
