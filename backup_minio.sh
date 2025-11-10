#!/bin/bash
# /opt/backups/backup_minio.sh
set -e
DATE=$(date +%F_%H%M)
OUTDIR=/opt/backups/minio
mkdir -p "$OUTDIR"
# Assumindo mc instalado no host:
mc alias set myminio http://127.0.0.1:9000 ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY} || true
# espelhar bucket para diretório local
mc mirror myminio/evolution-media "${OUTDIR}/evolution-media-${DATE}"
mc mirror myminio/chatwoot "${OUTDIR}/chatwoot-${DATE}"
echo "MinIO buckets espelhados em ${OUTDIR}"
