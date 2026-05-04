# Changelog

## 1.7.5-1

- Upgrade base image to Dawarich 1.7.5
- See [release notes](https://github.com/Freika/dawarich/releases/tag/1.7.5) for upstream changes

## 1.7.1-1

- Upgrade base image to Dawarich 1.7.1 — see upstream [1.7.0](https://github.com/Freika/dawarich/releases/tag/1.7.0) and [1.7.1](https://github.com/Freika/dawarich/releases/tag/1.7.1) release notes for user-facing changes

## 1.6.1-1

- Upgrade base image to Dawarich 1.6.1
- Immich photo enrichment with geodata (1.6.0)
- Two-factor authentication with TOTP and backup codes (1.6.0)
- GPS noise filtering, map layer management, "Day per Country" analytics (1.5.0)
- Family page map, visit confirmation buttons, visual redesign (1.4.0)
- 50+ bug fixes across 1.4.0–1.6.1 including deadlock fixes, memory crash on large imports, and compressed zip import failures

## 1.3.4-2

- Add `photon_api_key` config option for Dawarich Patreon supporters using `photon.dawarich.app`
- Fix startup crash (exit 22) when geocoding API test fails
- Public Photon instance (`photon.komoot.io`) now supports reverse geocoding

## 1.3.4-1

- Upgrade base image to Dawarich 1.3.4
- Family location sharing, redesigned onboarding, geocoding and UI fixes

## 1.3.3-70

- Fix Photon host format — strip protocol prefix, set `PHOTON_API_USE_HTTPS` separately per Dawarich docs

## 1.3.3-69

- Add Geoapify API startup test to verify API key works

## 1.3.3-68

- Fix Geoapify/Photon env vars being set simultaneously — now mutually exclusive

## 1.3.3-67

- Default `reverse_geocoding` to `false` — public Photon instance does not support reverse geocoding
- Document provider options: Geoapify (free API key), self-hosted Photon, Dawarich Patreon

## 1.3.3-66

- Add Photon API connectivity test on startup with debug logging

## 1.3.3-65

- Add reverse geocoding support with `reverse_geocoding` toggle, `photon_api_host`, and `geoapify_api_key` config options
- Test geocoding API on startup and log result
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
