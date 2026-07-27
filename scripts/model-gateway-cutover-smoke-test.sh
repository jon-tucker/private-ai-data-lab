#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command ssh
require_command ss

"${PROJECT_ROOT}/scripts/model-gateway-operations-smoke-test.sh"
"${PROJECT_ROOT}/scripts/model-gateway-operations-agent-factory-smoke-test.sh"

if ss -ltnH |
  awk '{print $4}' |
  grep -Eq "(^|\\])${LITELLM_HOST_BIND}:${LITELLM_PORT}$|^${LITELLM_HOST_BIND}:${LITELLM_PORT}$"
then
  die "LiteLLM HTTP remains published at ${LITELLM_HOST_BIND}:${LITELLM_PORT}"
fi

remote="${AGENT_FACTORY_VM_USER}@${AGENT_FACTORY_VM_IP}"
if ssh -T -o BatchMode=yes -o ConnectTimeout=5 "${remote}" \
  "curl --silent --show-error --connect-timeout 3 --output /dev/null 'http://${LITELLM_HOST_BIND}:${LITELLM_PORT}/health/liveliness'" \
  2>/dev/null
then
  die 'Agent Factory can still reach the retired LiteLLM HTTP endpoint'
fi

printf 'PASS: LiteLLM HTTPS is operational and HTTP port 4000 is retired.\n'
