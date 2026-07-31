#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[[ -f "${ENV_FILE}" ]] || cp "${PROJECT_ROOT}/.env.example" "${ENV_FILE}"

append_default() {
  local key="$1"
  local value="$2"
  if ! grep -qE "^${key}=" "${ENV_FILE}"; then
    printf '%s=%s\n' "${key}" "${value}" >>"${ENV_FILE}"
    printf 'Added %s to .env\n' "${key}"
  fi
}

append_default LIVESTACK_IMAGE oracle-ai/livestack-utilities:1.2.0
append_default LIVESTACK_CONTAINER oracle-ai-livestack
append_default LIVESTACK_SOURCE_DIR /srv/oracle-ai-work/livestack/utilities
append_default LIVESTACK_ARCHIVE /tmp/livestack.zip
append_default LIVESTACK_HOST_BIND 127.0.0.1
append_default LIVESTACK_PORT 8505
append_default LIVESTACK_DATABASE_USER LIVESTACK
append_default LIVESTACK_DATABASE_PASSWORD_FILE /srv/oracle-ai-secrets/livestack-database-password
append_default LIVESTACK_DATABASE_CONNECT_STRING oracle-db:1521/FREEPDB1
append_default LIVESTACK_OLLAMA_URL http://ollama:11434
append_default LIVESTACK_OLLAMA_MODEL qwen3:4b-instruct
append_default LIVESTACK_TELEMETRY_ENABLED false
