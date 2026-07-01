#!/usr/bin/env bash
# Reset padrón producción: borrar socios/pagos de prueba + migrate + import CSV.
#
# Uso (desde club_manager_infra en el servidor o vía SSH):
#   ./scripts/prod/prepare-ssh-key.sh   # local WSL
#   ./scripts/prod/reset-padron-produccion.sh dry-run
#   ./scripts/prod/reset-padron-produccion.sh wipe
#   ./scripts/prod/reset-padron-produccion.sh import
#   ./scripts/prod/reset-padron-produccion.sh full
#
# Variables: PROD_HOST, PROD_SITE, HETZNER_SSH_KEY, CSV_PATH

set -euo pipefail

PROD_HOST="${PROD_HOST:-root@157.90.164.162}"
PROD_SITE="${PROD_SITE:-gestion.icdpedroechague.com.ar}"
HETZNER_SSH_KEY="${HETZNER_SSH_KEY:-/tmp/hetzner_key}"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-club_manager_infra}"
COMPOSE_FILES="${COMPOSE_FILES:-compose.yaml -f overrides/compose.postgres.yaml -f overrides/compose.redis.yaml -f overrides/compose.https.yaml}"
CSV_PATH="${CSV_PATH:-/home/francisco/ERSport/club_manager_infra/tmp/padron/socios_limpios_frappe.csv}"
REMOTE_CSV="/home/frappe/frappe-bench/sites/socios_limpios_frappe.csv"
APP_ROOT="/home/francisco/ERSport/club_manager_infra/development/frappe-bench/apps/club_management/club_management"

sync_code_to_prod() {
	echo "==> Sincronizar scripts de padrón al backend (sin git push)"
	ssh_prod "mkdir -p /tmp/club_padron_sync"
	scp -i "$HETZNER_SSH_KEY" -o StrictHostKeyChecking=no \
		"$APP_ROOT/members/setup/wipe_socios_prueba.py" \
		"$APP_ROOT/members/setup/import_socios_padron.py" \
		"$APP_ROOT/members/doctype/socio/socio.py" \
		"$APP_ROOT/members/doctype/socio/socio.json" \
		"${PROD_HOST}:/tmp/club_padron_sync/"
	ssh_prod "docker compose -p $COMPOSE_PROJECT -f $COMPOSE_FILES cp /tmp/club_padron_sync/. backend:/tmp/club_padron_sync/"
	ssh_prod "docker compose -p $COMPOSE_PROJECT -f $COMPOSE_FILES exec -T -u root backend bash -lc \"cp /tmp/club_padron_sync/wipe_socios_prueba.py apps/club_management/club_management/members/setup/ && cp /tmp/club_padron_sync/import_socios_padron.py apps/club_management/club_management/members/setup/ && cp /tmp/club_padron_sync/socio.py apps/club_management/club_management/members/doctype/socio/ && cp /tmp/club_padron_sync/socio.json apps/club_management/club_management/members/doctype/socio/ && chown frappe:frappe apps/club_management/club_management/members/setup/*.py apps/club_management/club_management/members/doctype/socio/socio.*\""
}

ssh_prod() {
	ssh -i "$HETZNER_SSH_KEY" -o StrictHostKeyChecking=no "$PROD_HOST" "$@"
}

backend_exec() {
	ssh_prod "docker compose -p $COMPOSE_PROJECT -f $COMPOSE_FILES exec -T backend bash -lc $(printf '%q' "$1")"
}

cmd_dry_run() {
	echo "==> Simulación borrado socios prueba ($PROD_SITE)"
	backend_exec "bench --site '$PROD_SITE' execute club_management.members.setup.wipe_socios_prueba.run --kwargs '{\"dry_run\": True}'"
}

cmd_wipe() {
	echo "==> BORRADO REAL socios y cobranza de prueba ($PROD_SITE)"
	backend_exec "bench --site '$PROD_SITE' execute club_management.members.setup.wipe_socios_prueba.run --kwargs '{\"dry_run\": False, \"confirm\": \"WIPE_SOCIOS_PRUEBA\"}'"
}

cmd_migrate() {
	echo "==> bench migrate ($PROD_SITE)"
	backend_exec "bench --site '$PROD_SITE' migrate --skip-failing"
	backend_exec "bench build --app club_management"
	backend_exec "bench --site '$PROD_SITE' clear-cache"
}

cmd_import() {
	if [[ ! -f "$CSV_PATH" ]]; then
		echo "No existe CSV local: $CSV_PATH" >&2
		exit 1
	fi
	echo "==> Copiando CSV al backend..."
	ssh_prod "docker compose -p $COMPOSE_PROJECT -f $COMPOSE_FILES cp -" 2>/dev/null || true
	scp -i "$HETZNER_SSH_KEY" -o StrictHostKeyChecking=no "$CSV_PATH" \
		"${PROD_HOST}:/tmp/socios_limpios_frappe.csv"
	ssh_prod "docker compose -p $COMPOSE_PROJECT -f $COMPOSE_FILES cp /tmp/socios_limpios_frappe.csv backend:$REMOTE_CSV"

	echo "==> Dry-run import padrón"
	backend_exec "bench --site '$PROD_SITE' execute club_management.members.setup.import_socios_padron.run --kwargs '{\"csv_path\": \"$REMOTE_CSV\", \"dry_run\": True}'"

	echo "==> Import REAL padrón"
	backend_exec "bench --site '$PROD_SITE' execute club_management.members.setup.import_socios_padron.run --kwargs '{\"csv_path\": \"$REMOTE_CSV\", \"dry_run\": False, \"commit_every\": 100}'"
}

cmd_full() {
	sync_code_to_prod
	cmd_wipe
	cmd_migrate
	cmd_import
	echo "OK reset padrón completo."
}

usage() {
	cat <<EOF
Uso: $0 <comando>

Comandos:
  dry-run    Contar qué se borraría (sin cambios)
  wipe       Borrar socios de prueba y cobranza vinculada
  migrate    migrate + build club_management
  import     Subir CSV e importar padrón (dry-run + real)
  full       wipe + migrate + import

EOF
}

case "${1:-}" in
dry-run) cmd_dry_run ;;
wipe) cmd_wipe ;;
migrate) cmd_migrate ;;
import) cmd_import ;;
full) cmd_full ;;
*) usage; exit 1 ;;
esac
