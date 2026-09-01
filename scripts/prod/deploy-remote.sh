#!/usr/bin/env bash
# Deploy remoto — invocado en Hetzner vía ssh.exe desde WSL.
set -euo pipefail
COMPOSE_DIR="${COMPOSE_DIR:-/root/club_manager_infra}"
PROD_SITE="${PROD_SITE:-gestion.icdpedroechague.com.ar}"
APP_BRANCH="${APP_BRANCH:-mvp/secretaria-2026-06}"
DOCKER_IMAGE="${DOCKER_IMAGE:-icdpe-frappe:v16-mvp}"
SKIP_MIGRATE="${SKIP_MIGRATE:-0}"

cd "$COMPOSE_DIR"
DC="docker compose -f compose.yaml -f overrides/compose.postgres.yaml -f overrides/compose.redis.yaml -f overrides/compose.https.yaml"

echo "==> Actualizar app en backend"
$DC exec -T backend git -C /home/frappe/frappe-bench/apps/club_management fetch upstream "$APP_BRANCH"
$DC exec -T backend git -C /home/frappe/frappe-bench/apps/club_management reset --hard "upstream/$APP_BRANCH"
$DC exec -T backend git -C /home/frappe/frappe-bench/apps/club_management log -1 --oneline

if [[ "$SKIP_MIGRATE" != "1" ]]; then
	echo "==> bench migrate"
	$DC exec -T backend bench --site "$PROD_SITE" migrate --skip-failing </dev/null
fi

echo "==> bench build club_management"
$DC exec -T backend bench build --app club_management </dev/null

echo "==> clear-cache"
$DC exec -T backend bench --site "$PROD_SITE" clear-cache </dev/null || true

echo "==> Restart backend + workers"
$DC exec -T backend bench restart </dev/null || true
$DC restart backend queue-short queue-long scheduler </dev/null

echo "==> docker commit → $DOCKER_IMAGE"
docker commit "$(docker ps -qf name=backend)" "$DOCKER_IMAGE"

echo "==> Recrear frontend + websocket"
$DC up -d --force-recreate --no-deps frontend websocket </dev/null

echo "==> Sync assets.json"
$DC exec -T backend cat /home/frappe/frappe-bench/sites/assets/assets.json </dev/null > /tmp/assets.json
$DC exec -T backend cat /home/frappe/frappe-bench/sites/assets/assets-rtl.json </dev/null > /tmp/assets-rtl.json
$DC exec -T frontend bash -lc 'cat > /home/frappe/frappe-bench/sites/assets/assets.json' < /tmp/assets.json
$DC exec -T frontend bash -lc 'cat > /home/frappe/frappe-bench/sites/assets/assets-rtl.json' < /tmp/assets-rtl.json

$DC exec -T backend grep club_management /home/frappe/frappe-bench/sites/assets/assets.json </dev/null || true
echo "OK deploy"
