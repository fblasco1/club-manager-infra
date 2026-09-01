#!/usr/bin/env bash
# Pipeline apply cobranza informe Excel en producción Hetzner.
#
# Requisitos:
#   - Deploy previo con bulk_payments + cobranza_informe_prod_pipeline (rama mvp/secretaria-2026-06)
#   - Backup DB prod reciente
#   - Excel en el host o copiado al contenedor backend
#
# Uso:
#   ./scripts/prod/apply-cobranza-informe.sh /ruta/local/Cobranza\ 01\ a\ 28-08.xlsx
#   ./scripts/prod/apply-cobranza-informe.sh --dry-run /ruta/informe.xlsx
#   ./scripts/prod/apply-cobranza-informe.sh --prep-only /ruta/informe.xlsx
#   ./scripts/prod/apply-cobranza-informe.sh --apply /ruta/informe.xlsx
#
# Variables: PROD_HOST, PROD_SITE, HETZNER_SSH_KEY, LOG_DIR remoto

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROD_HOST="${PROD_HOST:-root@157.90.164.162}"
PROD_SITE="${PROD_SITE:-gestion.icdpedroechague.com.ar}"
COMPOSE_DIR="${COMPOSE_DIR:-/root/club_manager_infra}"
SSH_KEY="${HETZNER_SSH_KEY:-/tmp/hetzner_key}"
REMOTE_LOG_DIR="${REMOTE_LOG_DIR:-/tmp/cobranza_pipeline}"
MODE="dry-run"
XLSX=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--dry-run) MODE="dry-run"; shift ;;
		--prep-only) MODE="prep"; shift ;;
		--apply) MODE="apply"; shift ;;
		-*) echo "Opción desconocida: $1" >&2; exit 1 ;;
		*)
			if [[ -z "$XLSX" ]]; then
				XLSX="$1"
			else
				echo "Solo un archivo Excel." >&2
				exit 1
			fi
			shift
			;;
	esac
done

if [[ -z "$XLSX" || ! -f "$XLSX" ]]; then
	echo "Uso: $0 [--dry-run|--prep-only|--apply] /ruta/informe.xlsx" >&2
	exit 1
fi

if [[ -f "$ROOT/scripts/prod/prepare-ssh-key.sh" ]]; then
	"$ROOT/scripts/prod/prepare-ssh-key.sh" >/dev/null 2>&1 || true
fi

ssh_opts=(-o StrictHostKeyChecking=no)
if [[ -f "$SSH_KEY" ]]; then
	ssh_opts+=(-i "$SSH_KEY")
fi

BASENAME="$(basename "$XLSX")"
REMOTE_XLSX="/tmp/${BASENAME}"

echo "==> Copiar informe → $PROD_HOST:$REMOTE_XLSX"
scp "${ssh_opts[@]}" "$XLSX" "${PROD_HOST}:${REMOTE_XLSX}"

KWARGS="{\"csv_path\": \"${REMOTE_XLSX}\", \"log_dir\": \"${REMOTE_LOG_DIR}\""

case "$MODE" in
	dry-run)
		KWARGS+=", \"dry_run\": true"
		;;
	prep)
		KWARGS+=", \"dry_run\": false, \"skip_apply\": true, \"confirm\": \"APPLY_PROD\""
		;;
	apply)
		KWARGS+=", \"dry_run\": false, \"confirm\": \"APPLY_PROD\""
		;;
esac
KWARGS+="}"

echo "==> Pipeline cobranza ($MODE) en $PROD_SITE"
ssh "${ssh_opts[@]}" "$PROD_HOST" bash -s <<REMOTE
set -euo pipefail
cd "$COMPOSE_DIR"
DC="docker compose -f compose.yaml -f overrides/compose.postgres.yaml -f overrides/compose.redis.yaml -f overrides/compose.https.yaml"
\$DC exec -T backend bash -lc "cd /home/frappe/frappe-bench && bench --site $PROD_SITE execute club_management.scripts.cobranza_informe_prod_pipeline.run --kwargs '$KWARGS'" </dev/null
REMOTE

echo "OK: pipeline $MODE finalizado. Logs en $PROD_HOST:$REMOTE_LOG_DIR/pipeline_summary.json"
