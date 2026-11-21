#!/usr/bin/env bash
# Visual comparison of the template pages (/templates/*) against the canvas boards design/canvas/T*Claro|Escuro
# (the source of truth of the templates; the markup is no longer compared).
#
#   SHOW_URL=http://localhost:4222 scripts/visual/templates.sh [scratch_dir]
#
# Needs a running showcase (cd showcase && PORT=4222 mix phx.server), chromium and node >= 22.
# env: THEMES=light,dark (default)  ONLY=tpl-tabela,tpl-dashboard,...  CANVAS_PORT=4688
# Prints the % of differing pixels of each page and theme (#1 = the whole board; #2 = the first 900px,
# when the board is taller). The crepúsculo boards are `tpl-crep-*` (the same pages with ?palette=crepusculo).
set -euo pipefail
cd "$(dirname "$0")/../.."
S=${1:-/tmp/lu-visual-templates}; export DESIGN=${DESIGN:-design}
export CANVAS_PORT=${CANVAS_PORT:-4688} SHOW_URL=${SHOW_URL:-http://localhost:4222}
export CANVAS_URL=http://127.0.0.1:$CANVAS_PORT THEMES=${THEMES:-light,dark}
IDS=tpl-auth-login,tpl-auth-login-erro,tpl-auth-cadastro,tpl-auth-codigo,tpl-auth-senha,tpl-dashboard,tpl-tabela,tpl-tabela-gaveta,tpl-tabela-modal,tpl-crep-auth-login,tpl-crep-dashboard,tpl-crep-paleta
export ONLY=${ONLY:-$IDS}
mkdir -p "$S/out"; [ -f "$S/out/manifest.json" ] || echo "{}" > "$S/out/manifest.json"
rm -rf "$S/canvas-site"; node scripts/visual/build_canvas.mjs "$DESIGN" "$S/canvas-site"
(cd "$S/canvas-site" && exec python3 -m http.server "$CANVAS_PORT" --bind 127.0.0.1 >/dev/null 2>&1) & SRV=$!
trap 'kill $SRV' EXIT; sleep 1
for m in tcanvas tshowcase diff; do node scripts/visual/visual.mjs $m "$S/out"; done
node -e '
const r=JSON.parse(require("fs").readFileSync(process.argv[1]+"/out/results.json"));
for(const x of r.filter(x=>x.state==="base"&&x.id.startsWith("tpl-"))) console.log(x.theme.padEnd(6),x.id.padEnd(22),"#"+x.idx,String(x.pct).padStart(7)+"%",x.w1+"x"+x.h1,"|",x.w2+"x"+x.h2,x.error||"");
' "$S"
