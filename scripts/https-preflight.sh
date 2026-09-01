#!/usr/bin/env bash
# Comprueba salida HTTPS desde WSL y recomienda backend (WSL vs Windows).
# Uso: ./scripts/https-preflight.sh [--quiet]
# Exit 0 = WSL OK; exit 1 = usar fallback Windows para GitHub/Drive.

set -euo pipefail

QUIET=0
for arg in "$@"; do
	case "$arg" in
		--quiet) QUIET=1 ;;
	esac
done

log() {
	[[ "$QUIET" -eq 1 ]] || echo "$*"
}

check_url() {
	local name="$1" url="$2"
	if curl -4 -sS --connect-timeout 5 --max-time 8 -o /dev/null "$url" 2>/dev/null; then
		log "  OK  $name"
		return 0
	fi
	log "  FAIL $name"
	return 1
}

github_ok=0
drive_ok=0
hetzner_ok=0

log "==> Preflight HTTPS/SSH (WSL)"
check_url "GitHub (443)" "https://github.com" && github_ok=1 || true
check_url "Google (443)" "https://www.google.com" && drive_ok=1 || true
if command -v ssh >/dev/null 2>&1; then
	if ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no \
		-i "${HETZNER_SSH_KEY:-/tmp/hetzner_key}" root@157.90.164.162 true 2>/dev/null; then
		log "  OK  Hetzner SSH (22)"
		hetzner_ok=1
	else
		log "  FAIL Hetzner SSH (22) — ¿./scripts/prod/prepare-ssh-key.sh?"
	fi
else
	log "  SKIP ssh no instalado"
fi

if [[ "$github_ok" -eq 1 && "$drive_ok" -eq 1 ]]; then
	log ""
	log "WSL tiene salida HTTPS. Podés usar git/rclone desde bash."
	exit 0
fi

log ""
log "⚠ WSL sin HTTPS completo. Usar PowerShell en Windows para:"
[[ "$github_ok" -eq 0 ]] && log "  • git push  →  .\\scripts\\win\\git-push.ps1"
[[ "$drive_ok" -eq 0 ]] && log "  • Drive     →  .\\scripts\\publish-dev-session.sh  o  .\\scripts\\sync-pm-ai-to-drive.ps1"
[[ "$hetzner_ok" -eq 1 ]] && log "  • Deploy SSH desde WSL sigue OK: ./scripts/prod/deploy-club-management.sh"
exit 1
