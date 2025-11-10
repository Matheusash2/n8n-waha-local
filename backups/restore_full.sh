#!/bin/bash
set -euo pipefail

echo "⚠ RESTORE COMPLETO — ATENÇÃO!"
echo "Isso vai APAGAR todos os volumes atuais."
read -p "Digite YES para continuar: " confirm
[ "$confirm" = "YES" ] || exit 1


RESTORE_DIR="/opt/backups"
PG_FILE=$(ls -t $RESTORE_DIR/postgres/*.gz | head -1)

echo "🔄 Parando serviços..."
docker compose down -v

echo "🟦 Restaurando Postgres..."

gunzip -c "$PG_FILE" > /tmp/restore_pg.sql

docker compose up -d postgres

echo "⏳ Aguardando Postgres..."
until docker compose exec -T postgres pg_isready -U "$POSTGRES_USER" >/dev/null 2>&1; do
  sleep 3
done

cat /tmp/restore_pg.sql | docker compose exec -T postgres psql -U "$POSTGRES_USER"

echo "✅ Postgres restaurado!"


# Restore dos volumes
echo "🟩 Restaurando Volumes..."

VOLUMES="pgdata minio_data evolution_sessions evolution_media evolution_store evolution_instances chatwoot_data n8n_data"

for vol in $VOLUMES; do
  TARFILE=$(ls -t $RESTORE_DIR/volumes/${vol}_*.tar.gz | head -1)

  echo "📦 Restaurando $vol..."

  docker volume rm $vol || true
  docker volume create $vol

  docker run --rm \
    -v $vol:/data \
    -v $RESTORE_DIR/volumes:/backup \
    alpine sh -c "cd /data && tar xzf /backup/$(basename $TARFILE)"
done

echo "✅ Volumes restaurados"


# Restaurar MinIO
echo "🟧 Restaurando MinIO buckets..."

docker compose up -d minio

sleep 10

mc alias set myminio http://127.0.0.1:9000 "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" || true

for bucket in evolution-media chatwoot; do
  LATEST=$(ls -td $RESTORE_DIR/minio/${bucket}-* | head -1)
  mc mirror "$LATEST" "myminio/$bucket"
done

echo "✅ MinIO restaurado"

echo "🌐 Subindo stack..."
docker compose up -d

echo "🎉 RESTORE COMPLETO FINALIZADO!"
