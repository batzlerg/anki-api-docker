#!/usr/bin/env bash
set -euo pipefail

SERVICE="anki-headless"
ADDONS_ROOT="/config/app/Anki2/addons21"
AC_ID="2055492159"
AC_DIR="${ADDONS_ROOT}/${AC_ID}"
# 23.10.x.x is compatible with Anki v2.1.54 which anki-desktop hard-codes
RELEASE_URL="https://git.sr.ht/~foosoft/anki-connect/archive/23.10.29.0.tar.gz"

echo "AnkiBot: Setup (container + AnkiConnect provisioning)"
echo "===================================================="

# ---------- Preconditions ----------
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker not found in PATH"; exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: Docker Compose v2 is required (use 'docker compose')"; exit 1
fi

# ---------- Bring stack up cleanly ----------
echo "🧹 Stopping any previous stack..."
docker compose down --remove-orphans 2>/dev/null || true

echo "📦 Ensuring named volume (anki_config) exists..."
docker volume create anki_config >/dev/null

echo "🚀 Bringing up container..."
docker compose up -d

# Wait for process state=running (not 'healthy'; desktop requires browser visit)
echo "⏳ Waiting for container state=running..."
for i in {1..30}; do
  state="$(docker compose ps --format json | sed -n 's/.*\"State\":\"\([^\"]*\)\".*/\1/p' | head -n1 || true)"
  if [ "${state:-}" = "running" ]; then
    echo "✅ Container process is running"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "❌ Container failed to enter running state"
    docker compose logs --tail=200 "$SERVICE" || true
    exit 1
  fi
  sleep 2
done

# ---------- Context ----------
echo
echo "🔎 Container context (env, paths, perms)..."
docker exec "$SERVICE" bash -lc '
  set -e
  echo "- id:"; id
  echo "- HOME:" "$HOME"
  echo "- LANG/LC vars:"; env | egrep "^(LANG|LC_)=" | sort || true
  echo "- key paths:"; ls -ld /config /config/app /config/app/Anki2 || true
'

# ---------- Ensure addons root exists and is writable ----------
echo
echo "📁 Ensuring add-ons root exists and is writable: $ADDONS_ROOT"
docker exec "$SERVICE" bash -lc "
  set -e
  mkdir -p '$ADDONS_ROOT'
  chown -R abc:abc /config
  chmod 775 '$ADDONS_ROOT' || true
  echo -n '- write test: '
  if sudo -u abc bash -lc \"touch '$ADDONS_ROOT/.write_test' 2>/dev/null\"; then
    echo ok; rm -f '$ADDONS_ROOT/.write_test'
  else
    echo 'FAIL (addons root not writable by abc)'; exit 1
  fi
"

# ---------- Install AnkiConnect from SourceHut tar.gz ----------
echo
echo "📥 Installing AnkiConnect (tar.gz) to $AC_DIR"
docker exec "$SERVICE" bash -lc "
  set -e

  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y wget ca-certificates tar >/dev/null

  ROOT='$ADDONS_ROOT'
  AC_DIR='$AC_DIR'
  TMP=\$(mktemp -d /tmp/ac.XXXXXX)

  echo '- clearing previous copy...'
  rm -rf \"\$AC_DIR\"

  echo '- downloading tar.gz: $RELEASE_URL'
  wget -q --show-progress -O \"\$TMP/ac.tar.gz\" '$RELEASE_URL'

  echo '- extracting tar.gz...'
  mkdir -p \"\$TMP/unpack\"
  tar -xzf \"\$TMP/ac.tar.gz\" -C \"\$TMP/unpack\"

  echo '- locating plugin root (must contain __init__.py):'
  CAND=''

  # Common layouts to probe:
  # 1) */plugin containing __init__.py (legacy structure)
  for d in \"\$TMP/unpack\"/*/plugin; do
    [ -d \"\$d\" ] || continue
    if [ -f \"\$d/__init__.py\" ]; then CAND=\"\$d\"; break; fi
  done

  # 2) A top-level directory which itself contains __init__.py (flat layout)
  if [ -z \"\$CAND\" ]; then
    for d in \"\$TMP/unpack\"/*/; do
      [ -d \"\$d\" ] || continue
      if [ -f \"\$d/__init__.py\" ]; then CAND=\"\$d\"; break; fi
      # 3) Rare two-deep cases, search one level deeper for __init__.py
      if [ -z \"\$CAND\" ]; then
        for e in \"\$d\"*/; do
          [ -d \"\$e\" ] || continue
          if [ -f \"\$e/__init__.py\" ]; then CAND=\"\$e\"; break; fi
        done
      fi
      [ -n \"\$CAND\" ] && break
    done
  fi

  if [ -z \"\$CAND\" ]; then
    echo 'ERROR: Could not find a plugin root with __init__.py in SourceHut tarball'
    echo 'Archive layout (first 200 lines):'; ls -laR \"\$TMP/unpack\" | sed -n '1,200p'
    exit 1
  fi
  echo \"- plugin root: \$CAND\"

  echo '- installing to ID directory...'
  mkdir -p \"\$AC_DIR\"
  cp -a \"\$CAND\"/* \"\$AC_DIR\"/

  echo '- writing Docker-friendly config.json (force)...'
  cat > \"\$AC_DIR/config.json\" << EOF
{
  \"apiKey\": null,
  \"apiLogPath\": null,
  \"ignoreOriginList\": [],
  \"webBindAddress\": \"0.0.0.0\",
  \"webBindPort\": 8765,
  \"webCorsOriginList\": [\"http://localhost\", \"http://127.0.0.1\"]
}
EOF

  echo '- removing meta.json to clear any previous GUI overrides...'
  rm -f \"\$AC_DIR/meta.json\"

  echo '- fixing ownership...'
  chown -R abc:abc \"\$ROOT\"

  echo '- post-install verification (must show __init__.py at top level):'
  ls -la \"\$AC_DIR\" | sed -n '1,120p'
  if [ ! -f \"\$AC_DIR/__init__.py\" ]; then
    echo 'ERROR: __init__.py is missing at top-level of the add-on directory'; exit 1
  fi
  echo '✅ verified: __init__.py present at top-level of '"$AC_DIR"''

  echo '- final config.json:'
  sed -n '1,120p' \"\$AC_DIR/config.json\"

  echo '- cleanup temp...'
  rm -rf \"\$TMP\"
"

# ---------- Final state + next step ----------
echo
echo "📄 Final addons tree (top-level):"
docker exec "$SERVICE" bash -lc "ls -la '$ADDONS_ROOT'"

echo
echo "✅ AnkiConnect files are in place at: $AC_DIR"
echo
echo "📣 Next step: initialize desktop & load add-on"
echo "---------------------------------------------"
cat <<'NEXT'
1) Open the desktop Web UI:
   - Headless: ssh -L 3000:127.0.0.1:3000 <user>@<server-ip>, then open http://localhost:3000
   - Local:    open http://127.0.0.1:3000

2) In the desktop, launch Anki and confirm Tools → Add-ons shows “AnkiConnect”.
   - Config will show "webBindAddress": "0.0.0.0" due to enforced config and cleared overrides.

3) Validate the API from the host:
     ./validate-setup.sh
NEXT
echo
