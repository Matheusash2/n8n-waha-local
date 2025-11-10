#!/bin/bash
set -e

echo "🔄 Atualizando imagens..."
docker compose pull

echo "🧹 Limpando imagens antigas..."
docker system prune -f

echo "🔹 Subindo serviços core..."
docker compose up -d postgres redis minio

echo "⏳ Aguardando Postgres..."
until docker compose exec -T postgres pg_isready -U "$POSTGRES_USER" >/dev/null 2>&1; do
  sleep 3
done

echo "🟦 Rodando migrations Chatwoot..."
docker compose run --rm chatwoot bundle exec rails db:migrate

echo "🟧 Migrações Evolution (se aplicável)..."
# docker compose run --rm evolution npm run prisma:migrate:deploy

echo "🚀 Subindo todo o ambiente..."
docker compose up -d

echo "✅ Atualização concluída!"
