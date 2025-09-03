# AnkiBot

Headless Anki Desktop with AnkiConnect API baked into a single Docker container to enable plug & play scripting against Anki knowledge base.

WIP: building on API access for LLM integration and voice control.

## Requirements

- Docker and Docker Compose
- SSH access (for headless servers)
- Web browser (for accessing remote desktop UI)
- 2GB+ RAM recommended
- 1GB+ disk space for Anki data

## Quick Start

1. **Clone and setup**:
```bash
git clone <your-repo-url> anki-bot
cd anki-bot
chmod +x setup.sh
./setup.sh
```

2. **Launch Anki Desktop**:
    - Access the web UI via SSH tunnel (headless) or directly (GUI servers)
    - Launch Anki Desktop application from the web interface
    - AnkiConnect is pre-configured - no manual setup required
3. **Test API**:
```bash
curl -X POST http://127.0.0.1:8765 \
  -H 'Content-Type: application/json' \
  -d '{"action":"version","version":6}'
```

*Expected: `{"result": 6, "error": null}`*

## Initial Configuration

### For Headless Servers (no GUI/browser)

1. **Create SSH tunnel from your local machine**:
```bash
ssh -L 3000:127.0.0.1:3000 <username>@<server-ip>
```

*Example: `ssh -L 3000:127.0.0.1:3000 user@192.168.0.110`*

2. **Access web UI**: Open http://localhost:3000 in your local browser

### For Servers with Browser Access

**Access web UI directly**: Open http://127.0.0.1:3000

### Complete Setup (Both Methods)

1. **Launch Anki Desktop**: Click on the Anki icon or find it in the applications menu
2. **Ready to Use**: AnkiConnect API is pre-configured and available immediately
3. **Optional - Sync existing decks**:
    - Click "Sync" in Anki Desktop
    - Enter your AnkiWeb credentials when prompted
    - Wait for sync to complete

## API Documentation

### Basic Operations

**Version Check:**

```bash
curl -X POST http://127.0.0.1:8765 \
  -H 'Content-Type: application/json' \
  -d '{"action":"version","version":6}'
```

**List Decks:**

```bash
curl -X POST http://127.0.0.1:8765 \
  -H 'Content-Type: application/json' \
  -d '{"action":"deckNames","version":6}'
```

**Add Note:**

```bash
curl -X POST http://127.0.0.1:8765 \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "addNote",
    "version": 6,
    "params": {
      "note": {
        "deckName": "Default",
        "modelName": "Basic",
        "fields": {
          "Front": "Question",
          "Back": "Answer"
        }
      }
    }
  }'
```

**Find Cards:**

```bash
curl -X POST http://127.0.0.1:8765 \
  -H 'Content-Type: application/json' \
  -d '{"action":"findCards","version":6,"params":{"query":"deck:Default"}}'
```

## Services

- **AnkiConnect API**: http://127.0.0.1:8765 (localhost-only, available after Anki Desktop launch)
- **Web UI**: http://127.0.0.1:3000 (remote desktop interface)

## Management

```bash
# Stop services
docker compose down

# Start services (requires relaunching Anki Desktop)
docker compose up -d

# View logs
docker compose logs anki-headless

# Check status
docker compose ps

# Restart container
docker compose restart anki-headless
```


## Data Persistence

All Anki data is stored in the Docker named volume:

- `anki_profile`: Complete Anki user profile, decks, and add-on data

Data persists across container restarts and system reboots. **Note**: Anki Desktop must be manually relaunched after container restarts.

## Validation + Debugging

### Quick Validation

Run the included validation script:

```bash
chmod +x debug_anki.sh
./debug_anki.sh
```


### Manual API Tests

```bash
# Test connectivity
curl -s http://127.0.0.1:8765

# Test deck operations
curl -X POST http://127.0.0.1:8765 \
  -H 'Content-Type: application/json' \
  -d '{"action":"deckNames","version":6}'

# Test card search
curl -X POST http://127.0.0.1:8765 \
  -H 'Content-Type: application/json' \
  -d '{"action":"findCards","version":6,"params":{"query":"is:due"}}'
```


## Troubleshooting

### Common Issues

**API not responding on port 8765:**

- **Cause**: Anki Desktop not launched
- **Solution**: Access web UI and start Anki Desktop application

**Web UI inaccessible:**

- **Cause**: Container not running or port mapping issue
- **Solution**: Check `docker compose ps` and use SSH tunnel for headless servers

**Container startup fails:**

- **Cause**: Port conflicts or Docker issues
- **Solution**: Check logs with `docker compose logs anki-headless`


### Debug Commands

```bash
# Check if Anki Desktop is running
docker exec anki-headless ps aux | grep -i anki

# Verify AnkiConnect configuration
docker exec anki-headless cat /config/app/Anki2/addons21/2055492159/config.json

# Test API from inside container
docker exec anki-headless curl -s http://127.0.0.1:8765
```

## Development + Integration

## Architecture

- Base image is `pnorcross/anki-desktop` (uses LinuxServer.io)
 - uses noVNC for remote desktop WebUI
- AnkiConnect version is v23.10.29.0 (todo: update / make easier to update)
- Single Docker volume for storage
- LAN-only bindings

### WIP

- Connect language models to Anki operations
- STT → API → TTS workflows
- Programmatic review and scheduling
- LLM-assisted flashcard creation based on study progress

### TODO (maybe)

- Replace hard-coded Anki v2.1.54 from anki-desktop-docker, update AnkiConnect accordingly
