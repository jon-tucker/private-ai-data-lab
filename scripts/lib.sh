#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

load_env() {
  [[ -f "${ENV_FILE}" ]] || die "Missing ${ENV_FILE}; copy .env.example to .env first"
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
  export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-oracle-ai-data-platform}"
  export PLATFORM_DATA_ROOT="${PLATFORM_DATA_ROOT:-/srv/oracle-ai-data}"
  export PLATFORM_SECRETS_ROOT="${PLATFORM_SECRETS_ROOT:-/srv/oracle-ai-secrets}"
  export ORACLE_DATABASE_CONTAINER="${ORACLE_DATABASE_CONTAINER:-oracle-ai-database}"
  export ORACLE_PASSWORD_FILE="${ORACLE_PASSWORD_FILE:-${PLATFORM_SECRETS_ROOT}/oracle-db-password}"
  export OLLAMA_ACCELERATOR="${OLLAMA_ACCELERATOR:-rocm}"
  export OLLAMA_CONTAINER="${OLLAMA_CONTAINER:-oracle-ai-ollama}"
  export OPEN_WEBUI_CONTAINER="${OPEN_WEBUI_CONTAINER:-oracle-ai-open-webui}"
  export OPEN_WEBUI_SECRET_FILE="${OPEN_WEBUI_SECRET_FILE:-${PLATFORM_SECRETS_ROOT}/open-webui-secret-key}"
  export ORDS_CONTAINER="${ORDS_CONTAINER:-oracle-ai-ords}"
  export ORDS_INSTALL_CONTAINER="${ORDS_INSTALL_CONTAINER:-oracle-ai-ords-install}"
  export ORDS_CONFIG_DIR="${ORDS_CONFIG_DIR:-${PLATFORM_DATA_ROOT}/ords}"
  export ORDS_PUBLIC_PASSWORD_FILE="${ORDS_PUBLIC_PASSWORD_FILE:-${PLATFORM_SECRETS_ROOT}/ords-public-user-password}"
  export ORDS_URL="${ORDS_URL:-http://127.0.0.1:8080/ords/}"
}

compose() {
  docker compose --project-directory "${PROJECT_ROOT}" --env-file "${ENV_FILE}" "$@"
}
