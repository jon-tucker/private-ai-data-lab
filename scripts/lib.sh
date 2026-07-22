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
}

compose() {
  docker compose --project-directory "${PROJECT_ROOT}" --env-file "${ENV_FILE}" "$@"
}
