#!/bin/bash
# /opt/backups/backup_pg.sh
set -e
DATE=$(date +%F_%H%M)
OUTDIR=/opt/backups/postgres
mkdir -p "$OUTDIR"
docker exec -t $(docker compose ps -q postgres) pg_dump -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -F c -f /tmp/db_${DATE}.dump
docker cp $(docker compose ps -q postgres):/tmp/db_${DATE}.dump "${OUTDIR}/db_${DATE}.dump"
docker exec -t $(docker compose ps -q postgres) rm -f /tmp/db_${DATE}.dump
# (opcional) espelhar para MinIO com mc, rclone ou aws-cli
echo "Backup Postgres escrito em ${OUTDIR}/db_${DATE}.dump"
