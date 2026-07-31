#!/usr/bin/with-contenv bashio

export PATH="/usr/lib/postgresql/17/bin:${PATH}"

# --- Create persistent data directories (HA mounts /data fresh) ---
mkdir -p /data/postgres /data/redis /data/dawarich/storage /data/dawarich/public
mkdir -p /var/app/tmp/imports/watched
mkdir -p /run/postgresql && chown postgres:postgres /run/postgresql

# --- Hardcoded infrastructure env vars ---
for kv in \
  "DATABASE_HOST=localhost" \
  "DATABASE_PORT=5432" \
  "DATABASE_USERNAME=dawarich" \
  "DATABASE_NAME=dawarich_production" \
  "REDIS_URL=redis://localhost:6379/0" \
  "RAILS_ENV=production" \
  "SELF_HOSTED=true" \
  "STORE_GEODATA=true" \
  "APPLICATION_PROTOCOL=http" \
  "RAILS_LOG_TO_STDOUT=true"; do
  key="${kv%%=*}"
  val="${kv#*=}"
  printf '%s' "$val" > "/var/run/s6/container_environment/${key}"
done

# --- User-configurable env vars ---
printf '%s' "$(bashio::config 'database_password')" > /var/run/s6/container_environment/DATABASE_PASSWORD
printf '%s' "$(bashio::config 'time_zone')" > /var/run/s6/container_environment/TIME_ZONE
printf '%s' "$(bashio::config 'application_hosts')" > /var/run/s6/container_environment/APPLICATION_HOSTS
printf '%s' "$(bashio::config 'background_processing_concurrency')" > /var/run/s6/container_environment/BACKGROUND_PROCESSING_CONCURRENCY

# DOMAIN is what Dawarich uses to build absolute URLs in mails (Devise unlock and
# password-reset instructions). Unset, rendering those mails raises "Missing host
# to link to!" and the request 500s — which is what a locked-out account hits on
# its next login attempt, instead of being told the account is locked.
PRIMARY_HOST="$(bashio::config 'application_hosts' | cut -d',' -f1 | xargs)"
[ -z "$PRIMARY_HOST" ] && PRIMARY_HOST="homeassistant.local"
printf '%s' "$PRIMARY_HOST" > /var/run/s6/container_environment/DOMAIN

# Admin user credentials
printf '%s' "$(bashio::config 'admin_email')" > /var/run/s6/container_environment/ADMIN_EMAIL
printf '%s' "$(bashio::config 'admin_password')" > /var/run/s6/container_environment/ADMIN_PASSWORD

