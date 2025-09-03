#!/usr/bin/env bash
set -euo pipefail

SERVICE="anki-headless"

echo "AnkiBot: Validate Desktop & AnkiConnect"
echo "======================================="

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker not found in PATH"; exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "Error: Docker Compose v2 is required (use 'docker compose')"; exit 1
fi

echo "🔎 Container status:"
docker compose ps || true
echo

echo "🌐 Checking Guacamole (:3000) — requires that a browser has opened it at least once..."
for i in {1..120}; do
  if curl -fsS http://127.0.0.1:3000 >/dev/null 2>&1; then
    echo "✅ Guacamole is reachable"
    break
  fi
  if [ $i -eq 120 ]; then
    echo "❌ Web UI not reachable; open http://127.0.0.1:3000 first"
    exit 1
  fi
  sleep 1
done
echo

echo "🖥️  Checking AnkiConnect on :8765 (ensure Anki is running in the desktop)..."
for i in {1..600}; do
  if curl -fsS http://127.0.0.1:8765 >/dev/null 2>&1; then
    echo "✅ AnkiConnect base endpoint responds"
    break
  fi
  if (( i % 30 == 0 )); then
    echo "…still waiting (launch Anki inside the desktop at :3000)"
  fi
  if [ $i -eq 600 ]; then
    echo "❌ AnkiConnect did not appear within 10 minutes"
    exit 1
  fi
  sleep 1
done
echo

echo "🧪 Exercising API endpoints"
echo "---------------------------"

echo "- version:"
curl -fsS -X POST http://127.0.0.1:8765 \
  -H 'Content-Type: application/json' \
  -d '{"action":"version","version":6}'
echo

echo "- deckNames:"
curl -fsS -X POST http://127.0.0.1:8765 \
  -H 'Content-Type: application/json' \
  -d '{"action":"deckNames","version":6}'
echo

echo "- modelNames:"
curl -fsS -X POST http://127.0.0.1:8765 \
  -H 'Content-Type: application/json' \
  -d '{"action":"modelNames","version":6}'
echo

echo
echo "🎉 Validation complete; AnkiConnect is ready."
