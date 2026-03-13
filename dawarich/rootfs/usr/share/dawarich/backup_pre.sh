#!/usr/bin/with-contenv bash
# Pre-backup: dump PostgreSQL to a SQL file so the backup captures a consistent snapshot.
# Raw PG files are excluded via backup_exclude in config.yaml.

export PATH="/usr/lib/postgresql/17/bin:${PATH}"

if pg_isready -h localhost -p 5432 -q; then
  su - postgres -c "PATH=/usr/lib/postgresql/17/bin:\$PATH pg_dumpall" > /data/dawarich/backup.sql
  echo "PostgreSQL backup completed successfully."
else
  echo "WARNING: PostgreSQL is not running, skipping database dump."
fi
