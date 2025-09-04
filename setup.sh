#!/usr/bin/env bash
set -euo pipefail

SERVICE="anki-api-docker"
ADDONS_ROOT="/config/app/Anki2/addons21"
AC_ID="2055492159"
AC_DIR="${ADDONS_ROOT}/${AC_ID}"
# 23.10.x.x is compatible with Anki v2.1.54 which anki-desktop hard-codes
RELEASE_URL="https://git.sr.ht/~foosoft/anki-connect/archive/23.10.29.0.tar.gz"

echo "AnkiBot: Containerized API for your Anki Cards"
echo "============================================="

# Preconditions
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker not found in PATH"; exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: Docker Compose v2 is required"; exit 1
fi

# Container setup
echo "🧹 Stopping any previous stack..."
docker compose down --remove-orphans 2>/dev/null || true

echo "📦 Creating volume and starting container..."
docker volume create anki_config >/dev/null
docker compose up -d

# Wait for container
echo "⏳ Waiting for container..."
for i in {1..30}; do
  state="$(docker compose ps --format json | sed -n 's/.*\"State\":\"\([^\"]*\)\".*/\1/p' | head -n1 || true)"
  if [ "${state:-}" = "running" ]; then
    echo "✅ Container running"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "❌ Container failed to start"
    exit 1
  fi
  sleep 2
done

# Install AnkiConnect
echo "📥 Installing AnkiConnect..."
docker exec "$SERVICE" bash -c "
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq && apt-get install -y wget tar >/dev/null

  mkdir -p '$ADDONS_ROOT' && chown -R abc:abc /config

  TMP=\$(mktemp -d) && cd \$TMP
  wget -q '$RELEASE_URL' -O ac.tar.gz
  tar -xzf ac.tar.gz

  # Find plugin root containing __init__.py
  PLUGIN_ROOT=\$(find . -name '__init__.py' -type f | head -1 | xargs dirname)
  [ -z \"\$PLUGIN_ROOT\" ] && { echo 'ERROR: Plugin not found'; exit 1; }

  rm -rf '$AC_DIR' && mkdir -p '$AC_DIR'
  cp -a \$PLUGIN_ROOT/* '$AC_DIR'/ 

  # Configure for container networking
  cat > '$AC_DIR/config.json' << 'EOF'
{\"apiKey\":null,\"webBindAddress\":\"0.0.0.0\",\"webBindPort\":8765,\"webCorsOriginList\":[\"http://localhost\",\"http://127.0.0.1\"]}
EOF

  rm -f '$AC_DIR/meta.json' && chown -R abc:abc '$ADDONS_ROOT'
  echo '✅ AnkiConnect configured'
"

cat <<'EOT'

🎯 NEXT: Connect Your AnkiWeb Account
====================================

If this machine has a browser, visit:
http://localhost:3000

If this machine DOES NOT have a browser, you will have to SSH tunnel to the UI:
ssh -L 3000:$SERVER_IP:3000 $USERNAME@$SERVER_IP

Once you see the Guacamole page load Anki Desktop:
1. Select your desired language from the menu
2. Ignore new version notifications unless you are confident it won't break things!
3. Click 'Sync' and enter your AnkiWeb credentials. Download all cards to your device.
4. Test the API by running: ./validate-setup.sh

Your AnkiWeb cards will be accessible at port 8765!
EOT
