#!/bin/bash
set -euo pipefail

echo "Setting up headless Anki with AnkiConnect..."

# Check if Docker and Docker Compose are available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    echo "Error: Docker Compose is not available"
    exit 1
fi

# Create the project's named volumes first
echo "Creating Docker volumes..."
docker volume create anki_profile 2>/dev/null || true
docker volume create anki_addons 2>/dev/null || true

# Seed AnkiConnect add-on into the addons volume (idempotent)
echo "Installing AnkiConnect add-on..."
docker run --rm \
  -v anki_addons:/addons \
  alpine:3.20 sh -c "
    apk add --no-cache git
    if [ ! -d /addons/2055492159 ]; then
      git clone https://git.sr.ht/~foosoft/anki-connect /addons/2055492159
      echo 'AnkiConnect installed successfully'
    else
      echo 'AnkiConnect already exists, skipping installation'
    fi
  "

# Start services 
echo "Starting Anki container..."
docker compose up -d

# Wait for health check with more patience
echo "Waiting for Anki to become healthy (this may take 1-2 minutes)..."
for i in {1..60}; do
    if docker compose ps --format json | grep -q '"Health":"healthy"'; then
        echo "Anki is healthy!"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "Warning: Anki did not become healthy within 60 attempts"
        echo "Checking container logs..."
        docker compose logs --tail=20 anki-headless
        exit 1
    fi
    sleep 3
done

echo "Testing AnkiConnect API..."

# Test basic connectivity
if curl -s --max-time 10 http://127.0.0.1:8765 > /dev/null; then
    echo "✓ AnkiConnect is responding"
else
    echo "✗ AnkiConnect is not responding"
    exit 1
fi

# Test deck names API
response=$(curl -s --max-time 10 -X POST http://127.0.0.1:8765 \
  -H 'Content-Type: application/json' \
  -d '{"action":"deckNames","version":6}')

if echo "$response" | grep -q '"result"'; then
    echo "✓ AnkiConnect API is working correctly"
    echo "Response: $response"
else
    echo "✗ AnkiConnect API test failed"
    echo "Response: $response"
    exit 1
fi

echo ""
echo "Setup complete! Headless Anki with AnkiConnect is running."
echo "API available at: http://127.0.0.1:8765"
echo "Web UI available at: http://127.0.0.1:3000 (optional, for debugging)"
echo ""
echo "To stop: docker compose down"
echo "To restart: docker compose up -d"
