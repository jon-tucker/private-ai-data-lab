#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
[[ -f "${ENV_FILE}" ]] || cp "${PROJECT_ROOT}/.env.example" "${ENV_FILE}"

append_default() {
  local name="$1"
  local value="$2"
  if ! grep -q "^${name}=" "${ENV_FILE}"; then
    printf '%s=%s\n' "${name}" "${value}" >>"${ENV_FILE}"
    printf 'Added %s to .env\n' "${name}"
  fi
}

append_default OPERATIONS_AGENT_ENABLED 1
append_default OPERATIONS_AGENT_RETENTION_DAYS 365

printf 'Operations-agent environment defaults are configured.\n'
