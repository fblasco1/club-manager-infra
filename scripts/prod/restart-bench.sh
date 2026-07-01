#!/usr/bin/env bash
# Reinicio de servicios Frappe en producción (Hetzner / compose icdpe).
#
# Uso en el servidor:
#   ./scripts/prod/restart-bench.sh
#
# Desde tu máquina (con clave SSH en HETZNER_SSH_KEY):
#   HETZNER_SSH_KEY=~/.ssh/id_ed25519 ./scripts/prod/restart-bench.sh remote

set -euo pipefail

PROD_HOST="${PROD_HOST:-root@157.90.164.162}"
PROD_SITE="${PROD_SITE:-gestion.icdpedroechague.com.ar}"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-club_manager_infra}"
COMPOSE_DIR="${COMPOSE_DIR:-/root/club_manager_infra}"
COMPOSE_FILES="compose.yaml -f overrides/compose.postgres.yaml -f overrides/compose.redis.yaml -f overrides/compose.https.yaml"

run_on_server() {
	local ssh_key="${HETZNER_SSH_KEY:-/tmp/hetzner_key}"
	local ssh_opts=(-o StrictHostKeyChecking=no)
	if [[ -f "$ssh_key" ]]; then
		ssh_opts+=(-i "$ssh_key")
	fi
	ssh "${ssh_opts[@]}" "$PROD_HOST" bash -s <<REMOTE
set -euo pipefail
cd "$COMPOSE_DIR"
DC="docker compose -p $COMPOSE_PROJECT -f $COMPOSE_FILES"
# IMPORTANTE: cada 'docker compose exec' lleva '</dev/null' para que NO consuma
# el stdin del heredoc (si no, se "come" las líneas siguientes del script).
echo "==> bench restart (backend)"
# bench restart devuelve no-cero en este setup; el reinicio real es 'docker compose restart'.
\$DC exec -T backend bench restart </dev/null || true
echo "==> restart workers"
\$DC restart backend queue-short queue-long scheduler websocket </dev/null
echo "==> clear-cache"
\$DC exec -T backend bench --site '$PROD_SITE' clear-cache </dev/null
# 'bench build' como exec directo (sin 'bash -lc': el login shell pierde node del PATH).
echo "==> build club_management"
\$DC exec -T backend bench build --app club_management </dev/null
echo "OK reinicio producción ($PROD_SITE)"
REMOTE
}

run_local_compose() {
	dc() {
		docker compose -p "$COMPOSE_PROJECT" -f $COMPOSE_FILES "$@"
	}
	echo "==> bench restart (backend)"
	dc exec -T backend bench restart </dev/null || true
	echo "==> restart workers"
	dc restart backend queue-short queue-long scheduler websocket </dev/null
	echo "==> clear-cache"
	dc exec -T backend bench --site "$PROD_SITE" clear-cache </dev/null
	echo "==> build club_management"
	dc exec -T backend bench build --app club_management </dev/null
	echo "OK reinicio producción ($PROD_SITE)"
}

case "${1:-local}" in
remote) run_on_server ;;
local) run_local_compose ;;
*) echo "Uso: $0 [local|remote]" >&2; exit 1 ;;
esac
