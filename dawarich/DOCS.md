# Dawarich Home Assistant Addon

Self-hosted location tracking — a Google Timeline alternative, running as a Home Assistant addon.

## Overview

This addon bundles [Dawarich](https://github.com/Freika/dawarich) with all required services in a single container:

- **PostgreSQL 17 + PostGIS** — spatial database
- **Redis 7.4** — cache and job queue
- **Dawarich** — Rails web application
- **Sidekiq** — background job processor

## Installation

1. Add this repository to your Home Assistant addon store
2. Install the Dawarich addon
3. (Optional) Adjust configuration options
4. Start the addon
5. Open the web UI at `http://<your-ha-ip>:3000`
6. Create your first account

## Configuration

| Option | Default | Description |
|---|---|---|
| `database_password` | `dawarich` | PostgreSQL password. Change from default for security. |
| `secret_key_base` | _(auto-generated)_ | Rails secret key. Leave empty for auto-generation on first run. |
| `time_zone` | `Europe/Vienna` | Timezone for the application (e.g., `America/New_York`). |
| `application_hosts` | `homeassistant.local,localhost` | Comma-separated list of hostnames the app responds to. Add your HA hostname/IP. |
| `background_processing_concurrency` | `5` | Number of Sidekiq worker threads (1-20). Lower for constrained devices. |
| `photon_api_host` | _(optional)_ | Custom Photon geocoding API host URL. |
| `geoapify_api_key` | _(optional)_ | Geoapify API key for reverse geocoding. |

### Important Notes

- **First start** takes several minutes while PostgreSQL initializes and Rails runs migrations
- **`application_hosts`** must include the hostname/IP you use to access the UI, or Rails will reject requests
- **`secret_key_base`** is auto-generated and stored in `/data/dawarich/secret_key_base` — do not change it after initial setup or existing sessions will be invalidated

## Data Persistence

All data is stored under `/data/` and survives addon restarts and updates:

- `/data/postgres/` — PostgreSQL data directory
- `/data/redis/` — Redis persistence files
- `/data/dawarich/storage/` — User uploads and exports
- `/data/dawarich/secret_key_base` — Auto-generated secret key

## Backups

Home Assistant backups are supported:

- **Pre-backup:** PostgreSQL is dumped to `/data/dawarich/backup.sql` via `pg_dumpall`
- **Post-backup:** The SQL dump is cleaned up to save disk space
- Raw PostgreSQL files (`postgres/**`) are excluded from the backup — only the SQL dump is included

To restore from backup, the addon will automatically detect and restore the SQL dump on startup if the PostgreSQL data directory is empty.

## Network Security

- PostgreSQL binds to `localhost` only — port 5432 is **not** exposed outside the container
- Redis binds to `localhost` only — port 6379 is **not** exposed outside the container
- Only port 3000 (web UI) is exposed

## Troubleshooting

### Addon won't start
- Check the addon logs in Home Assistant for error messages
- Ensure you have enough disk space (PostgreSQL needs at least 100MB)
- On Raspberry Pi, first start may take 5+ minutes

### Can't access web UI
- Verify your hostname/IP is in `application_hosts`
- Check that port 3000 is not blocked by your network

### Data import fails
- Check Sidekiq is running in the addon logs
- Large imports may take significant time — check background job status in the Dawarich UI
