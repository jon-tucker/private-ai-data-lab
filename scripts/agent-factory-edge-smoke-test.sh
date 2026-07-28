#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
status="$(
  curl --fail --silent --show-error \
    --cacert "${AGENT_FACTORY_EDGE_TLS_DIR}/ca.crt" \
    --output /dev/null --write-out '%{http_code}' \
    "https://${AGENT_FACTORY_EDGE_HOST_BIND}:${AGENT_FACTORY_EDGE_PORT}/agentFactory/"
)"
[[ "${status}" == 200 ]] || die "Agent Factory edge returned HTTP ${status}"
printf 'Agent Factory trusted HTTPS edge returned HTTP 200.\n'
