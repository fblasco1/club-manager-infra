#!/usr/bin/env bash
# Copia la clave SSH de desarrollo a /tmp/hetzner_key (permisos 600).
# NO commitear la clave ni este archivo con rutas personales sensibles.
#
# Uso:
#   ./scripts/prod/prepare-ssh-key.sh
#   HETZNER_SSH_KEY_SOURCE=~/.ssh/id_ed25519 ./scripts/prod/prepare-ssh-key.sh

set -euo pipefail

SOURCE="${HETZNER_SSH_KEY_SOURCE:-/mnt/c/Users/USUARIO/.ssh/id_ed25519}"
TARGET="${HETZNER_SSH_KEY:-/tmp/hetzner_key}"

if [[ ! -f "$SOURCE" ]]; then
	echo "No se encontró la clave en: $SOURCE" >&2
	echo "Definí HETZNER_SSH_KEY_SOURCE con la ruta a tu id_ed25519." >&2
	exit 1
fi

cp "$SOURCE" "$TARGET"
chmod 600 "$TARGET"
echo "OK: $TARGET ($(wc -c < "$TARGET") bytes)"
