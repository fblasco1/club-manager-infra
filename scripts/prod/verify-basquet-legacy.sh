#!/usr/bin/env bash
# Verifica (y opcionalmente purga) básquet legacy en producción o local.
#
# Uso:
#   ./scripts/prod/verify-basquet-legacy.sh                  # solo verificar (dry_run)
#   ./scripts/prod/verify-basquet-legacy.sh --purge --apply  # verificar + purga en prod
#
# Variables: PROD_HOST, PROD_SITE, HETZNER_SSH_KEY (igual que deploy-club-management.sh)

set -euo pipefail

PURGE=0
DRY_RUN=1
LOCAL=0

for arg in "$@"; do
	case "$arg" in
		--purge) PURGE=1 ;;
		--apply) DRY_RUN=0 ;;
		--local) LOCAL=1 ;;
		--help|-h)
			echo "Uso: $0 [--purge] [--apply] [--local]"
			exit 0
			;;
	esac
done

if [[ "$PURGE" == "1" && "$DRY_RUN" == "0" ]]; then
	KWARGS='{"dry_run": False, "purge": True, "confirm": "PURGE_BASQUET_LEGACY"}'
elif [[ "$PURGE" == "1" ]]; then
	KWARGS='{"dry_run": True, "purge": True}'
else
	KWARGS='{"dry_run": True, "purge": False}'
fi

MODULE="club_management.activities.setup.verify_and_purge_basquet_legacy.run"

if [[ "$LOCAL" == "1" ]]; then
	SITE="${BENCH_SITE:-dev.localhost}"
	cd "$(dirname "$0")/../.."
	docker compose -p devcontainer -f .devcontainer/docker-compose.yml exec -T backend \
		bench --site "$SITE" execute "$MODULE" --kwargs "$KWARGS"
	exit 0
fi

PROD_HOST="${PROD_HOST:-root@157.90.164.162}"
PROD_SITE="${PROD_SITE:-gestion.icdpedroechague.com.ar}"
SSH_KEY="${HETZNER_SSH_KEY:-/tmp/hetzner_key}"
COMPOSE_DIR="${COMPOSE_DIR:-/root/club_manager_infra}"

ssh_opts=(-o StrictHostKeyChecking=no)
[[ -f "$SSH_KEY" ]] && ssh_opts+=(-i "$SSH_KEY")

ssh "${ssh_opts[@]}" "$PROD_HOST" \
	"docker compose -f ${COMPOSE_DIR}/compose.yaml -f ${COMPOSE_DIR}/overrides/compose.postgres.yaml exec -T backend \
	bench --site ${PROD_SITE} execute ${MODULE} --kwargs '${KWARGS}'"
