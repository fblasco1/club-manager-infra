#!/usr/bin/env bash
# Hook sessionEnd: actualiza bitácora y publica en Google Drive (fail-open).
set -euo pipefail
cat >/dev/null || true
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
exec "$ROOT/scripts/publish-dev-session.sh" >>"${PUBLISH_DEV_SESSION_LOG:-$ROOT/.cursor/hooks/publish-dev-session.log}" 2>&1 || true
