#!/usr/bin/env bash
# Full visual comparison. Usage: scripts/visual/run.sh [scratch_dir]
# env: DESIGN=design (dir with canvas/*.dc.html + canvas/canvas.css), SHOW_URL=http://localhost:4500,
#      ONLY=id1,id2  THEMES=light,dark
# Needs: chromium, a running showcase (cd showcase && PORT=4500 mix phx.server), node >= 22.
set -euo pipefail
cd "$(dirname "$0")/../.."
S=${1:-/tmp/lu-visual}; export DESIGN=${DESIGN:-design}
export CANVAS_URL=${CANVAS_URL:-http://127.0.0.1:4600}
rm -rf "$S/canvas-site"; node scripts/visual/build_canvas.mjs "$DESIGN" "$S/canvas-site"
(cd "$S/canvas-site" && exec python3 -m http.server 4600 --bind 127.0.0.1 >/dev/null 2>&1) & SRV=$!
trap 'kill $SRV' EXIT; sleep 1
mkdir -p "$S/out"
[ -f "$S/out/results.json" ] && cp "$S/out/results.json" "$S/out/results-before.json"
for m in canvas tcanvas showcase tshowcase diff report; do node scripts/visual/visual.mjs $m "$S/out"; done
echo "report: visual-report/index.html"
