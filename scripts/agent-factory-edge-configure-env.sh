#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

append_default() {
  local key="$1" value="$2"
  grep -q "^${key}=" "${ENV_FILE}" || {
    printf '%s=%s\n' "${key}" "${value}" >>"${ENV_FILE}"
    printf 'Added %s to .env\n' "${key}"
  }
}

append_default AGENT_FACTORY_EDGE_IMAGE nginx:1.30.4-alpine3.24
append_default AGENT_FACTORY_EDGE_CONTAINER oracle-ai-agent-factory-edge
append_default AGENT_FACTORY_EDGE_TLS_DIR /srv/oracle-ai-secrets/agent-factory-edge-tls
append_default AGENT_FACTORY_EDGE_DATA_DIR /srv/oracle-ai-data/agent-factory-edge
append_default AGENT_FACTORY_EDGE_HOST_BIND 192.168.0.209
append_default AGENT_FACTORY_EDGE_PORT 8443
append_default AGENT_FACTORY_EDGE_ALLOWED_CIDR 192.168.0.0/24
append_default AGENT_FACTORY_EDGE_SERVER_NAME oracle-ai
