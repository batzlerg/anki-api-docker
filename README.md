# AnkiBot
Dockerized headless Anki Desktop with AnkiConnect API for local-only automation and scripting. WIP: agentic LLM assistant, voice control

## Quick Start

1. **Clone and setup**:
```

git clone <your-repo-url> anki-headless
cd anki-headless
chmod +x setup.sh
./setup.sh

```

2. **Complete initial configuration** (required - see details below):
   - Access the Anki Desktop web UI at port 3000
   - Manually launch Anki Desktop application
   - Optionally sync with AnkiWeb for existing decks

3. **Test API**:
```

curl -X POST http://127.0.0.1:8765 \
-H 'Content-Type: application/json' \
-d '{"action":"deckNames","version":6}'

```

## Initial Configuration

**The setup script provisions the container but requires manual steps to activate the AnkiConnect API.**

### For Headless Servers (no GUI/browser)

1. **Create SSH tunnel from your local machine**:
```

ssh -L 3000:127.0.0.1:3000 <username>@<server-ip>

```
Example: `ssh -L 3000:127.0.0.1:3000 user@192.168.0.110`

2. **Access web UI**: Open http://localhost:3000 in your local browser

### For Servers with Browser Access

**Access web UI directly**: Open http://127.0.0.1:3000

### Complete Setup (Both Methods)

1. **Launch Anki Desktop**: Click on the Anki icon or find it in the applications menu within the web interface
2. **Optional - Sync existing decks**: 
   - Click "Sync" in Anki Desktop
   - Enter your AnkiWeb credentials when prompted
   - Wait for sync to complete
3. **Verify API**: The AnkiConnect API will now respond on port 8765

## Services

- **AnkiConnect API**: http://127.0.0.1:8765 (localhost-only) - *Available only after Anki Desktop is launched*
- **Web UI**: http://127.0.0.1:3000 (remote desktop interface)

## Management

- Stop: `docker compose down`
- Restart: `docker compose up -d` (requires relaunching Anki Desktop through web UI)
- Logs: `docker compose logs anki-headless`
- Status: `docker compose ps`

## Data Persistence

All Anki data is stored in Docker named volumes:
- `anki_profile`: Anki user profile and decks  
- `anki_addons`: AnkiConnect add-on

Data persists across container restarts and system reboots. However, **Anki Desktop must be manually relaunched** after container restarts.

## Troubleshooting

- **API not responding on port 8765**: Anki Desktop hasn't been launched yet. Access the web UI and start the application.
- **Web UI inaccessible**: Ensure the container is running (`docker compose ps`) and try the SSH tunnel method for headless servers.
- **Sync issues**: Use the "Check Database" option in Anki's Tools menu if sync fails.
