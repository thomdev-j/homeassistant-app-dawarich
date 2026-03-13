# Dawarich Home Assistant Addon

**This addon runs a full [Dawarich](https://github.com/Freika/dawarich) instance directly on your Home Assistant OS device** — a self-hosted alternative to Google Timeline. No separate server or Docker Compose setup needed. Just install, and you have location tracking with full control of your data.

## Overview

Everything is bundled into a single addon container:

- **PostgreSQL 17 + PostGIS** — spatial database
- **Redis 7.4** — cache and job queue
- **Dawarich** — Rails web application
- **Sidekiq** — background job processor
- **Nginx** — ingress reverse proxy

## Installation

1. Add this repository to your Home Assistant addon store
2. Install the Dawarich addon (the image is roughly 1 GB — initial download may take a while)
3. Adjust configuration options (see below)
4. Start the addon — first boot initializes the database and compiles assets, subsequent starts are fast (under 15 seconds)
5. Open the web UI via the sidebar panel or at `http://<your-ha-ip>:3000`
6. Log in with the admin credentials from your addon config

## Configuration

### General

| Option | Default | Description |
|---|---|---|
| `admin_email` | `admin@dawarich.local` | Email address used to log into Dawarich as admin. |
| `admin_password` | `changeme` | Password for the admin account. **Change this!** Only used on first creation — change password through the Dawarich UI after that. |
| `time_zone` | `Etc/UTC` | Timezone for the application (e.g., `America/New_York`, `Europe/Berlin`). |
| `database_password` | `dawarich` | Internal PostgreSQL password. Not exposed externally. |
| `application_hosts` | `homeassistant.local,localhost` | Comma-separated hostnames/IPs Rails accepts. Only needed for direct port 3000 access — ingress works without it. Add your HA IP if you get "blocked host" errors. |
| `background_processing_concurrency` | `5` | Sidekiq worker threads (1-20). Lower on constrained devices like Raspberry Pi 3. |

### Device Tracking

The addon can automatically poll Home Assistant device tracker entities and push their location data to Dawarich.

| Option | Default | Description |
|---|---|---|
| `ha_tracked_entities` | _(empty)_ | Comma-separated list of `device_tracker.*` entity IDs to poll. Leave empty to disable. |
| `ha_polling_interval` | `30` | Polling interval in seconds when a device is moving (5-3600). |
| `ha_polling_interval_stationary` | `300` | Polling interval in seconds when stationary (30-3600). |

**Basic usage** — track a single device under the admin user:
```
ha_tracked_entities: "device_tracker.my_phone"
```

**Multi-user** — create separate Dawarich users per person by adding a `:Name` suffix:
```
ha_tracked_entities: "device_tracker.my_phone:Alice, device_tracker.partner_phone:Bob"
```

This creates `alice@dawarich.local` and `bob@dawarich.local` with default password `password`. Each device's location data is sent to its own user. Users can change their password after first login via the Dawarich settings page.

Entities without a `:Name` suffix use the admin user. You can mix both styles:
```
ha_tracked_entities: "device_tracker.my_phone:Alice, device_tracker.tablet"
```

#### Adaptive Polling

The tracker uses two intervals to balance data resolution against resource usage:

- **Moving interval** — used when a device has changed position. Lower values give more detailed tracks.
- **Stationary interval** — used when a device hasn't moved. Avoids wasting resources polling a device sitting on a desk. Automatically switches back to the moving interval when movement is detected.

Duplicate locations (same lat/lon) are always skipped — no redundant data is stored.

#### Family Map (multi-user)

After creating multiple users, you can set up Dawarich's built-in Family feature to see everyone on a shared map with different colors:

1. Log into Dawarich as admin
2. Go to **Family** and create a group
3. Invite the other user(s)
4. Each user accepts and enables location sharing

### Optional / Advanced

| Option | Default | Description |
|---|---|---|
| `photon_api_host` | _(optional)_ | URL of a self-hosted Photon geocoding server for reverse geocoding. |
| `geoapify_api_key` | _(optional)_ | Geoapify API key for reverse geocoding. Free tier covers personal use. |

### Important Notes

- **`application_hosts`** must include the hostname/IP you use to access the UI, or Rails will reject requests (not needed for ingress)
- **`secret_key_base`** is auto-generated on first start and stored in `/data/dawarich/secret_key_base` — sessions are invalidated if this file is deleted
- **Admin user** is created on first start with the configured email/password. The password is only set on creation — changing it in the addon config won't update an existing user. Use the Dawarich UI to change passwords.

## Data Persistence

All data is stored under `/data/` and survives addon restarts and updates:

- `/data/postgres/` — PostgreSQL data directory
- `/data/redis/` — Redis persistence files
- `/data/dawarich/storage/` — User uploads and exports
- `/data/dawarich/secret_key_base` — Auto-generated secret key
- `/data/dawarich/api_keys/` — Per-entity API keys for HA tracking

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
- The addon supports Home Assistant ingress for secure access without exposing port 3000

## Troubleshooting

### Addon won't start
- Check the addon logs in Home Assistant for error messages
- Ensure you have enough disk space (PostgreSQL needs at least 100MB)

### Can't access web UI
- Verify your hostname/IP is in `application_hosts`
- Check that port 3000 is not blocked by your network
- Try using the ingress panel in the HA sidebar instead

### HA Tracker not sending data
- Check addon logs for "HA Tracker:" messages
- Verify entity IDs exist in Home Assistant (Developer Tools → States)
- Ensure the entities have GPS attributes (latitude/longitude)

### Data import fails
- Check Sidekiq is running in the addon logs
- Large imports may take significant time — check background job status in the Dawarich UI
