#!/usr/bin/env bash
# Invoca git-push.ps1 en Windows (fallback cuando WSL no tiene HTTPS a GitHub).
#
# Uso (desde cualquier repo git en WSL):
#   ./scripts/win/git-push-via-windows.sh
#   ./scripts/win/git-push-via-windows.sh --remote upstream --branch mvp/secretaria-2026-06
#
# Variables: GIT_REMOTE, GIT_BRANCH

set -euo pipefail

REMOTE="${GIT_REMOTE:-origin}"
BRANCH="${GIT_BRANCH:-}"
DRY_RUN=0
PS1=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--remote) REMOTE="$2"; shift 2 ;;
		--branch) BRANCH="$2"; shift 2 ;;
		--dry-run) DRY_RUN=1; shift ;;
		*) echo "Opción desconocida: $1" >&2; exit 1 ;;
	esac
done

if ! command -v powershell.exe >/dev/null 2>&1; then
	echo "powershell.exe no disponible — ejecutá git-push.ps1 desde Windows." >&2
	exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PS1_WIN="$(wslpath -w "$ROOT/scripts/win/git-push.ps1")"
REPO="$(git rev-parse --show-toplevel)"
WIN_REPO="$(wslpath -w "$REPO")"

ps_inner="Set-Location '$WIN_REPO'; & '$PS1_WIN' -Remote '$REMOTE'"
[[ -n "$BRANCH" ]] && ps_inner+=" -Branch '$BRANCH'"
[[ "$DRY_RUN" -eq 1 ]] && ps_inner+=" -DryRun"

echo "==> git push vía Windows (repo: $REPO)"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ps_inner"
