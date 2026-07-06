#!/bin/bash
# ------------------------------------------------------------
#  Global View — Live Flight Tracker
#  Double-click this file to start the app in your browser.
#  Keep this window open while using it · press Ctrl+C to stop.
# ------------------------------------------------------------
cd "$(dirname "$0")"
PORT=5500
URL="http://localhost:$PORT"

# already running? just open the browser
if curl -s -o /dev/null --max-time 2 "$URL"; then
  echo "✅ Flight tracker is already running — opening $URL"
  open "$URL"
  exit 0
fi

echo "🌍 Starting Global View flight tracker …"
echo "   $URL"
echo ""
echo "   Keep this window open while you use the app."
echo "   Press Ctrl+C here to stop the server."
echo ""

# open the browser once the server is up
( sleep 1.5; open "$URL" ) &

exec python3 -m http.server "$PORT" --directory "$(pwd)"
