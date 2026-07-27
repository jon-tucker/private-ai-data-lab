#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command scp
require_command ssh

remote="${AGENT_FACTORY_VM_USER}@${AGENT_FACTORY_VM_IP}"
remote_ca='/tmp/litellm-ca.crt'

scp -q \
  -o BatchMode=yes \
  -o ConnectTimeout=5 \
  "${LITELLM_TLS_DIR}/ca.crt" \
  "${remote}:${remote_ca}"

ssh -T -o BatchMode=yes -o ConnectTimeout=5 "${remote}" \
  "bash -s -- '${AGENT_FACTORY_INSTALL_DIR}' '${remote_ca}'" <<'REMOTE'
set -Eeuo pipefail
base="$1"
incoming_ca="$2"
volume="${base}/applied-ai/volume"
tls_dir="${volume}/config/app/latest/backend/tls"
source_env="${volume}/config/app/latest/backend/source_env.sh"
mcp_chain="${tls_dir}/mcp-trust-chain.pem"
litellm_ca="${tls_dir}/litellm-ca.crt"
platform_chain="${tls_dir}/platform-trust-chain.pem"

[[ -s "${mcp_chain}" ]] || {
  printf 'Missing existing MCP trust chain: %s\n' "${mcp_chain}" >&2
  exit 1
}

install -d -m 0700 "${tls_dir}"
install -m 0600 "${incoming_ca}" "${litellm_ca}"
cat "${mcp_chain}" "${litellm_ca}" >"${platform_chain}.tmp"
chmod 0600 "${platform_chain}.tmp"
mv "${platform_chain}.tmp" "${platform_chain}"
cp -p "${source_env}" "${source_env}.pre-litellm-tls"
sed -i \
  's|^export SSL_CERTIFICATE_FILE=.*|export SSL_CERTIFICATE_FILE=/mount/config/app/latest/backend/tls/platform-trust-chain.pem|' \
  "${source_env}"
rm -f "${incoming_ca}"

make -C "${base}" stop
make -C "${base}" start
REMOTE

printf 'Installed the LiteLLM CA and restarted Agent Factory.\n'
