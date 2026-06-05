#!/usr/bin/env bash
# Start the local agent-log viewer.
# Generates tools/log-index.json from .github/agent-logs/, then serves the
# repo root over HTTP and opens the viewer page.
set -euo pipefail

cd "$(dirname "$0")/.."

PORT="${PORT:-8765}"
INDEX="tools/log-index.json"

# If the requested port is taken, walk forward until we find a free one.
while lsof -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; do
  echo "port $PORT is in use, trying $((PORT + 1))…"
  PORT=$((PORT + 1))
done

find .github/agent-logs -type f -name '*.json' 2>/dev/null \
  | LC_ALL=C sort \
  | python3 -c "import sys, json; print(json.dumps([l.strip() for l in sys.stdin]))" \
  > "$INDEX"

URL="http://localhost:${PORT}/tools/log-viewer.html"
echo "Serving repo at http://localhost:${PORT}"
echo "Opening ${URL}"
( sleep 0.4 && open "$URL" ) &
exec python3 -m http.server "$PORT"
