#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[[ -f "${ENV_FILE}" ]] || cp "${PROJECT_ROOT}/.env.example" "${ENV_FILE}"

append_default() {
  local name="$1"
  local value="$2"
  if ! grep -q "^${name}=" "${ENV_FILE}"; then
    printf '%s=%s\n' "${name}" "${value}" >> "${ENV_FILE}"
    printf 'Added %s to .env\n' "${name}"
  fi
}

append_default APEX_VERSION 26.1
append_default APEX_SOURCE_DIR /srv/oracle-ai-work/apex/apex
append_default APEX_IMAGES_DIR /srv/oracle-ai-data/apex/images
append_default APEX_CONTAINER_SOURCE_DIR /opt/oracle/apex-26.1
append_default APEX_TABLESPACE APEX
append_default APEX_FILES_TABLESPACE APEX_FILES
append_default APEX_ADMIN_USERNAME ADMIN
append_default APEX_URL http://127.0.0.1:8080/ords/
