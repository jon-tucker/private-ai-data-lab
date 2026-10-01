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

append_default LIVESTACK_EDGE_IMAGE nginx:1.30.4-alpine3.24
append_default LIVESTACK_EDGE_CONTAINER oracle-ai-livestack-edge
append_default LIVESTACK_EDGE_TLS_DIR /srv/oracle-ai-secrets/livestack-edge-tls
append_default LIVESTACK_EDGE_DATA_DIR /srv/oracle-ai-data/livestack-edge
append_default LIVESTACK_EDGE_HOST_BIND 127.0.0.1
append_default LIVESTACK_EDGE_PORT 8506
append_default LIVESTACK_EDGE_ALLOWED_CIDR 192.168.0.0/24
append_default LIVESTACK_EDGE_SERVER_NAME oracle-ai.local
