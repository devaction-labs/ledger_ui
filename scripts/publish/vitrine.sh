#!/usr/bin/env bash
# Static export of the showcase -> out/publish/vitrine/ (idempotent: wipes and recreates it).
#   scripts/publish/vitrine.sh            FULL=0 skips full/<id>.html (the "tela cheia" overlay pages)
# Needs: elixir/mix, node >= 22, network the first time (Tailwind binary, Google Fonts; cached afterwards).
# env: MIX_DEPS_PATH (default: showcase/deps)   PORT (default: a free one)
set -euo pipefail
cd "$(dirname "$0")/../.."
ROOT=$PWD
OUT=$ROOT/out/publish/vitrine
export MIX_DEPS_PATH=${MIX_DEPS_PATH:-$ROOT/showcase/deps}
PORT=${PORT:-$(python3 -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1])')}
mkdir -p "$ROOT/out/publish"; rm -rf "$OUT"; mkdir -p "$OUT"
IDS=$ROOT/out/publish/ids.txt LOG=$ROOT/out/publish/server.log

(cd showcase && mix assets.setup >/dev/null && mix assets.build >/dev/null \
  && mix run --no-start -e 'IO.puts(Enum.join(LedgerShowcase.Examples.ids(), "\n"))' | grep -E '^[a-z0-9_-]+$' > "$IDS")

(cd showcase && PORT=$PORT exec setsid mix phx.server >"$LOG" 2>&1) & SRV=$!
trap 'pkill -TERM -g "$SRV" 2>/dev/null || kill "$SRV" 2>/dev/null || true' EXIT
for _ in $(seq 1 300); do curl -sf "http://127.0.0.1:$PORT/" >/dev/null && break; sleep 1; done
curl -sf "http://127.0.0.1:$PORT/" >/dev/null || { echo "showcase did not start; see $LOG" >&2; exit 1; }

node scripts/publish/vitrine.mjs "http://127.0.0.1:$PORT" "$OUT" "$IDS"
