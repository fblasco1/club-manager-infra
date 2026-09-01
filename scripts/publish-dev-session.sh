#!/usr/bin/env bash
# Cierra sesión de desarrollo: bitácora ← sync-pm-ai.md + publicación Drive.
#
# Uso manual:
#   ./scripts/publish-dev-session.sh
#   ./scripts/publish-dev-session.sh --dry-run
#
# Invocado por .cursor/hooks/publish-dev-session.sh (sessionEnd).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${SYNC_PM_AI_ENV:-$ROOT/.env.sync-pm-ai}"
LOG="${PUBLISH_DEV_SESSION_LOG:-$ROOT/.cursor/hooks/publish-dev-session.log}"
DRY_RUN=0

for arg in "$@"; do
	case "$arg" in
		--dry-run) DRY_RUN=1 ;;
	esac
done

log() {
	echo "[$(date -Iseconds)] $*" | tee -a "$LOG"
}

mkdir -p "$(dirname "$LOG")"

if [[ -f "$ENV_FILE" ]]; then
	# shellcheck disable=SC1090
	set -a
	source "$ENV_FILE"
	set +a
fi

log "==> actualizar bitácora desde sync-pm-ai.md"
python3 "$ROOT/scripts/append_devlog_from_sync.py" || log "WARN: actualizar bitácora falló"

upload_args=()
if [[ "$DRY_RUN" -eq 1 ]]; then
	upload_args+=(--dry-run)
fi

upload_wsl() {
	[[ -n "${RCLONE_REMOTE:-}" ]] && command -v rclone >/dev/null 2>&1 \
		&& curl -4 -sS --connect-timeout 5 --max-time 8 -o /dev/null https://www.google.com 2>/dev/null
}

upload_windows() {
	command -v powershell.exe >/dev/null 2>&1 || return 1
	local ps1="$ROOT/scripts/sync-pm-ai-to-drive.ps1"
	[[ -f "$ps1" ]] || return 1
	local win_root
	win_root="$(wslpath -w "$ROOT" 2>/dev/null || true)"
	if [[ -z "$win_root" ]]; then
		return 1
	fi
	local ps_args=("-NoProfile" "-ExecutionPolicy" "Bypass" "-File" "${win_root}\\scripts\\sync-pm-ai-to-drive.ps1")
	if [[ "$DRY_RUN" -eq 1 ]]; then
		ps_args+=("-DryRun")
	fi
	powershell.exe "${ps_args[@]}"
}

log "==> publicar sync-pm-ai.md + Bitácora de desarrollo en Drive"
if upload_wsl; then
	log "backend: rclone (WSL)"
	"$ROOT/scripts/sync-pm-ai-to-drive.sh" "${upload_args[@]}" && exit 0
fi

if upload_windows; then
	log "backend: rclone (Windows PowerShell)"
	exit 0
fi

log "WARN: sin red WSL ni PowerShell — archivos locales actualizados; subí manualmente:"
log "  .\\scripts\\sync-pm-ai-to-drive.ps1"
exit 0