# Dawarich rejects passwords shorter than 12 characters. Creating the admin user
# would fail with "Password is too short" and leave the app with no account to
# log in with, so warn about it here rather than at the point of failure.
ADMIN_PW="$(bashio::config 'admin_password')"
if [ -n "$ADMIN_PW" ] && [ ${#ADMIN_PW} -lt 12 ]; then
  bashio::log.warning "admin_password is only ${#ADMIN_PW} characters — Dawarich requires at least 12."
  bashio::log.warning "The admin user cannot be created until you set a longer password in the app configuration."
fi

# HA location tracker settings
printf '%s' "$(bashio::config 'ha_tracked_entities')" > /var/run/s6/container_environment/HA_TRACKED_ENTITIES
printf '%s' "$(bashio::config 'ha_min_distance')" > /var/run/s6/container_environment/HA_MIN_DISTANCE

# Reverse geocoding
if bashio::config.true 'reverse_geocoding'; then
  GEOAPIFY_KEY="$(bashio::config 'geoapify_api_key')"
  if [ -n "$GEOAPIFY_KEY" ]; then
    printf '%s' "$GEOAPIFY_KEY" > /var/run/s6/container_environment/GEOAPIFY_API_KEY
    bashio::log.info "Reverse geocoding: enabled (Geoapify)"
    # Verify Geoapify API key works
    GEOAPIFY_TEST_URL="https://api.geoapify.com/v1/geocode/reverse?lat=48.8584&lon=2.2945&apiKey=${GEOAPIFY_KEY}"
    # Force IPv4 to mirror the path Ruby's geocoder takes (see /etc/gai.conf).
    # A plain curl uses Happy Eyeballs and can succeed over IPv4 even when IPv6
    # egress is dead, masking the failure the real geocoding jobs would hit.
    GEOAPIFY_RESPONSE=$(curl -4 -sf "${GEOAPIFY_TEST_URL}" 2>&1) || true
    GEOAPIFY_CITY=$(echo "$GEOAPIFY_RESPONSE" | jq -r '.features[0].properties.city // empty' 2>/dev/null)
    if [ -n "$GEOAPIFY_CITY" ]; then
      bashio::log.info "Reverse geocoding: API reachable (test: ${GEOAPIFY_CITY})"
    else
      GEOAPIFY_HTTP_CODE=$(curl -4 -s -o /dev/null -w "%{http_code}" "${GEOAPIFY_TEST_URL}" 2>/dev/null)
      bashio::log.warning "Reverse geocoding: Geoapify API test failed (HTTP ${GEOAPIFY_HTTP_CODE})"
      bashio::log.debug "Reverse geocoding: response: ${GEOAPIFY_RESPONSE}"
    fi
  else
    PHOTON_URL="$(bashio::config 'photon_api_host')"
    PHOTON_KEY="$(bashio::config 'photon_api_key')"
    # Strip protocol — Dawarich expects just the hostname and uses PHOTON_API_USE_HTTPS separately
    PHOTON_HOST="${PHOTON_URL#https://}"
    PHOTON_HOST="${PHOTON_HOST#http://}"
    printf '%s' "$PHOTON_HOST" > /var/run/s6/container_environment/PHOTON_API_HOST
    if [[ "$PHOTON_URL" == https://* ]]; then
      printf '%s' "true" > /var/run/s6/container_environment/PHOTON_API_USE_HTTPS
    else
      printf '%s' "false" > /var/run/s6/container_environment/PHOTON_API_USE_HTTPS
    fi
    if [ -n "$PHOTON_KEY" ]; then
      printf '%s' "$PHOTON_KEY" > /var/run/s6/container_environment/PHOTON_API_KEY
      bashio::log.info "Reverse geocoding: enabled (Photon: ${PHOTON_HOST}, API key set)"
    else
      bashio::log.info "Reverse geocoding: enabled (Photon: ${PHOTON_HOST})"
      # Verify Photon reverse geocoding is reachable (skip when API key is set — can't test auth)
      PHOTON_TEST_URL="${PHOTON_URL}/reverse?lat=48.8584&lon=2.2945"
      bashio::log.debug "Reverse geocoding: testing API at ${PHOTON_TEST_URL}"
      PHOTON_RESPONSE=$(curl -sf "${PHOTON_TEST_URL}" 2>&1) || true
      PHOTON_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${PHOTON_TEST_URL}" 2>/dev/null)
      PHOTON_CITY=$(echo "$PHOTON_RESPONSE" | jq -r '.features[0].properties.city // empty' 2>/dev/null)
      if [ -n "$PHOTON_CITY" ]; then
        bashio::log.info "Reverse geocoding: API reachable (test: ${PHOTON_CITY})"
      else
        bashio::log.warning "Reverse geocoding: API test failed (HTTP ${PHOTON_HTTP_CODE})"
        bashio::log.debug "Reverse geocoding: response: ${PHOTON_RESPONSE}"
      fi
    fi
  fi
else
  bashio::log.info "Reverse geocoding: disabled"
fi

# --- SECRET_KEY_BASE: auto-generate on first run, persist to /data ---
if [ -f /data/dawarich/secret_key_base ]; then
  cat /data/dawarich/secret_key_base > /var/run/s6/container_environment/SECRET_KEY_BASE
else
  openssl rand -hex 64 | tee /data/dawarich/secret_key_base > /var/run/s6/container_environment/SECRET_KEY_BASE
fi

# --- PostgreSQL init on first run ---
# A missing cluster means either a first install or a restored backup (HA backups
# exclude postgres/**). svc-dawarich needs to tell those apart to decide whether
# it may import a SQL dump, so record it here.
printf '%s' "false" > /var/run/s6/container_environment/PG_FRESH_INIT
if [ ! -f /data/postgres/PG_VERSION ]; then
  bashio::log.info "Initializing PostgreSQL database..."
  printf '%s' "true" > /var/run/s6/container_environment/PG_FRESH_INIT
  chown -R postgres:postgres /data/postgres
  su - postgres -c "PATH=/usr/lib/postgresql/17/bin:\$PATH initdb -D /data/postgres"
  # Trust auth: safe because PG binds to localhost only, port 5432 not exposed
  cat > /data/postgres/pg_hba.conf <<'PGEOF'
# Trust is safe here: PostgreSQL is only accessible via localhost within
# this container. Port 5432 is NOT exposed to the host or other containers.
local   all   all                 trust
host    all   all   127.0.0.1/32  trust
host    all   all   ::1/128       trust
PGEOF
fi

# Ensure ownership is correct on restarts
chown -R postgres:postgres /data/postgres
chown -R postgres:postgres /run/postgresql

# --- Generate nginx ingress proxy config ---
# Fetch the ingress entry path from Supervisor API (e.g. /api/hassio_ingress/<token>)
INGRESS_ENTRY=$(curl -s -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
  http://supervisor/addons/self/info 2>/dev/null | jq -r '.data.ingress_entry // empty')

if [ -n "$INGRESS_ENTRY" ]; then
  # Remove trailing slash
  INGRESS_ENTRY="${INGRESS_ENTRY%/}"
  bashio::log.info "Ingress path: ${INGRESS_ENTRY}"
  sed "s|INGRESS_PATH|${INGRESS_ENTRY}|g" \
    /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
else
  bashio::log.warning "Could not determine ingress path, using passthrough"
  sed "s|INGRESS_PATH||g" \
    /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
fi
