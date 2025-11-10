#!/bin/bash
set -e

echo "🔹 Carregando .env"
export $(grep -v '^#' .env | xargs)

echo "🔹 Subindo Postgres, Redis e MinIO"
docker-compose up -d postgres redis minio

echo "🔹 Aguardando Postgres..."
until docker-compose exec -T postgres pg_isready -U "$POSTGRES_USER" >/dev/null 2>&1; do
  sleep 3
done
echo "✅ Postgres online"

echo "🔹 Aguardando Redis..."
until docker-compose exec -T redis redis-cli -a "$REDIS_PASSWORD" ping >/dev/null 2>&1; do
  sleep 2
done
echo "✅ Redis online"

echo "🔹 Aguardando MinIO..."
sleep 10
echo "✅ MinIO online"

echo "🔹 Rodando migrations do Chatwoot..."
docker-compose run --rm chatwoot bundle exec rails db:migrate

echo "🔹 Seed opcional do Chatwoot..."
docker-compose run --rm chatwoot bundle exec rake chatwoot:install

echo "✅ Migrations finalizadas"

echo "🔹 Subindo o restante dos serviços..."
docker-compose up -d evolution chatwoot chatwoot-worker n8n proxy minio-init

echo "✅ Sistema pronto!"
echo "🌐 Chatwoot → https://chat.localhost"
echo "🌐 n8n → http://n8n.localhost"
echo "🌐 MinIO → http://minio.localhost:9000"
