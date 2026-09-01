#!/usr/bin/env bash
# Publica docs/club/sync-pm-ai.md en Google Drive (carpeta Gemini PM AI).
#
# Backends (en orden):
#   1. rclone — si RCLONE_REMOTE está definido (sin deps Python).
#   2. Google Drive API — scripts/sync_pm_ai_to_drive.py
#
# Configuración: copiar docs/club/example.sync-pm-ai.env → .env.sync-pm-ai
# (gitignored) y completar variables.
#
# Uso:
#   ./scripts/sync-pm-ai-to-drive.sh
#   ./scripts/sync-pm-ai-to-drive.sh --dated
#   ./scripts/sync-pm-ai-to-drive.sh --auth          # OAuth primera vez
#   ./scripts/sync-pm-ai-to-drive.sh --dry-run
#   RCLONE_REMOTE=gdrive ./scripts/sync-pm-ai-to-drive.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYNC_FILE="${SYNC_FILE:-$ROOT/docs/club/sync-pm-ai.md}"
DEVLOG_FILE="${BITACORA_FILE:-${DEVLOG_FILE:-$ROOT/docs/club/bitacora-de-desarrollo.md}}"
BITACORA_DRIVE_NAME="${BITACORA_DRIVE_NAME:-Bitacora de desarrollo.md}"
DEVLOG_DRIVE_NAME="${DEVLOG_DRIVE_NAME:-$BITACORA_DRIVE_NAME}"
ENV_FILE="${SYNC_PM_AI_ENV:-$ROOT/.env.sync-pm-ai}"

if [[ -f "$ENV_FILE" ]]; then
	# shellcheck disable=SC1090
	set -a
	source "$ENV_FILE"
	set +a
fi

if [[ ! -f "$SYNC_FILE" ]]; then
	echo "No existe $SYNC_FILE — generá el sync antes (Cursor: «generar sync para PM»)." >&2
	exit 1
fi

preflight_network() {
	# WSL a veces pierde salida HTTPS (VPN, Hyper-V, DNS). Fallar rápido con instrucciones.
	if curl -4 -sS --connect-timeout 5 --max-time 8 -o /dev/null https://www.google.com 2>/dev/null; then
		return 0
	fi
	echo "" >&2
	echo "⚠ WSL no tiene salida HTTPS a Internet (timeout a google.com)." >&2
	echo "  rclone desde WSL no puede llegar a Google Drive." >&2
	echo "" >&2
	echo "  Usá PowerShell en Windows:" >&2
	echo "    cd \\\\wsl.localhost\\Ubuntu\\home\\francisco\\ERSport\\club_manager_infra" >&2
	echo "    .\\scripts\\sync-pm-ai-to-drive.ps1 -CopyConfigFromWsl   # solo la 1.ª vez" >&2
	echo "    .\\scripts\\sync-pm-ai-to-drive.ps1" >&2
	echo "" >&2
	echo "  Guía: docs/club/rclone-oauth-wsl-fix.md" >&2
	exit 1
}

upload_via_rclone() {
	local remote="${RCLONE_REMOTE:?Definí RCLONE_REMOTE (ej. gdrive-icdpe)}"
	local folder_id="${RCLONE_ROOT_FOLDER_ID:-${GOOGLE_DRIVE_FOLDER_ID:-}}"
	local folder_path="${RCLONE_FOLDER_PATH:-}"
	local rclone_opts=()
	local dated=0
	local dry_run=0
	local dest dated_dest

	for arg in "$@"; do
		case "$arg" in
			--dated) dated=1 ;;
			--dry-run) dry_run=1 ;;
		esac
	done

	if [[ "$dry_run" -eq 1 ]]; then
		rclone_opts+=(--dry-run)
	fi

	# Preferir folder ID (más robusto que el nombre con espacios/guiones)
	if [[ -n "$folder_id" ]]; then
		rclone_opts+=(--drive-root-folder-id="$folder_id")
		dest="${remote}:sync-pm-ai.md"
		dated_dest="${remote}:sync-pm-ai-$(date +%Y-%m-%d).md"
	else
		folder_path="${folder_path:-Sistema de Gestion - ERP CLUBES}"
		dest="${remote}:${folder_path}/sync-pm-ai.md"
		dated_dest="${remote}:${folder_path}/sync-pm-ai-$(date +%Y-%m-%d).md"
	fi

	echo "==> rclone → $dest"
	rclone copyto "$SYNC_FILE" "$dest" \
		--timeout 2m --contimeout 30s \
		"${rclone_opts[@]}" ${RCLONE_EXTRA_OPTS:+${RCLONE_EXTRA_OPTS}}

	if [[ -f "$DEVLOG_FILE" ]]; then
		if [[ -n "$folder_id" ]]; then
			devlog_dest="${remote}:${DEVLOG_DRIVE_NAME}"
		else
			devlog_dest="${remote}:${folder_path}/${DEVLOG_DRIVE_NAME}"
		fi
		echo "==> rclone → $devlog_dest"
		rclone copyto "$DEVLOG_FILE" "$devlog_dest" \
			--timeout 2m --contimeout 30s \
			"${rclone_opts[@]}" ${RCLONE_EXTRA_OPTS:+${RCLONE_EXTRA_OPTS}}
	fi

	if [[ "$dated" -eq 1 ]]; then
		rclone copyto "$SYNC_FILE" "$dated_dest" "${rclone_opts[@]}" ${RCLONE_EXTRA_OPTS:+${RCLONE_EXTRA_OPTS}}
		echo "==> copia fechada: $dated_dest"
	fi
}

upload_via_gapi() {
	local py="${PYTHON:-python3}"
	local req="$ROOT/scripts/requirements-sync-drive.txt"
	local script="$ROOT/scripts/sync_pm_ai_to_drive.py"

	if ! "$py" -c "import googleapiclient" 2>/dev/null; then
		echo "Instalando dependencias Google Drive (pip --user)…" >&2
		"$py" -m pip install --user -q -r "$req"
	fi

	"$py" "$script" "$@"
}

main() {
	local use_rclone=0
	# ~/bin (instalación local sin sudo)
	if [[ -d "${HOME}/bin" ]]; then
		PATH="${HOME}/bin:${PATH}"
	fi
	if [[ -n "${RCLONE_REMOTE:-}" ]] && command -v rclone >/dev/null 2>&1; then
		use_rclone=1
	fi

	# --auth solo aplica a OAuth / gapi
	for arg in "$@"; do
		if [[ "$arg" == "--auth" ]]; then
			use_rclone=0
			break
		fi
	done

	if [[ "$use_rclone" -eq 1 ]]; then
		preflight_network
		upload_via_rclone "$@"
		return
	fi

	upload_via_gapi "$@"
}

main "$@"
