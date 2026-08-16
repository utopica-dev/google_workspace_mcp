#!/bin/sh
# Utopica (req R.01, 2026-08-15): entrypoint que corre como root SOLO para
# arreglar el dueno del volumen persistente de Railway (que monta en root),
# y luego deja caer privilegios al usuario no-root "app" para el proceso real.
# No inventa ninguna otra logica: es el mismo comando que antes corria via
# `sh -c`, nada mas envuelto.
set -e

CREDS_DIR="${WORKSPACE_MCP_CREDENTIALS_DIR:-/app/store_creds}"

mkdir -p "$CREDS_DIR"
chown -R app:app "$CREDS_DIR"

exec su -s /bin/sh app -c "$1"
