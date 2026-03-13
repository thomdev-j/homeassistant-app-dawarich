# Changelog

## 1.3.3-45

- Add multi-user device tracking: use `:Name` suffix in `ha_tracked_entities` to create separate Dawarich users per household member
- Fix CSRF 422 errors on login/logout via ingress
- Fix ingress compatibility for forms, redirects, and WebSocket connections

## 1.3.3-1

- Initial release
- Based on Dawarich v1.3.3
- Bundled PostgreSQL 17 + PostGIS, Redis 7.4
- s6-overlay process supervision
- Auto-generated SECRET_KEY_BASE persisted across restarts
- Home Assistant backup support with pg_dumpall
