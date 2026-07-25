#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

"${PROJECT_ROOT}/scripts/mcp-http-smoke-test.sh"

target="${AGENT_FACTORY_VM_USER}@${AGENT_FACTORY_VM_IP}"
container_trust_file="/mount/config/app/latest/backend/tls/mcp-trust-chain.pem"

ssh -T "${target}" bash -s -- \
  "${container_trust_file}" \
  "${MCP_HTTPS_HOST_BIND}" \
  "${MCP_HTTPS_PORT}" <<'REMOTE'
set -Eeuo pipefail
trust_file="$1"
host="$2"
port="$3"

podman exec oracle-applied-ai-label test -r "${trust_file}"

for attempt in {1..12}; do
  response="$(
    podman exec oracle-applied-ai-label \
      curl --fail --silent --show-error \
      --cacert "${trust_file}" \
      "https://${host}:${port}/healthz" 2>/dev/null ||
      true
  )"
  [[ "${response}" == 'ok' ]] && break
  sleep 5
done
[[ "${response}" == 'ok' ]] || {
  printf 'ERROR: Agent Factory could not reach the trusted MCP HTTPS endpoint\n' >&2
  exit 1
}

printf 'Agent Factory trust file and MCP HTTPS endpoint passed.\n'
REMOTE

printf 'Agent Factory can reach and trust the SQLcl MCP HTTPS bridge.\n'
printf 'Run the documented Agent Builder identity query for the end-to-end tool test.\n'
