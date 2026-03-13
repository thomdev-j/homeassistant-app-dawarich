#!/usr/bin/with-contenv bash
# Post-backup: clean up the SQL dump to save disk space.
rm -f /data/dawarich/backup.sql
echo "Backup cleanup completed."
