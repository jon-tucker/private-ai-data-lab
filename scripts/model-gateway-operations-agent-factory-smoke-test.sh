#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command ssh

remote="${AGENT_FACTORY_VM_USER}@${AGENT_FACTORY_VM_IP}"
container_ca='/mount/config/app/latest/backend/tls/platform-trust-chain.pem'

result="$(
  ssh -T -o BatchMode=yes -o ConnectTimeout=5 "${remote}" \
    "podman exec oracle-applied-ai-label curl --fail --silent --show-error --cacert '${container_ca}' 'https://${LITELLM_HTTPS_HOST_BIND}:${LITELLM_HTTPS_PORT}/health/liveliness'" \
    2>/dev/null || true
)"
[[ "${result}" == *"I'm alive!"* || "${result}" == *'"status"'* || -n "${result}" ]] ||
  die 'Agent Factory did not trust the LiteLLM HTTPS endpoint'

active_ca="$(
  ssh -T -o BatchMode=yes -o ConnectTimeout=5 "${remote}" \
    "podman exec oracle-applied-ai-label sh -lc '. /mount/config/app/latest/backend/source_env.sh; printf \"%s\" \"\${SSL_CERTIFICATE_FILE}\"'" \
    2>/dev/null || true
)"
[[ "${active_ca}" == "${container_ca}" ]] ||
  die "Unexpected Agent Factory trust file: ${active_ca:-unset}"
printf 'Agent Factory trusts and reaches the LiteLLM HTTPS endpoint.\n'
