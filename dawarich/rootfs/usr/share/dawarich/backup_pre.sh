#!/usr/bin/with-contenv bash
# Pre-backup: dump PostgreSQL to a SQL file so the backup captures a consistent snapshot.
# Raw PG files are excluded via backup_exclude in config.yaml, so this dump is the
# only copy of the database inside the backup — svc-dawarich imports it again on
# the next start after a restore.

export PATH="/usr/lib/postgresql/17/bin:${PATH}"

DUMP=/data/dawarich/backup.sql

if pg_isready -h localhost -p 5432 -U postgres -q; then
  # Dump to a temporary file first: a partial dump left at the real path would be
  # picked up by the restore as if it were a complete one.
  if su - postgres -c "PATH=/usr/lib/postgresql/17/bin:\$PATH pg_dumpall" > "${DUMP}.tmp"; then
    mv "${DUMP}.tmp" "${DUMP}"
    echo "PostgreSQL backup completed successfully ($(du -h "${DUMP}" | cut -f1))."
  else
    rm -f "${DUMP}.tmp" "${DUMP}"
    echo "ERROR: pg_dumpall failed — this backup will NOT contain the database."
    exit 1
  fi
else
  echo "WARNING: PostgreSQL is not running, skipping database dump."
fi
