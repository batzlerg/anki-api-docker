#!/usr/bin/env bash
set -euo pipefail

SERVICE="anki-headless"
echo "AnkiBot: Validate AnkiWeb Cards API"
echo "==================================="

if ! docker compose ps | grep -q "Up"; then
    echo "❌ Container not running. Run: ./setup.sh"
    exit 1
fi

echo "🔌 Testing AnkiConnect API..."
for i in {1..60}; do
  if curl -fsS http://127.0.0.1:8765 >/dev/null 2>&1; then
    echo "✅ API responding"
    break
  fi
  if [ $i -eq 60 ]; then
    echo "❌ API not responding. Launch Anki via web UI at :3000"
    exit 1
  fi
  sleep 2
done

echo
echo "🧪 Version response:"
curl -fsS -X POST http://127.0.0.1:8765 -H 'Content-Type: application/json' -d '{"action":"version","version":6}' || echo "ERROR"

echo
echo "🧪 Decks response:"
curl -fsS -X POST http://127.0.0.1:8765 -H 'Content-Type: application/json' -d '{"action":"deckNames","version":6}' || echo "ERROR"

echo
echo "🎉 Your AnkiWeb cards API is ready at http://127.0.0.1:8765"
echo "📖 Full documentation: https://foosoft.net/projects/anki-connect/"
