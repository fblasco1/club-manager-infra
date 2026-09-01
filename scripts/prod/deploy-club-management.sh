#!/usr/bin/env bash
# Despliega club_management en producción Hetzner (código + build + frontend).
#
# Requisitos:
#   - git push previo a upstream/mvp/secretaria-2026-06 (o APP_BRANCH)
#   - ./scripts/prod/prepare-ssh-key.sh (o HETZNER_SSH_KEY apuntando a clave válida)
#
# Uso:
#   ./scripts/prod/deploy-club-management.sh
#   APP_BRANCH=mvp/secretaria-2026-06 SKIP_MIGRATE=1 ./scripts/prod/deploy-club-management.sh

set -euo pipefail

PROD_HOST="${PROD_HOST:-root@157.90.164.162}"
PROD_SITE="${PROD_SITE:-gestion.icdpedroechague.com.ar}"
COMPOSE_DIR="${COMPOSE_DIR:-/root/club_manager_infra}"
APP_BRANCH="${APP_BRANCH:-mvp/secretaria-2026-06}"
DOCKER_IMAGE="${DOCKER_IMAGE:-icdpe-frappe:v16-mvp}"
SSH_KEY="${HETZNER_SSH_KEY:-/tmp/hetzner_key}"
SKIP_MIGRATE="${SKIP_MIGRATE:-0}"

ssh_opts=(-o StrictHostKeyChecking=no)
if [[ -f "$SSH_KEY" ]]; then
	ssh_opts+=(-i "$SSH_KEY")
else
	echo "Aviso: no existe $SSH_KEY — probando SSH con agente/config por defecto." >&2
fi

echo "==> Deploy club_management → $PROD_HOST (rama $APP_BRANCH)"

ssh "${ssh_opts[@]}" "$PROD_HOST" bash -s <<REMOTE
set -euo pipefail
cd "$COMPOSE_DIR"
DC="docker compose -f compose.yaml -f overrides/compose.postgres.yaml -f overrides/compose.redis.yaml -f overrides/compose.https.yaml"
# IMPORTANTE: cada 'docker compose exec' lleva '</dev/null' para que NO consuma
# el stdin del heredoc (si no, se "come" las líneas siguientes del script y el
# deploy corta tras el primer comando). Las excepciones son los exec que SÍ leen
# de un archivo (sync de assets), que mantienen su propio '< archivo'.

echo "==> Actualizar app en backend"
$DC exec -T backend git -C /home/frappe/frappe-bench/apps/club_management fetch upstream "$APP_BRANCH"
$DC exec -T backend git -C /home/frappe/frappe-bench/apps/club_management reset --hard "upstream/$APP_BRANCH"
$DC exec -T backend git -C /home/frappe/frappe-bench/apps/club_management log -1 --oneline

if [[ "$SKIP_MIGRATE" != "1" ]]; then
	echo "==> bench migrate"
	\$DC exec -T backend bench --site '$PROD_SITE' migrate --skip-failing </dev/null
fi

echo "==> bench build club_management"
\$DC exec -T backend bench build --app club_management </dev/null

echo "==> clear-cache"
\$DC exec -T backend bench --site '$PROD_SITE' clear-cache </dev/null || true

echo "==> Restart backend + workers (recarga código Python)"
# bench restart devuelve no-cero en este setup; el reinicio real es el docker compose restart.
\$DC exec -T backend bench restart </dev/null || true
\$DC restart backend queue-short queue-long scheduler </dev/null

echo "==> docker commit → $DOCKER_IMAGE"
docker commit "\$(docker ps -qf name=backend)" "$DOCKER_IMAGE"

echo "==> Recrear frontend + websocket"
\$DC up -d --force-recreate --no-deps frontend websocket </dev/null

echo "==> Sync assets.json backend → frontend"
\$DC exec -T backend cat /home/frappe/frappe-bench/sites/assets/assets.json </dev/null > /tmp/assets.json
\$DC exec -T backend cat /home/frappe/frappe-bench/sites/assets/assets-rtl.json </dev/null > /tmp/assets-rtl.json
\$DC exec -T frontend bash -lc 'cat > /home/frappe/frappe-bench/sites/assets/assets.json' < /tmp/assets.json
\$DC exec -T frontend bash -lc 'cat > /home/frappe/frappe-bench/sites/assets/assets-rtl.json' < /tmp/assets-rtl.json

echo "==> Assets en backend:"
\$DC exec -T backend grep club_management /home/frappe/frappe-bench/sites/assets/assets.json </dev/null || true
echo "OK deploy"
REMOTE

echo "==> Verificación HTTP assets.json"
curl -sf "https://gestion.icdpedroechague.com.ar/assets/assets.json" | grep -o 'club_management.bundle[^"]*' | head -4 || true
echo "Listo. Hard refresh en https://gestion.icdpedroechague.com.ar/desk/secretaría"
