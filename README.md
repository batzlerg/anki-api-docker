# AnkiBot

Dockerized headless Anki Desktop with AnkiConnect API for local-only automation and scripting. WIP: agentic LLM assistant, voice control

## Quick Start

1. Clone and setup:
```

git clone <your-repo-url> anki-headless
cd anki-headless
chmod +x setup.sh
./setup.sh

```

2. Test API:
```

curl -X POST http://127.0.0.1:8765 \
-H 'Content-Type: application/json' \
-d '{"action":"deckNames","version":6}'

```

## Services

- **AnkiConnect API**: http://127.0.0.1:8765 (localhost-only)
- **Web UI**: http://127.0.0.1:3000 (optional debugging interface)

## Management

- Stop: `docker compose down`
- Restart: `docker compose up -d`
- Logs: `docker compose logs anki-headless`
- Status: `docker compose ps`

## Data Persistence

All Anki data is stored in Docker named volumes:
- `anki_profile`: Anki user profile and decks
- `anki_addons`: AnkiConnect add-on

Data persists across container restarts and system reboots.
```


## B) User Setup Instructions

### Prerequisites

- Docker and Docker Compose installed
- Git available
- SSH access to 192.168.0.110


### Setup Steps

1. **Clone the repository**:
```bash
git clone <your-repo-url> anki-headless
cd anki-headless
```

2. **Run the setup script**:
```bash
chmod +x setup.sh
./setup.sh
```

3. **Verify setup**:
The script will automatically test the AnkiConnect API and report success/failure.

### Expected Output

```
Setting up headless Anki with AnkiConnect...
Starting Anki container to provision volumes...
Installing AnkiConnect add-on...
Restarting Anki to load AnkiConnect...
Waiting for Anki to become healthy...
Anki is healthy!
Testing AnkiConnect API...
✓ AnkiConnect is responding
✓ AnkiConnect API is working correctly
Response: {"result":[],"error":null}

Setup complete! Headless Anki with AnkiConnect is running.
API available at: http://127.0.0.1:8765
Web UI available at: http://127.0.0.1:3000 (optional, for debugging)
```
