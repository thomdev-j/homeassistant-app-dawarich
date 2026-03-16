# Changelog

## 1.3.3-65

- Enable reverse geocoding out of the box via public Photon service (free, no API key)
- Add optional `photon_api_host` and `geoapify_api_key` config for self-hosted or alternative providers
- Fix `FATAL: role "root" does not exist` log warnings during startup

## 1.3.3-62

- Remove polling fallback — tracker now uses real-time SSE exclusively
- Remove `ha_polling_interval` and `ha_polling_interval_stationary` config options
- Add configurable GPS drift filter (`ha_min_distance`, default 10m) — prevents stationary phones from generating spurious data points due to GPS signal fluctuation. Set to `0` to disable.

## 1.3.3-60

- Rewrite HA tracker to use real-time SSE event stream
- Persist session cookies for 1 year to prevent unexpected logouts
- Extend Devise remember-me token to 1 year with sliding expiry

## 1.3.3-56

- Show friendly loading page instead of raw 502 Bad Gateway while Dawarich starts up

## 1.3.3-55

- Rename "addon" to "app" throughout docs and metadata to match Home Assistant's updated terminology
- Fix logout not fully signing out: clear stale session cookies at root path and flush Turbo page cache on sign-out

## 1.3.3-53

- Add multi-user device tracking: use `:Name` suffix in `ha_tracked_entities` to create separate Dawarich users per household member
- Grant admin privileges to the configured admin user automatically
- Fix CSRF 422 errors on login/logout via ingress
- Fix ingress compatibility for forms, redirects, and WebSocket connections
- Fix navigation and login/logout via HTTPS reverse proxies (e.g. Cloudflare tunnel)
- Add graceful Sidekiq shutdown to avoid interrupted background jobs
- Bail out on database migration failure instead of starting with broken state
- Remove `secret_key_base`, `photon_api_host`, and `geoapify_api_key` from addon config (auto-generated or configurable in Dawarich UI)
- Suppress Redis memory overcommit warning in logs
- Clean up stale API key files when entity config changes
- Default timezone changed to `Etc/UTC`
- Comprehensive README with quickstart guide, configuration reference, hardware requirements, and FAQ

## 1.3.3-1

- Initial release
- Based on Dawarich v1.3.3
- Bundled PostgreSQL 17 + PostGIS, Redis 7.4
- s6-overlay process supervision
- Auto-generated SECRET_KEY_BASE persisted across restarts
- Home Assistant backup support with pg_dumpall
