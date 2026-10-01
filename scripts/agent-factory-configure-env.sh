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

append_default AGENT_FACTORY_VERSION 26.7.0
append_default AGENT_FACTORY_VM_NAME agent-factory
append_default AGENT_FACTORY_VM_IP 192.168.122.202
append_default AGENT_FACTORY_VM_USER "$(id -un)"
append_default AGENT_FACTORY_VM_URI qemu:///system
append_default AGENT_FACTORY_DB_USER AGENT_FACTORY
append_default AGENT_FACTORY_DB_READ_USER AAI_RO_AGENT_FACTORY
append_default AGENT_FACTORY_DB_PASSWORD_FILE /srv/oracle-ai-secrets/agent-factory-db-password
append_default AGENT_FACTORY_OLLAMA_URL http://192.168.122.1:11434
append_default AGENT_FACTORY_STAGE_ROOT /u01/agent-factory
append_default AGENT_FACTORY_INSTALL_DIR /u01/agent-factory/staging/26.7.0-upgrade
append_default AGENT_FACTORY_PORT 8080
