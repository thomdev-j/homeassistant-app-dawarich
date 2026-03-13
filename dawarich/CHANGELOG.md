# Changelog

## 1.3.3-50

- Add multi-user device tracking: use `:Name` suffix in `ha_tracked_entities` to create separate Dawarich users per household member
- Add Family map support for shared location viewing between users
- Grant admin privileges to the configured admin user automatically
- Fix CSRF 422 errors on login/logout via ingress
- Fix ingress compatibility for forms, redirects, and WebSocket connections
- Add graceful Sidekiq shutdown to avoid interrupted background jobs
- Bail out on database migration failure instead of starting with broken state
- Remove `secret_key_base` from user-facing config (always auto-generated)
- Suppress Redis memory overcommit warning in logs
- Clean up stale API key files when entity config changes
- Default timezone changed to `Etc/UTC`
- Comprehensive README with quickstart guide, configuration reference, and FAQ

## 1.3.3-1

- Initial release
- Based on Dawarich v1.3.3
- Bundled PostgreSQL 17 + PostGIS, Redis 7.4
- s6-overlay process supervision
- Auto-generated SECRET_KEY_BASE persisted across restarts
- Home Assistant backup support with pg_dumpall
