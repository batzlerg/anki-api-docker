# AnkiBot

Containerized solution for interacting with your Anki cards via API.

## The Problem AnkiBot Solves

**"Why isn't there an API for my Anki cards?"**

You have Anki cards and they sync to various devices via AnkiWeb, but there's no direct API to access them. The AnkiConnect add-on provides this, but it depends on your Anki Desktop installation as the persistence layer. This makes scripted interactions against your collection of cards difficult and prone to sync issues.

AnkiBot containerizes everything - giving you a clean HTTP API for your existing AnkiWeb cards with minimal setup. You can host it on a home server and have a single source of truth for your scripts to interact with.

## Requirements

- Docker and Docker Compose
- **Existing AnkiWeb account with cards** (primary use case)
- 2GB+ RAM, 1GB+ disk space

## Quick Start

```
git clone https://github.com/batzlerg/anki-bot anki-bot
cd anki-bot
chmod +x setup.sh
./setup.sh

```

## Configuration (3 minutes)

### Step 1: Access Setup Interface
**Local:** http://localhost:3000  
**Remote:** `ssh -L 3000:127.0.0.1:3000 username@server-ip` then http://localhost:3000

### Step 2: Connect AnkiWeb
1. Select your language from the menu
2. **Click "Sync"** and enter AnkiWeb credentials
3. Wait for cards to download
4. Close the localhost:3000 (this will continue running in the background)

### Step 3: Test API
```
./validate-setup.sh

```

## Using Your AnkiWeb Cards API

Working example with correct container networking:

```
# List your decks

curl -X POST http://127.0.0.1:8765 -H 'Content-Type: application/json' \
-d '{"action":"deckNames","version":6}'

# Add a card

curl -X POST http://127.0.0.1:8765 -H 'Content-Type: application/json' \
-d '{"action":"addNote","version":6,"params":{"note":{"deckName":"Default","modelName":"Basic","fields":{"Front":"API Question","Back":"API Answer"}}}}'

# Sync changes back to AnkiWeb

curl -X POST http://127.0.0.1:8765 -H 'Content-Type: application/json' \
-d '{"action":"sync","version":6}'

```

**Complete API documentation:** [AnkiConnect API Reference](https://foosoft.net/projects/anki-connect/)

## Container Management

```

docker compose down    # Stop
docker compose up -d   # Start (auto-reconnects to AnkiWeb)
docker compose restart anki-headless  # Restart if API stops responding

```

## Troubleshooting

**API not responding:** `docker compose restart anki-headless`  
**Sync issues:** Re-authenticate via web UI  
**Web UI access:** Use SSH tunnel for remote servers  

## Architecture

- **Base:** `pnorcross/anki-desktop` (LinuxServer.io)
- **AnkiConnect:** v23.10.29.0 (compatible with containerized Anki v2.1.54)
- **Storage:** Persistent Docker volume
- **Security:** Localhost-only bindings

Perfect for automated card generation, bulk operations, and custom applications using your existing AnkiWeb cards.
