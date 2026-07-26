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

append_default AGENT_OPERATIONS_BACKUP_ROOT /srv/oracle-ai-data/backups/agent-operations
append_default AGENT_OPERATIONS_CERT_WARN_DAYS 90
append_default AGENT_OPERATIONS_DISK_WARN_PERCENT 80
append_default AGENT_OPERATIONS_VM_SHUTDOWN_TIMEOUT 300
append_default AGENT_FACTORY_OS_DISK /srv/oracle-ai-data/vms/agent-factory-ol8.qcow2
append_default AGENT_FACTORY_BUILD_DISK /srv/oracle-ai-data/vms/agent-factory-build.qcow2
