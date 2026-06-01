# Changelog

## 1.7.11-1

- Upgrade base image to Dawarich 1.7.11 — see upstream [1.7.9](https://github.com/Freika/dawarich/releases/tag/1.7.9), [1.7.10](https://github.com/Freika/dawarich/releases/tag/1.7.10), and [1.7.11](https://github.com/Freika/dawarich/releases/tag/1.7.11) release notes
- New Map v2 features: H3 **Hexagons** heatmap layer, area-selection bulk delete (incl. anomalies), area Edit button, GPX/GeoJSON trip downloads, hover tooltips on family member markers (1.7.9–1.7.11)
- Real-time Photon place suggestions: one Place per visit (was up to 25 candidates); `POST /api/v1/visits/:id/select_place` to swap; `place_visits` table will be removed in a follow-up release (1.7.9)
- New **Minimum visit duration** setting (default 5 min, replaces hardcoded 3 min); visit detection now ignores drive-bys and respects your enabled transportation modes; smart density fill fixed (1.7.10)
- Many fixes: overlapping tracks reconciled, late-arriving points reabsorbed, real-time family location updates, duplicate-import skip surfaced, Stats/Insights no longer 500 without `JWT_SECRET_KEY`, area geometry validation, two unused `points` indexes dropped on upgrade (frees several GB on large installs), 9 CVE-fix gem bumps (1.7.9–1.7.11)
- Addon: on first boot after upgrade, runs the upstream-recommended `dawarich:backfill_place_names` and `dawarich:cleanup_suggested_places` rake tasks once (gated by a marker file in `/data`) so existing installs get the new Place data populated
- New optional upstream env `OIDC_PKCE_ENABLED` is not exposed in the addon (off by default); request it if you need PKCE for an OIDC provider

## 1.7.8-2

- Show the Dawarich sidebar panel for non-admin Home Assistant users (`panel_admin: false`). Dawarich's own login still applies, so non-admin HA users will need their own Dawarich credentials.

## 1.7.8-1

- Upgrade base image to Dawarich 1.7.8 — see upstream [1.7.8](https://github.com/Freika/dawarich/releases/tag/1.7.8) release notes
- Fix multi-user creation failing with "Password is too short" — default password for auto-created users (and the `admin_password` config default) is now `changemeplease` (14 chars), meeting Dawarich's 12-char minimum

## 1.7.7-1

- Upgrade base image to Dawarich 1.7.7 — see upstream [1.7.2](https://github.com/Freika/dawarich/releases/tag/1.7.2), [1.7.3](https://github.com/Freika/dawarich/releases/tag/1.7.3), [1.7.4](https://github.com/Freika/dawarich/releases/tag/1.7.4), [1.7.5](https://github.com/Freika/dawarich/releases/tag/1.7.5), [1.7.6](https://github.com/Freika/dawarich/releases/tag/1.7.6), and [1.7.7](https://github.com/Freika/dawarich/releases/tag/1.7.7) release notes
- Security audit fixes: path-traversal in archive import, OAuth account-link consent, SSRF blocklist for Immich/PhotoPrism URLs, 2FA brute-force rate limit, stored XSS sanitization, 12-char minimum password length, 256-bit API keys (1.7.3)
- Map v2: delete-from-card, manual transportation-mode correction, bulk visit confirm/decline, trip recalculate button, heatmap visible at city zoom, mobile safe-area fit (1.7.2, 1.7.5, 1.7.6)
- Polarsteps and Google "Timeline Edits.json" Takeout imports; clearer errors on unsupported uploads (1.7.3, 1.7.6)
- Visit suggestions now triggered by live tracking (Dawarich iOS app, OwnTracks, Overland, Traccar), not just imports (1.7.5)
- Many timezone, track-merge, stats, and reverse-geocoding fixes; duplicate-tracks prevention (1.7.5–1.7.7)
- No env-variable changes required for this addon — Prometheus migration to Yabeda (1.7.7) only affects setups with `PROMETHEUS_EXPORTER_ENABLED=true`; `JWT_SECRET_KEY` no longer required (1.7.4)

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
