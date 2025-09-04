# Anki API Docker

Containerized solution for interacting with your Anki cards via API.

## The Problem This Solves

**"Why isn't there an API for my Anki cards?"**

You have Anki cards and they sync to various devices via AnkiWeb, but there's no public API to access them like other cloud services. The excellent AnkiConnect add-on provides API functionality, but it integrates with your Anki Desktop installation on whatever machine runs Anki, often your personal computer. This means you have to have your laptop running if you want to execute scripts against your data in the AnkiWeb cloud.

Anki API Docker containerizes all of the necessary pieces and exposes AnkiConnect's clean HTTP API for AnkiWeb cards with minimal setup. You can self-host it and write scripts, MCP integrations, etc. against it.

## Requirements

- Docker and Docker Compose
- **AnkiWeb account with cards** (primary use case)
- 2GB+ RAM, 1GB+ disk space

## Quick Start

```
git clone https://github.com/batzlerg/anki-api-docker anki-api-docker
cd anki-api-docker
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

Run these commands from the terminal of whatever machine you installed Anki API onto:

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
docker compose restart anki-api-docker  # Restart if API stops responding

```

## Troubleshooting

**API not responding:** `docker compose restart anki-api-docker`  
**Sync issues:** Re-authenticate via web UI  
**Web UI access:** Use SSH tunnel for remote servers  

## Architecture

- **Base:** `pnorcross/anki-desktop` (LinuxServer.io)
- **AnkiConnect:** v23.10.29.0 (compatible with containerized Anki v2.1.54)
- **Storage:** Persistent Docker volume
- **Security:** Localhost-only bindings

Perfect for automated card generation, bulk operations, and custom applications using your existing AnkiWeb cards.
