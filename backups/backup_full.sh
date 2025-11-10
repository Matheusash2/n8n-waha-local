#!/bin/bash
set -euo pipefail

# ============================
# CONFIGURAÇÃO
# ============================
BACKUP_DIR="/opt/backups"
RETENTION_DAYS=7

DATE=$(date +%F_%H%M)
PG_CONTAINER=$(docker compose ps -q postgres)
MINIO_ALIAS="myminio"
MINIO_URL="http://127.0.0.1:9000"

mkdir -p "$BACKUP_DIR/postgres"
mkdir -p "$BACKUP_DIR/minio"
mkdir -p "$BACKUP_DIR/volumes"

echo "📦 Iniciando BACKUP COMPLETO - $DATE"


# ============================
# BACKUP POSTGRES (pg_dumpall)
# ============================
echo "🟦 Backup Postgres..."

docker exec -t "$PG_CONTAINER" pg_dumpall -U "$POSTGRES_USER" \
  > "$BACKUP_DIR/postgres/all_databases_${DATE}.sql"

gzip "$BACKUP_DIR/postgres/all_databases_${DATE}.sql"

echo "✅ PostgreSQL salvo em postgres/all_databases_${DATE}.sql.gz"


# ============================
# BACKUP MINIO (mc mirror)
# ============================
echo "🟧 Backup MinIO..."

mc alias set $MINIO_ALIAS $MINIO_URL "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" || true

mc mirror "$MINIO_ALIAS/evolution-media" "$BACKUP_DIR/minio/evolution-media-$DATE"
mc mirror "$MINIO_ALIAS/chatwoot" "$BACKUP_DIR/minio/chatwoot-$DATE"

echo "✅ MinIO buckets salvos"


# ============================
# BACKUP VOLUMES DOCKER
# ============================
echo "🟩 Backup dos volumes Docker..."

VOLUMES="pgdata minio_data evolution_sessions evolution_media evolution_store evolution_instances chatwoot_data n8n_data"

for vol in $VOLUMES; do
  docker run --rm \
    -v $vol:/data \
    -v $BACKUP_DIR/volumes:/backup \
    alpine sh -c "cd /data && tar czf /backup/${vol}_${DATE}.tar.gz ."
  echo "✅ Volume $vol salvo"
done


# ============================
# ROTAÇÃO DE BACKUP
# ============================
echo "♻ Limpando backups antigos..."

find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -delete

echo "✅ Rotação completa (arquivos > $RETENTION_DAYS dias removidos)"

echo "🎉 BACKUP FINALIZADO!"
