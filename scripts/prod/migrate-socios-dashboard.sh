#!/usr/bin/env bash
# Migración a producción: dashboard Gestión de Socios + datos de socios.
#
# Uso local (exportar desde dev):
#   ./scripts/prod/migrate-socios-dashboard.sh export
#
# Uso en servidor de producción (tras copiar el backup):
#   ./scripts/prod/migrate-socios-dashboard.sh restore /ruta/al/backup.sql.gz
#   ./scripts/prod/migrate-socios-dashboard.sh post-restore
#
# Requiere: Docker Compose frappe_docker con servicio `backend`, sitio secretaria.icdpe.org.ar

set -euo pipefail

PROD_SITE="${PROD_SITE:-secretaria.icdpe.org.ar}"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-icdpe}"
COMPOSE_FILES="${COMPOSE_FILES:-compose.yaml -f overrides/compose.postgres.yaml -f overrides/compose.redis.yaml}"
BACKUP_DIR="${BACKUP_DIR:-./backups/prod-migration}"
APP_BRANCH="${APP_BRANCH:-mvp/secretaria-2026-06}"

dc() {
	docker compose -p "$COMPOSE_PROJECT" -f $COMPOSE_FILES "$@"
}

backend_exec() {
	dc exec -T backend bash -lc "$1"
}

cmd_export() {
	local bench_path="${BENCH_PATH:-/workspace/development/frappe-bench}"
	local dev_site="${DEV_SITE:-dev.localhost}"
	local container="${DEV_CONTAINER:-devcontainer-example-frappe-1}"

	mkdir -p "$BACKUP_DIR"
	echo "==> Backup sitio dev: $dev_site → $BACKUP_DIR"
	docker exec "$container" bash -lc \
		"cd '$bench_path' && bench --site '$dev_site' backup --with-files --backup-path '$bench_path/backups/prod-migration'"
	echo "==> Copiando backups al host..."
	docker cp "$container:$bench_path/backups/prod-migration/." "$BACKUP_DIR/"
	ls -lh "$BACKUP_DIR"
	echo "OK. Subí $BACKUP_DIR al servidor de producción (scp/rsync)."
}

cmd_restore() {
	local backup_db="${1:?Falta ruta al .sql.gz del backup (database)}"
	local backup_public="${2:-}"
	local backup_private="${3:-}"

	if [[ ! -f "$backup_db" ]]; then
		echo "No existe: $backup_db" >&2
		exit 1
	fi

	echo "==> Restaurando base en sitio $PROD_SITE"
	# Si el sitio no existe, crearlo (Postgres)
	if ! backend_exec "test -d sites/$PROD_SITE"; then
		echo "==> Creando sitio $PROD_SITE"
		backend_exec "bench new-site --db-type postgres --admin-password admin --install-app erpnext --install-app club_management '$PROD_SITE'"
	fi

	backend_exec "bench --site '$PROD_SITE' restore '$backup_db' ${backup_public:+--with-public-files '$backup_public'} ${backup_private:+--with-private-files '$backup_private'} --force"
	echo "OK restore DB."
}

cmd_post_restore() {
	echo "==> Corrigiendo timestamps (pgloader / migración MariaDB→PG)"
	backend_exec "bench --site '$PROD_SITE' postgres" < "$(dirname "$0")/fix-pgloader-timestamps.sql" || true

	echo "==> migrate + build club_management"
	backend_exec "bench --site '$PROD_SITE' migrate --skip-failing"
	backend_exec "bench build --app club_management"
	backend_exec "bench --site '$PROD_SITE' clear-cache"

	echo "==> Verificación socios"
	backend_exec "bench --site '$PROD_SITE' execute club_management.members.services.secretaria_panel_kpis.count_socios_total"
	backend_exec "bench --site '$PROD_SITE' execute club_management.members.services.secretaria_workspace_panel.get_panel_lists_payload" | head -c 200
	echo ""
	echo "OK post-restore. Revisá Desk → Workspaces → Secretaría"
}

cmd_deploy_code() {
	echo "==> Desplegar solo código (sin reemplazar datos)"
	echo "1. Construir imagen custom con apps.prod.json (rama $APP_BRANCH)"
	echo "2. Actualizar .env: CUSTOM_IMAGE / CUSTOM_TAG"
	echo "3. docker compose pull && docker compose up -d"
	backend_exec "bench --site '$PROD_SITE' migrate --skip-failing"
	backend_exec "bench build --app club_management"
	backend_exec "bench --site '$PROD_SITE' clear-cache"
	echo "OK deploy código."
}

usage() {
	cat <<EOF
Uso: $0 <comando> [args]

Comandos:
  export                          Backup dev.localhost con archivos (desde máquina local)
  restore <db.sql.gz> [public] [private]   Restaurar backup en producción
  post-restore                    migrate, build, verificar panel Secretaría
  deploy-code                     Solo actualizar app (sin restore de datos)

Variables: PROD_SITE, COMPOSE_PROJECT, BACKUP_DIR, APP_BRANCH, DEV_CONTAINER
EOF
}

case "${1:-}" in
export) cmd_export ;;
restore) shift; cmd_restore "$@" ;;
post-restore) cmd_post_restore ;;
deploy-code) cmd_deploy_code ;;
*) usage; exit 1 ;;
esac
