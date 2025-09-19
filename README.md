# n8n-waha-local

Stack Docker Compose para lab/local que integra:

- Waha (adaptador WhatsApp) - imagem `devlikeapro/waha`
- n8n (automação) - imagem `n8nio/n8n`
- Chatwoot (suporte/omnichannel) - imagem `chatwoot/chatwoot`
- Redis - `redis:7.2-alpine`
- Postgres - `postgres:15`
- Nginx Proxy Manager (NPM) - `jc21/nginx-proxy-manager` para SSL e gerenciamento de hosts

Este repositório contém um `docker-compose.yml` para orquestrar os serviços acima. O objetivo é fornecer um ambiente local ou de laboratório para integrar WhatsApp → n8n → Chatwoot, com um proxy para gerenciar domínios e certificados.

## Conteúdo

- `docker-compose.yml` — definição dos serviços, volumes e rede.
- `.env` — variáveis de ambiente utilizadas pelo `docker-compose` (não comitar segredos reais).

## Requisitos

- Docker e Docker Compose (v2) instalados.
- Acesso a DNS/hosts para o domínio configurado em `DOMAIN` se você quiser testar HTTPS com Let's Encrypt (ou usar um domínio local e certificados provisórios).

## Variáveis importantes (defina em `.env`)

- `POSTGRES_USER` — usuário do banco Postgres utilizado pelo n8n (ex: `n8n_user`).
- `POSTGRES_PASSWORD` — senha do Postgres.
- `POSTGRES_DB` — nome do banco usado pelo n8n.

(Opcional, se quiser usar DB separado para Chatwoot)

- `POSTGRES_CHATWOOT_DB`
- `POSTGRES_CHATWOOT_USER`
- `POSTGRES_CHATWOOT_PASSWORD`

- `REDIS_PASSWORD` — senha do Redis (usado pelo redis e pelas apps que se conectam a ele).
- `WAHA_API_KEY` — chave API do Waha (se aplicável).
- `CHATWOOT_SECRET` — secret para o Chatwoot.
- `DOMAIN` — domínio base sem `https://` e sem `/` (ex: `meudominio.com`).

n8n specific

- `N8N_BASIC_AUTH_USER` — usuário Admin para o UI do n8n (autenticação básica).
- `N8N_BASIC_AUTH_PASSWORD` — senha para o admin do n8n.

## Como subir a stack (local)

1. Copie o exemplo de variáveis:

```fish
cp .env.example .env
# edite .env e preencha as variáveis obrigatórias
```

2. Preencha senhas e valores em `.env` (nunca comite segredos reais).

3. Inicie os serviços:

```fish
docker compose up -d
```

4. Verifique o status dos serviços:

```fish
docker compose ps
```

5. Logs úteis:

```fish
# Logs do n8n
docker compose logs -f n8n
# Logs do proxy
docker compose logs -f proxy
```

## Acessando serviços

- n8n: `https://n8n.<DOMAIN>` (autenticação básica se ativada)
	- Observação: a configuração do `docker-compose.yml` usa `n8nio/n8n:latest` por padrão temporariamente. Após validar uma versão estável, substitua por uma tag fixa (ex.: `n8nio/n8n:2.321.0`) para maior reprodutibilidade.
		- Observação: o `chatwoot` também está temporariamente configurado com `chatwoot/chatwoot:latest` para evitar erros de manifest. Substitua por uma tag fixa testada quando estiver pronto para produção.
			- Observação: o `waha` também está temporariamente configurado com `devlikeapro/waha:latest` para evitar erro de manifest. Substitua por uma tag fixa testada quando estiver pronto para produção.
- Chatwoot (frontend): `https://chat.<DOMAIN>`
- Nginx Proxy Manager (painel): `http://127.0.0.1:81` (mapeado apenas para localhost por segurança)
- Waha: normalmento acessível via proxy em `/waha` conforme configuração do proxy (veja `docker-compose.yml`).

## Notas de segurança e produção

- Use Docker secrets para senhas em ambientes de produção em vez de `.env`.
- Pin de imagens por tag (não use `:latest`) para reprodutibilidade.
- Faça backup regular dos volumes `pgdata` (Postgres) e `n8n_data` (dados do n8n) e de quaisquer mídias/sessions do Waha.
- Restrinja o acesso ao painel do Nginx Proxy Manager (mantenha-o apenas em localhost ou por VPN/SSH tunnel).

## Próximos passos recomendados

- Adicionar um `README` mais detalhado com exemplos de fluxos n8n.
- Script/Makefile para criar Docker secrets e iniciar a stack com validações.
- Instruções para migração de dados e backup/restore.

---

Se quiser, eu posso:

- Gerar um `Makefile` e scripts para criar secrets e subir a stack.
- Converter variáveis sensíveis para Docker secrets no `docker-compose.yml` (faço uma PR local).
- Adicionar um diagrama simples da arquitetura.

Diga qual desses itens quer que eu faça em seguida.
