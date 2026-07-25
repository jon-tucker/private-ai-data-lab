#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command scp
require_command ssh

"${PROJECT_ROOT}/scripts/mcp-http-validate.sh"
"${PROJECT_ROOT}/scripts/agent-factory-validate.sh"

target="${AGENT_FACTORY_VM_USER}@${AGENT_FACTORY_VM_IP}"
remote_tmp="/tmp/oracle-ai-mcp-tls-${$}"

ssh -T "${target}" "install -d -m 0700 '${remote_tmp}'"
scp \
  "${MCP_TLS_DIR}/server.crt" \
  "${MCP_TLS_DIR}/ca.crt" \
  "${target}:${remote_tmp}/"

ssh -T "${target}" bash -s -- \
  "${AGENT_FACTORY_INSTALL_DIR}" \
  "${remote_tmp}" \
  "${MCP_HTTPS_HOST_BIND}" \
  "${MCP_HTTPS_PORT}" \
  "${AGENT_FACTORY_PORT}" <<'REMOTE'
set -Eeuo pipefail

install_dir="$1"
remote_tmp="$2"
host="$3"
port="$4"
agent_factory_port="$5"
volume="${install_dir}/applied-ai/volume"
tls_dir="${volume}/config/app/latest/backend/tls"
source_env="${volume}/config/app/latest/backend/source_env.sh"
trust_file="${tls_dir}/mcp-trust-chain.pem"
container_trust_file="/mount/config/app/latest/backend/tls/mcp-trust-chain.pem"

[[ -f "${source_env}" ]] || {
  printf 'ERROR: Agent Factory source_env.sh is missing: %s\n' "${source_env}" >&2
  exit 1
}

install -d -m 0700 "${tls_dir}"
cat "${remote_tmp}/server.crt" "${remote_tmp}/ca.crt" >"${trust_file}"
chmod 0600 "${trust_file}"

if [[ ! -f "${source_env}.pre-mcp-tls" ]]; then
  cp -p "${source_env}" "${source_env}.pre-mcp-tls"
fi

if grep -q '^export SSL_CERTIFICATE_FILE=' "${source_env}"; then
  sed -i \
    "s|^export SSL_CERTIFICATE_FILE=.*|export SSL_CERTIFICATE_FILE=${container_trust_file}|" \
    "${source_env}"
else
  printf 'export SSL_CERTIFICATE_FILE=%s\n' "${container_trust_file}" >>"${source_env}"
fi

openssl verify -CAfile "${remote_tmp}/ca.crt" "${remote_tmp}/server.crt"
rm -rf "${remote_tmp}"

make -C "${install_dir}" stop
make -C "${install_dir}" start

for attempt in {1..60}; do
  if curl --insecure --fail --silent \
    "https://127.0.0.1:${agent_factory_port}/agentFactory/" >/dev/null; then
    break
  fi
  sleep 5
done

curl --insecure --fail --silent \
  "https://127.0.0.1:${agent_factory_port}/agentFactory/" >/dev/null
podman exec oracle-applied-ai-label \
  test -r "${container_trust_file}"
podman exec oracle-applied-ai-label \
  curl --fail --silent --show-error \
  --cacert "${container_trust_file}" \
  "https://${host}:${port}/healthz"
REMOTE

printf '\nInstalled the MCP private CA trust chain and restarted Agent Factory.\n'
