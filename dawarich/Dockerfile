ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG S6_OVERLAY_VERSION="3.2.2.0"
ARG BASHIO_VERSION="0.16.2"
ARG BUILD_ARCH

# System packages: Redis, PG prerequisites
RUN apt-get update && apt-get install -y --no-install-recommends \
    xz-utils jq redis-server gnupg lsb-release nginx \
    && rm -rf /var/lib/apt/lists/*

# PostgreSQL 17 + PostGIS from PGDG
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
      gpg --dearmor -o /usr/share/keyrings/pgdg.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] \
      https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
      > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      postgresql-17 postgresql-17-postgis-3 \
    && rm -rf /var/lib/apt/lists/*

# s6-overlay v3
RUN S6_ARCH=$([ "${BUILD_ARCH}" = "amd64" ] && echo "x86_64" || echo "aarch64") \
    && curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" | tar Jxpf - -C / \
    && curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz" | tar Jxpf - -C / \
    && curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz" | tar Jxpf - -C / \
    && curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz" | tar Jxpf - -C /

# bashio (NO tempio — not needed, no template files)
RUN curl -fsSL "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" | tar xzf - \
    && mv "bashio-${BASHIO_VERSION}/lib" /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf "bashio-${BASHIO_VERSION}"

# Persistent data directories
RUN mkdir -p /data/postgres /data/redis /data/dawarich/storage /data/dawarich/public \
    && mkdir -p /run/postgresql && chown postgres:postgres /run/postgresql

# s6 service definitions
COPY rootfs /

ENTRYPOINT ["/init"]

ENV S6_SERVICES_GRACETIME=30000 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=120000
