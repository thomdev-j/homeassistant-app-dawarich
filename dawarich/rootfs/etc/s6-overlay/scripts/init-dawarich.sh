#!/usr/bin/with-contenv bashio

export PATH="/usr/lib/postgresql/17/bin:${PATH}"

# --- Create persistent data directories (HA mounts /data fresh) ---
mkdir -p /data/postgres /data/redis /data/dawarich/storage /data/dawarich/public
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

# Optional vars
if bashio::config.has_value 'photon_api_host'; then
  printf '%s' "$(bashio::config 'photon_api_host')" > /var/run/s6/container_environment/PHOTON_API_HOST
fi
if bashio::config.has_value 'geoapify_api_key'; then
  printf '%s' "$(bashio::config 'geoapify_api_key')" > /var/run/s6/container_environment/GEOAPIFY_API_KEY
fi

# --- SECRET_KEY_BASE: auto-generate on first run, persist to /data ---
if [ -z "$(bashio::config 'secret_key_base')" ]; then
  if [ -f /data/dawarich/secret_key_base ]; then
    cat /data/dawarich/secret_key_base > /var/run/s6/container_environment/SECRET_KEY_BASE
  else
    openssl rand -hex 64 | tee /data/dawarich/secret_key_base > /var/run/s6/container_environment/SECRET_KEY_BASE
  fi
else
  printf '%s' "$(bashio::config 'secret_key_base')" > /var/run/s6/container_environment/SECRET_KEY_BASE
fi

# --- PostgreSQL init on first run ---
if [ ! -f /data/postgres/PG_VERSION ]; then
  bashio::log.info "Initializing PostgreSQL database..."
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
