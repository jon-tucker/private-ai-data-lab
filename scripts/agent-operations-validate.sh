#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

for command in openssl virsh; do
  require_command "${command}"
done

require_positive_integer() {
  local name="$1"
  local value="$2"

  [[ "${value}" =~ ^[1-9][0-9]*$ ]] ||
    die "${name} must be a positive integer"
}

require_positive_integer \
  AGENT_OPERATIONS_CERT_WARN_DAYS \
  "${AGENT_OPERATIONS_CERT_WARN_DAYS}"
require_positive_integer \
  AGENT_OPERATIONS_DISK_WARN_PERCENT \
  "${AGENT_OPERATIONS_DISK_WARN_PERCENT}"
require_positive_integer \
  AGENT_OPERATIONS_VM_SHUTDOWN_TIMEOUT \
  "${AGENT_OPERATIONS_VM_SHUTDOWN_TIMEOUT}"

((AGENT_OPERATIONS_DISK_WARN_PERCENT <= 100)) ||
  die 'AGENT_OPERATIONS_DISK_WARN_PERCENT must not exceed 100'

[[ "${AGENT_OPERATIONS_BACKUP_ROOT}" == /* ]] ||
  die 'AGENT_OPERATIONS_BACKUP_ROOT must be an absolute path'
case "${AGENT_OPERATIONS_BACKUP_ROOT}/" in
  "${PLATFORM_DATA_ROOT}/oracle/"* | \
  "${PLATFORM_DATA_ROOT}/mcp/"* | \
  "${PLATFORM_DATA_ROOT}/vms/"*)
    die 'AGENT_OPERATIONS_BACKUP_ROOT must not be inside active platform data'
    ;;
esac
[[ -d "${PLATFORM_DATA_ROOT}" ]] ||
  die "Platform data root does not exist: ${PLATFORM_DATA_ROOT}"
[[ -f "${AGENT_FACTORY_OS_DISK}" ]] ||
  die "Agent Factory OS disk not found: ${AGENT_FACTORY_OS_DISK}"
[[ -f "${AGENT_FACTORY_BUILD_DISK}" ]] ||
  die "Agent Factory build disk not found: ${AGENT_FACTORY_BUILD_DISK}"
[[ -f "${MCP_TLS_DIR}/ca.crt" ]] ||
  die "MCP CA certificate not found: ${MCP_TLS_DIR}/ca.crt"
[[ -f "${MCP_TLS_DIR}/server.crt" ]] ||
  die "MCP server certificate not found: ${MCP_TLS_DIR}/server.crt"

openssl verify \
  -CAfile "${MCP_TLS_DIR}/ca.crt" \
  "${MCP_TLS_DIR}/server.crt" >/dev/null

virsh -c "${AGENT_FACTORY_VM_URI}" dominfo \
  "${AGENT_FACTORY_VM_NAME}" >/dev/null

printf 'Agent operations configuration validation passed.\n'
