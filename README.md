# n8n-waha-local

Stack Docker Compose para lab/local que integra:

- evolution (adaptador WhatsApp) - imagem `atendai/evolution-api`
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
- `EVOLUTION_API_KEY` — chave API do evolution (se aplicável).
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
      - Observação: o `evolution` também está temporariamente configurado com `atendai/evolution-api:v2.2.3` para evitar erro de manifest. Substitua por uma tag fixa testada quando estiver pronto para produção.
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

## Arquitetura

Abaixo há um diagrama ASCII simplificado da arquitetura do ambiente e uma descrição dos fluxos principais, variáveis importantes e checks rápidos (smoke tests).

Diagrama ASCII da arquitetura

    												 Internet / WhatsApp
    																 │
    																 ▼
    													 (DNS -> domain)
    																 │
    												 ┌─────────────────┐
    												 │ Nginx Proxy     │
    												 │ Manager (proxy) │
    												 │ 80/443 + 127.0.0.1:81 (admin) │
    												 └─────────────────┘
    														│      │       │
    						https://n8n.DOMAIN│      │https://chat.DOMAIN
    														▼      ▼       ▼
    										┌──────────┐  ┌──────────┐
    										│   n8n    │  │ Chatwoot │
    										│(5678)   │  │ (3000)   │
    										└──────────┘  └──────────┘
    												 ▲             ▲
    												 │             │
    							WEBHOOKS   │             │ FRONTEND
    												 │             │
    											 ┌────────────────────────┐
    											 │  evolution (WhatsApp)  │
    											 │  sessions/media volumes│
    											 └────────────────────────┘
    												 ▲             ▲
    												 │             │
    					┌──────────────┴──────────────┴──────────────┐
    					│                 internal_net               │
    					│                                            │
    					│   ┌────────┐     ┌──────────┐    ┌────────┐│
    					│   │Redis   │     │Postgres  │    │Volumes ││
    					│   │6379    │     │5432      │    │(pg,n8n,││
    					│   └────────┘     └──────────┘    │ evo...)││
    					└────────────────────────────────────────────┘

Legenda / observações:

- Todos os serviços residem na rede interna `internal_net` (driver: bridge).
- O `proxy` (Nginx Proxy Manager) é o ponto de entrada público, termina TLS e faz reverse proxy para:
  - n8n (ex.: n8n.DOMAIN)
  - Chatwoot frontend (chat.DOMAIN)
  - evolution exposto via rota (ex: proxy configura /evolution → evolution:3000)
- n8n usa Postgres para persistência e Redis para fila (QUEUE_MODE=redis).
- Chatwoot usa o mesmo Postgres + Redis (obs: o README recomenda DB separado opcionalmente).
- Evolution mantém `sessions` e `media` em volumes persistentes; pode enviar webhooks para n8n (WHATSAPP_HOOK_URL apontando para n8n).
- chatwoot-worker executa Sidekiq (fila) e comunica-se com Redis/Postgres.

Fluxos principais (passo a passo)

1. Recebimento de mensagens WhatsApp

   - Usuário envia mensagem para número gerenciado pelo Waha.
   - Evolution processa a sessão e, conforme configurado, envia webhook para n8n em:
     - WHATSAPP_HOOK_URL = https://n8n.${DOMAIN}/webhook/webhook
   - Proxy roteia a requisição HTTPS para o container `n8n`.

2. Processamento em n8n

   - n8n recebe o webhook e executa um workflow definido pelo usuário.
   - Workflow pode:
     - Enviar/receber dados no Chatwoot via API (ex.: criar conversa, enviar mensagem).
     - Persistir dados no Postgres (ex.: logs, histórico).
     - Acionar jobs filados no Redis (n8n usa fila Bull com Redis).

3. Interação com Chatwoot

   - Chatwoot pode receber mensagens enviadas por n8n ou integrar-se ao fluxo via API.
   - Chatwoot usa Redis para filas/background e Postgres para dados persistentes.
   - chatwoot-worker processa jobs (sidekiq), conectado ao Redis/Postgres.

4. Persistência e sessão
   - Postgres (volume `pgdata`) guarda dados de aplicações (n8n, Chatwoot).
   - Redis (volume `redis_data`) mantém filas e cache; protegido por senha `${REDIS_PASSWORD}`.
   - Waha armazena sessões em `evolution_sessions` e mídias em `evolution_media`.

Pontos de atenção / variáveis importantes

- `.env` deve conter:
  - POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB
  - REDIS_PASSWORD
  - DOMAIN (ex: meudominio.com)
  - N8N_BASIC_AUTH_USER, N8N_BASIC_AUTH_PASSWORD
  - EVOLUTION_API_KEY, CHATWOOT_SECRET
- Imagens estão com `:latest` em alguns serviços — para produção, pin por tag.
- Proxy painel admin mapeado apenas para `127.0.0.1:81` (recomendado por segurança).
- Recomenda-se usar Docker secrets em ambiente de produção.

Verificações rápidas (smoke tests)

- Verificar containers estão up:
  - docker compose ps
- Logs:
  - docker compose logs -f n8n
  - docker compose logs -f proxy
- Testar healthchecks:
  - n8n: abrir https://n8n.${DOMAIN}/ (autenticação básica ativa)
  - Chatwoot: abrir https://chat.${DOMAIN}/
  - Proxy admin: http://127.0.0.1:81

Exemplos de checks locais (copie/cole no PowerShell):

```powershell
# Mostrar containers
docker compose ps

# Ver logs do n8n
docker compose logs -f n8n

# Testar que proxy responde no painel admin
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:81 | Select-Object StatusCode
```

Arquivos/volumes importantes para backup

- Volumes:
  - `pgdata` — Postgres DB
  - `n8n_data` — dados do n8n
  - `evolution_sessions`, `evolution_media` — sessões e mídias do Waha
  - `chatwoot_data` — storage de chatwoot
  - `proxy_letsencrypt` — certificados Let's Encrypt gerados pelo proxy

Próximo passo sugerido

- Posso aplicar o diagrama no `README.md` ou gerar um diagrama mermaid/imagem e adicioná-lo ao repositório.
- Também posso criar um script `make-secrets.ps1` para criar Docker secrets localmente e atualizar o `docker-compose.yml` para usá-los.
- Diga qual dessas opções prefere.
