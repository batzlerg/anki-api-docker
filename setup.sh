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

# Stop existing containers and clean up for fresh start
echo "Cleaning up any existing setup..."
docker compose down 2>/dev/null || true

# Create/recreate the volume (idempotent)
echo "Setting up Docker volumes..."
docker volume create anki_profile 2>/dev/null || true

# Start the container
echo "Starting Anki container..."
docker compose up -d

# Wait for container to be running (not necessarily healthy yet)
echo "Waiting for container to start..."
for i in {1..30}; do
    if docker compose ps --format json | grep -q '"State":"running"'; then
        echo "Container is running!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Error: Container failed to start within 30 seconds"
        docker compose logs --tail=20 anki-headless
        exit 1
    fi
    sleep 2
done

# Install AnkiConnect into the running container (idempotent)
echo "Installing AnkiConnect add-on..."
docker exec anki-headless bash -c '
    set -e
    echo "Preparing add-on installation..."
    
    # Install required packages
    apt-get update -qq
    apt-get install -y wget unzip
    
    # Create addons21 directory
    mkdir -p /config/app/Anki2/addons21
    
    # Remove existing AnkiConnect installation (idempotent)
    rm -rf /config/app/Anki2/addons21/2055492159
    
    # Download AnkiConnect from GitHub releases
    cd /config/app/Anki2/addons21
    echo "Downloading AnkiConnect from GitHub..."
    wget -O anki-connect.zip "https://github.com/FooSoft/anki-connect/archive/refs/tags/23.10.29.0.zip"
    
    # Extract the zip file
    unzip -q anki-connect.zip
    
    # The extracted folder contains the plugin files in a plugin/ subdirectory
    if [ -d "anki-connect-23.10.29.0/plugin" ]; then
        echo "✓ AnkiConnect archive extracted successfully"
        
        # Create the proper add-on directory and move plugin files
        mkdir -p 2055492159
        mv anki-connect-23.10.29.0/plugin/* 2055492159/
        
        echo "✓ AnkiConnect plugin files moved to correct location"
    else
        echo "✗ Expected plugin folder not found in extracted archive"
        ls -la anki-connect-23.10.29.0/ || echo "Archive folder not found"
        exit 1
    fi
    
    # Clean up
    rm -rf anki-connect-23.10.29.0 anki-connect.zip
    
    # Create default config.json with Docker-compatible settings
    echo "Configuring AnkiConnect for Docker networking..."
    cat > 2055492159/config.json <<EOF
{
  "apiKey": null,
  "apiLogPath": null,
  "ignoreOriginList": [],
  "webBindAddress": "0.0.0.0",
  "webBindPort": 8765,
  "webCorsOriginList": ["http://localhost", "http://127.0.0.1"]
}
EOF
    
    # Fix ownership so Anki can read/write all files
    echo "Fixing file ownership..."
    chown -R abc:abc /config/app/Anki2/addons21
    
    # Verify installation
    if [ -f "/config/app/Anki2/addons21/2055492159/__init__.py" ]; then
        echo "✓ AnkiConnect installed and configured successfully"
        echo "✓ Default configuration set for Docker networking (webBindAddress: 0.0.0.0)"
        echo "Add-on files:"
        ls -la /config/app/Anki2/addons21/2055492159/ | head -5
    else
        echo "✗ AnkiConnect installation failed - __init__.py not found"
        echo "Contents of 2055492159 directory:"
        ls -la /config/app/Anki2/addons21/2055492159/ || echo "Directory does not exist"
        exit 1
    fi
'

# Restart container to ensure clean state
echo "Restarting container to load add-on..."
docker compose restart anki-headless

# Wait for health check with extended patience
echo "Waiting for Anki container to become healthy..."
echo "NOTE: You must manually launch Anki Desktop via the web UI for the health check to pass"
echo "Access the web UI at: http://localhost:3000 (if using SSH tunnel) or http://127.0.0.1:3000"
echo ""

for i in {1..120}; do
    if docker compose ps --format json | grep -q '"Health":"healthy"'; then
        echo "Container is healthy and AnkiConnect should be ready!"
        break
    fi
    if [ $i -eq 120 ]; then
        echo "Container did not become healthy within 2 minutes"
        echo "This is normal - you need to manually launch Anki Desktop through the web UI"
        echo ""
        echo "Next steps:"
        echo "1. Access web UI: http://127.0.0.1:3000 (or use SSH tunnel for headless servers)"
        echo "2. Launch Anki Desktop application"
        echo "3. AnkiConnect is pre-configured for Docker - no manual config needed!"
        echo "4. Test the API with the validation commands below"
        echo ""
        exit 0
    fi
    
    # Show progress every 15 seconds
    if [ $((i % 15)) -eq 0 ]; then
        echo "Still waiting... ($i/120 seconds)"
        echo "Remember to launch Anki Desktop via the web UI at port 3000"
    fi
    
    sleep 1
done

# Test AnkiConnect API (only if healthy)
echo "Testing AnkiConnect API..."

# Basic connectivity test
if curl -s --max-time 10 http://127.0.0.1:8765 > /dev/null; then
    echo "✓ AnkiConnect is responding"
    
    # API version test
    response=$(curl -s --max-time 10 -X POST http://127.0.0.1:8765 \
      -H 'Content-Type: application/json' \
      -d '{"action":"version","version":6}' 2>/dev/null || echo "")
    
    if echo "$response" | grep -q '"result":6'; then
        echo "✓ AnkiConnect API is working correctly"
        echo "Response: $response"
    else
        echo "⚠ AnkiConnect API test inconclusive"
        echo "Response: $response"
        echo "This may be normal if AnkiConnect needs configuration"
    fi
else
    echo "ℹ AnkiConnect API not yet accessible"
    echo "This is expected until Anki Desktop is launched"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "NEXT STEPS:"
echo "1. Access the web UI to launch Anki Desktop:"
echo "   • For headless servers: ssh -L 3000:127.0.0.1:3000 user@server-ip"
echo "   • Then open: http://localhost:3000"
echo "   • For GUI servers: http://127.0.0.1:3000"
echo ""
echo "2. Launch Anki Desktop application in the web interface"
echo ""
echo "3. AnkiConnect is pre-configured for Docker - ready to use!"
echo ""
echo "4. Test the API:"
echo "   curl -X POST http://127.0.0.1:8765 -H 'Content-Type: application/json' -d '{\"action\":\"version\",\"version\":6}'"
echo ""
echo "Services:"
echo "• AnkiConnect API: http://127.0.0.1:8765 (after Anki Desktop launch)"
echo "• Web UI: http://127.0.0.1:3000"
echo ""
echo "Management:"
echo "• Stop: docker compose down"
echo "• Restart: docker compose up -d (requires relaunching Anki Desktop)"
echo "• Logs: docker compose logs anki-headless"
