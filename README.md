# Dawarich Home Assistant Addon

[![HA Addon][ha-addon-badge]][ha-addon-link]

A Home Assistant addon that runs [Dawarich](https://github.com/Freika/dawarich) — a self-hosted alternative to Google Timeline. Track your location history, visualize trips on a map, and keep full control of your data.

Everything runs in a single addon container: PostgreSQL, Redis, Sidekiq, and the Dawarich web app. No external services required.

## Features

- **Automatic location tracking** — polls HA device tracker entities and pushes GPS data to Dawarich
- **Multi-user support** — track multiple household members, each with their own Dawarich account and color on the map
- **Family map** — use Dawarich's built-in Family feature to share real-time locations between users
- **HA Ingress** — access the UI securely through the Home Assistant sidebar, no extra ports needed
- **Full backups** — integrates with HA's backup system including PostgreSQL dumps
- **Import support** — import existing location history from Google Takeout, OwnTracks, GPX, and more

## Quick Start

### 1. Install

Add this repository URL to your Home Assistant addon store:

```
https://github.com/thomdev-j/homeassistant-addon-dawarich
```

**Settings** → **Add-ons** → **Add-on Store** → **⋮** (top right) → **Repositories** → paste the URL → **Add**

Then find **Dawarich** in the store and click **Install**.

### 2. Configure

In the addon configuration tab, set at minimum:

| Option | What to set |
|---|---|
| `admin_email` | Your login email (default: `admin@dawarich.local`) |
| `admin_password` | Your login password (**change from `changeme`!**) |
| `time_zone` | Your timezone, e.g. `America/New_York`, `Europe/Berlin` |

### 3. Start

Click **Start**. First boot takes a few minutes (database initialization + asset compilation). Watch the **Log** tab for progress.

### 4. Open

Click **Open Web UI** in the sidebar, or navigate to `http://<your-ha-ip>:3000`. Log in with the email and password you configured.

## Automatic Location Tracking

The addon can poll Home Assistant `device_tracker` entities and automatically send their GPS data to Dawarich. No phone app needed — if Home Assistant already knows your location, Dawarich will too.

### Single user

Track one or more devices under the admin account:

```yaml
ha_tracked_entities: "device_tracker.my_phone"
```

### Multiple household members

Add a `:Name` suffix to create a separate Dawarich user per person:

```yaml
ha_tracked_entities: "device_tracker.my_phone:Alice, device_tracker.partner_phone:Bob"
```

This automatically creates:
- `alice@dawarich.local` (password: `password`)
- `bob@dawarich.local` (password: `password`)

Each device's location data goes to its own user. Users can change their password after first login.

You can mix named and unnamed entities — unnamed ones use the admin account:

```yaml
ha_tracked_entities: "device_tracker.my_phone:Alice, device_tracker.tablet"
```

### Adaptive polling

The tracker uses two polling intervals:

| Option | Default | When |
|---|---|---|
| `ha_polling_interval` | `30s` | Device has moved since last poll |
| `ha_polling_interval_stationary` | `300s` | Device hasn't moved (saves resources) |

Duplicate locations are automatically skipped.

### Family Map

To see all household members on a shared map with different colors:

1. Log into Dawarich as admin
2. Go to **Family** → create a group
3. Invite the other user(s)
4. Each user accepts and enables location sharing

This is a one-time setup in the Dawarich UI.

## All Configuration Options

| Option | Default | Description |
|---|---|---|
| `admin_email` | `admin@dawarich.local` | Admin login email |
| `admin_password` | `changeme` | Admin login password |
| `database_password` | `dawarich` | PostgreSQL password |
| `time_zone` | `Etc/UTC` | Application timezone |
| `application_hosts` | `homeassistant.local,localhost` | Allowed hostnames (add your HA IP if accessing directly on port 3000) |
| `background_processing_concurrency` | `5` | Sidekiq worker threads (1-20). Lower on Pi/constrained devices. |
| `ha_tracked_entities` | _(empty)_ | Device tracker entities to poll (see above) |
| `ha_polling_interval` | `30` | Polling interval when moving (seconds) |
| `ha_polling_interval_stationary` | `300` | Polling interval when stationary (seconds) |
| `photon_api_host` | _(optional)_ | Custom Photon geocoding API URL |
| `geoapify_api_key` | _(optional)_ | Geoapify API key for reverse geocoding |

## Data & Backups

All data persists across addon restarts and updates under `/data/`:

| Path | Contents |
|---|---|
| `/data/postgres/` | PostgreSQL database |
| `/data/redis/` | Redis persistence |
| `/data/dawarich/storage/` | User uploads and exports |
| `/data/dawarich/secret_key_base` | Auto-generated Rails secret |

**Backups** work with Home Assistant's built-in backup system. Before a backup, the addon dumps PostgreSQL to SQL so it can be cleanly restored. Raw database files are excluded — only the portable SQL dump is included.

## Security

- PostgreSQL and Redis bind to `localhost` only — not exposed outside the container
- The admin user is the only account with access to the Settings → Users page
- Home Assistant ingress provides authenticated access without exposing port 3000
- If you don't use ingress, port 3000 is available on your local network

## FAQ

### How long does first startup take?

2-5 minutes on modern hardware, 5-10 minutes on a Raspberry Pi. The addon needs to initialize PostgreSQL, run database migrations, and compile frontend assets. Subsequent starts are much faster.

### Can I import my Google Timeline data?

Yes. Export your data from [Google Takeout](https://takeout.google.com/) (select "Location History"), then use Dawarich's **My Data → Import** page to upload it.

### Do I need the Dawarich phone app?

Not if you're using the HA device tracking feature (`ha_tracked_entities`). The addon polls Home Assistant directly. You can still use the [Dawarich phone app](https://github.com/Freika/dawarich) or OwnTracks in addition if you prefer.

### I get a blank page or "blocked host" error

Add your Home Assistant's hostname or IP to `application_hosts`. For example: `homeassistant.local,localhost,192.168.1.100`. This is only needed when accessing port 3000 directly — ingress access works without it.

### Can I change the admin password after first setup?

Yes, log into Dawarich and change it through the UI (click your avatar → account settings). Changing `admin_password` in the addon config only affects initial user creation — it won't reset an existing password.

### How do I give another user admin access?

Log in as admin, go to **Settings → Users**, and promote the user from there.

### The map is empty after setup

Location data needs time to accumulate. If using HA tracking, check the addon logs for `HA Tracker: pushed` messages to confirm data is flowing. Verify your device tracker entities have GPS coordinates in **Developer Tools → States**.

### How do I reset everything and start fresh?

Stop the addon, delete the `/data/` directory contents via SSH or the file editor addon, and restart. The addon will reinitialize from scratch.

### What architectures are supported?

`amd64` (Intel/AMD) and `aarch64` (Raspberry Pi 4/5, Apple Silicon via HA OS).

## Links

- [Dawarich](https://github.com/Freika/dawarich) — upstream project
- [Dawarich Documentation](https://dawarich.app/) — full feature documentation
- [Report an issue](https://github.com/thomdev-j/homeassistant-addon-dawarich/issues)

[ha-addon-badge]: https://img.shields.io/badge/Home%20Assistant-Addon-blue?logo=homeassistant
[ha-addon-link]: https://github.com/thomdev-j/homeassistant-addon-dawarich
