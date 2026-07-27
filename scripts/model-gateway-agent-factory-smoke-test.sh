#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command ssh

status="$(
  ssh -T -o BatchMode=yes -o ConnectTimeout=5 \
    "${AGENT_FACTORY_VM_USER}@${AGENT_FACTORY_VM_IP}" \
    "curl --silent --output /dev/null --write-out '%{http_code}' http://${LITELLM_HOST_BIND}:${LITELLM_PORT}/health/liveliness" \
    2>/dev/null || true
)"

[[ "${status}" == '200' ]] ||
  die "Agent Factory VM could not reach LiteLLM; HTTP ${status:-000}"
printf 'Agent Factory VM can reach the private LiteLLM gateway.\n'
