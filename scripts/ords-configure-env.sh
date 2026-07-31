#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[[ -f "${ENV_FILE}" ]] || cp "${PROJECT_ROOT}/.env.example" "${ENV_FILE}"

append_default() {
  local key="$1" value="$2"
  if ! grep -q "^${key}=" "${ENV_FILE}"; then
    printf '%s=%s\n' "${key}" "${value}" >>"${ENV_FILE}"
    printf 'Added %s to .env\n' "${key}"
  fi
}

append_default ORDS_IMAGE container-registry.oracle.com/database/ords:26.2.0
append_default ORDS_CONTAINER oracle-ai-ords
append_default ORDS_INSTALL_CONTAINER oracle-ai-ords-install
append_default ORDS_HOST_BIND 0.0.0.0
append_default ORDS_PORT 8080
append_default ORDS_CPUS 2.0
append_default ORDS_MEMORY 2g
append_default ORDS_CONFIG_DIR /srv/oracle-ai-data/ords
append_default ORDS_PUBLIC_PASSWORD_FILE /srv/oracle-ai-secrets/ords-public-user-password
append_default ORDS_URL http://127.0.0.1:8080/ords/
