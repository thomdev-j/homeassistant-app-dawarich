# Dawarich Home Assistant Addon

[![HA Addon][ha-addon-badge]][ha-addon-link]

**This addon runs a full [Dawarich](https://github.com/Freika/dawarich) instance directly on your Home Assistant OS device** — a self-hosted alternative to Google Timeline. No separate server or Docker Compose setup needed. Just install, and you have location tracking with full control of your data.

> **Note:** This addon requires [Home Assistant OS](https://www.home-assistant.io/installation/) (HAOS), which provides the addon system. Home Assistant Container or Core installations cannot run addons.

## Features

- **Zero setup** — PostgreSQL, Redis, and all dependencies bundled in a single addon container
- **Automatic HA device tracking** — polls your `device_tracker` entities and pushes GPS data to Dawarich automatically
- **Multi-device, multi-user** — assign devices to separate Dawarich users per household member via addon config
- **HA Ingress** — access the UI securely through the Home Assistant sidebar, no extra ports needed
- **Full backups** — integrates with HA's backup system including automatic PostgreSQL dumps

## Quick Start

### 1. Install

Add this repository URL to your Home Assistant addon store:

```
https://github.com/thomdev-j/homeassistant-addon-dawarich
```

**Settings** → **Add-ons** → **Add-on Store** → **⋮** (top right) → **Repositories** → paste the URL → **Add**

Then find **Dawarich** in the store and click **Install**. The image is roughly 1 GB, so the initial download may take a while depending on your internet connection.

### 2. Configure

In the addon configuration tab, set at minimum:

| Option | What to set |
|---|---|
| `admin_email` | Your login email (default: `admin@dawarich.local`) |
| `admin_password` | Your login password (**change from `changeme`!**) |
| `time_zone` | Your timezone, e.g. `America/New_York`, `Europe/Berlin` |

### 3. Start

Click **Start**. The first boot initializes the database and compiles frontend assets, which takes a bit longer. Subsequent starts are fast (under 15 seconds, even on a Raspberry Pi). Watch the **Log** tab for progress.

### 4. Open

Click **Open Web UI** in the sidebar, or navigate to `http://<your-ha-ip>:3000`. Log in with the email and password you configured.

## Automatic Location Tracking

The addon can poll Home Assistant `device_tracker` entities and automatically send their GPS data to Dawarich. No phone app needed — if Home Assistant already knows your location, Dawarich will too.

### Single user

Track one or more devices under the admin account:

```yaml
ha_tracked_entities: "device_tracker.my_phone"
```

Multiple devices for the same user:

```yaml
ha_tracked_entities: "device_tracker.my_phone, device_tracker.my_tablet"
```

### Multiple household members

Add a `:Name` suffix to create a separate Dawarich user per person:

```yaml
ha_tracked_entities: "device_tracker.my_phone:Alice, device_tracker.partner_phone:Bob"
```

This automatically creates:
- `alice@dawarich.local` (password: `password`)
- `bob@dawarich.local` (password: `password`)

Each device's location data goes to its own user. Users can change their password after first login via the Dawarich settings page.

Two devices for the same person share one user — just use the same name:

```yaml
ha_tracked_entities: "device_tracker.alices_phone:Alice, device_tracker.alices_watch:Alice"
```

You can mix named and unnamed entities — unnamed ones use the admin account:

```yaml
ha_tracked_entities: "device_tracker.my_phone:Alice, device_tracker.tablet"
```

### Adaptive polling

The tracker uses two polling intervals to balance data resolution against system resources:

- **Moving interval** (`ha_polling_interval`, default `30s`) — used when a device has changed position since the last poll. Lower values give more detailed tracks but increase CPU and network usage.
- **Stationary interval** (`ha_polling_interval_stationary`, default `300s`) — used when a device hasn't moved. There's no value in polling every 30 seconds if someone is sitting at their desk, so the tracker backs off to save resources. As soon as movement is detected, it switches back to the moving interval.

Duplicate locations (same lat/lon as last poll) are always skipped regardless of interval — no redundant data is stored.

**Tuning tips:**
- For walking/cycling detail, try `ha_polling_interval: 15`
- For a car commute, `30` (default) is usually fine
- On low-power devices (Pi 3), increase `ha_polling_interval_stationary` to `600` or higher
- The minimum allowed value is `5s` (moving) and `30s` (stationary)

### Family Map

To see all household members on a shared map with different colors:

1. Log into Dawarich as admin
2. Go to **Family** → create a group
3. Invite the other user(s)
4. Each user accepts and enables location sharing

This is a one-time setup in the Dawarich UI.

## All Configuration Options

### General

| Option | Default | Description |
|---|---|---|
| `admin_email` | `admin@dawarich.local` | Email address used to log into Dawarich as admin. Also shown in the Users page. |
| `admin_password` | `changeme` | Password for the admin account. Only used on first creation — changing this later won't update an existing account. Change your password through the Dawarich UI instead. |
| `time_zone` | `Etc/UTC` | Timezone for displaying dates and times in the UI. Uses standard [tz database names](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) (e.g. `America/New_York`, `Europe/Berlin`, `Asia/Tokyo`). |
| `database_password` | `dawarich` | Password for the internal PostgreSQL database. Only relevant inside the container — not exposed externally. Changing this after first setup requires manual database migration. |
| `application_hosts` | `homeassistant.local,localhost` | Comma-separated list of hostnames/IPs that Rails accepts requests from. Only needed when accessing Dawarich directly on port 3000. Ingress access (via the sidebar) works regardless of this setting. Add your HA IP if you get "blocked host" errors, e.g. `homeassistant.local,localhost,192.168.1.100`. |
| `background_processing_concurrency` | `5` | Number of Sidekiq worker threads for background jobs (imports, reverse geocoding, stats). Range: 1-20. Lower this on resource-constrained devices like Raspberry Pi 3 (`2`-`3`). Increase for faster import processing on powerful hardware. |

### Device Tracking

| Option | Default | Description |
|---|---|---|
| `ha_tracked_entities` | _(empty)_ | Comma-separated list of `device_tracker.*` entity IDs to poll for GPS data. Leave empty to disable automatic tracking. Optionally add a `:Name` suffix to assign a device to a specific user (see [Multi-user](#multiple-household-members) above). Find your entity IDs in HA under **Developer Tools → States**. |
| `ha_polling_interval` | `30` | How often (in seconds) to poll devices that are moving. Range: 5-3600. Lower = more detailed tracks but more resource usage. See [Adaptive polling](#adaptive-polling) for details. |
| `ha_polling_interval_stationary` | `300` | How often (in seconds) to poll devices that haven't moved. Range: 30-3600. Higher = less wasted polling when devices are stationary. Automatically switches to the moving interval when movement is detected. |

### Optional / Advanced

| Option | Default | Description |
|---|---|---|
| `photon_api_host` | _(empty)_ | URL of a self-hosted [Photon](https://github.com/komoot/photon) geocoding server for reverse geocoding (turning coordinates into addresses). Leave empty to skip or use Dawarich's built-in options. |
| `geoapify_api_key` | _(empty)_ | API key for [Geoapify](https://www.geoapify.com/) reverse geocoding service. Free tier covers personal use. Configure this if you want automatic address labels on your location points. |

## Data & Backups

All data persists across addon restarts and updates under `/data/`:

| Path | Contents |
|---|---|
| `/data/postgres/` | PostgreSQL database |
| `/data/redis/` | Redis persistence |
| `/data/dawarich/storage/` | User uploads and exports |
| `/data/dawarich/secret_key_base` | Auto-generated Rails secret (sessions are invalidated if deleted) |

**Backups** work with Home Assistant's built-in backup system. Before a backup, the addon dumps PostgreSQL to SQL so it can be cleanly restored. Raw database files are excluded — only the portable SQL dump is included.

## Security

- PostgreSQL and Redis bind to `localhost` only — not exposed outside the container
- The admin user is the only account with access to the Settings → Users page
- Home Assistant ingress provides authenticated access without exposing port 3000
- If you don't use ingress, port 3000 is available on your local network

## FAQ

### Can I import my Google Timeline data?

Yes. Export your data from [Google Takeout](https://takeout.google.com/) (select "Location History"), then use Dawarich's **My Data → Import** page to upload it.

### Do I need the Dawarich phone app?

Not if you're using the HA device tracking feature (`ha_tracked_entities`). The addon polls Home Assistant directly. You can still use the [Dawarich phone app](https://github.com/Freika/dawarich) or OwnTracks in addition if you prefer.

### I get a blank page or "blocked host" error

Add your Home Assistant's hostname or IP to `application_hosts`. For example: `homeassistant.local,localhost,192.168.1.100`. This is only needed when accessing port 3000 directly — ingress access (via the sidebar) works without it.

### Can I change the admin password after first setup?

Yes, log into Dawarich and change it through the UI (click your avatar → account settings). Changing `admin_password` in the addon config only affects initial user creation — it won't reset an existing password.

### How do I give another user admin access?

Log in as admin, go to **Settings → Users**, and promote the user from there.

### The map is empty after setup

Location data needs time to accumulate. If using HA tracking, check the addon logs for `HA Tracker: pushed` messages to confirm data is flowing. Verify your device tracker entities have GPS coordinates in **Developer Tools → States**.

### How do I find my device tracker entity IDs?

In Home Assistant, go to **Developer Tools → States** and filter for `device_tracker.`. Entities with `latitude` and `longitude` attributes will work with this addon.

### How do I reset everything and start fresh?

Stop the addon, delete the `/data/` directory contents via SSH or the file editor addon, and restart. The addon will reinitialize from scratch.

### What architectures are supported?

`amd64` (Intel/AMD) and `aarch64` (Raspberry Pi 4/5, Apple Silicon via HA OS).

## License

This addon is licensed under the [GNU Affero General Public License v3.0](LICENSE).

This addon builds on top of the [Dawarich](https://github.com/Freika/dawarich) Docker image (`freikin/dawarich`), copyright [Freika](https://github.com/Freika), also licensed under AGPL-3.0.

## Links

- [Dawarich](https://github.com/Freika/dawarich) — upstream project
- [Dawarich Documentation](https://dawarich.app/) — full feature documentation
- [Report an issue](https://github.com/thomdev-j/homeassistant-addon-dawarich/issues)

[ha-addon-badge]: https://img.shields.io/badge/Home%20Assistant-Addon-blue?logo=homeassistant
[ha-addon-link]: https://github.com/thomdev-j/homeassistant-addon-dawarich
