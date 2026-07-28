#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

require_command docker
require_command openssl

apply=false
if [[ "${1:-}" == '--apply' ]]; then
  apply=true
elif [[ -n "${1:-}" ]]; then
  die "Usage: $0 [--apply]"
fi

install -d -m 700 "${AGENT_FACTORY_EDGE_TLS_DIR}"
next_prefix="${AGENT_FACTORY_EDGE_TLS_DIR}/server.next"

printf 'subjectAltName=DNS:%s,DNS:%s,IP:%s\n' \
  "${AGENT_FACTORY_EDGE_SERVER_NAME}" "${PLATFORM_HOSTNAME:-oracle-ai}" \
  "${AGENT_FACTORY_EDGE_HOST_BIND}" \
  >"${next_prefix}.ext"

openssl req -newkey rsa:3072 -nodes \
  -subj "/CN=${AGENT_FACTORY_EDGE_SERVER_NAME}" \
  -keyout "${next_prefix}.key" \
  -out "${next_prefix}.csr"

openssl x509 -req -days 825 \
  -in "${next_prefix}.csr" \
  -CA "${AGENT_FACTORY_EDGE_TLS_DIR}/ca.crt" \
  -CAkey "${AGENT_FACTORY_EDGE_TLS_DIR}/ca.key" \
  -CAcreateserial \
  -extfile "${next_prefix}.ext" \
  -out "${next_prefix}.crt"

chmod 600 "${next_prefix}.key" "${next_prefix}.csr" "${next_prefix}.ext"
chmod 644 "${next_prefix}.crt"
openssl verify -CAfile "${AGENT_FACTORY_EDGE_TLS_DIR}/ca.crt" "${next_prefix}.crt"
openssl x509 -in "${next_prefix}.crt" -noout -subject -issuer -dates -ext subjectAltName

if [[ "${apply}" != true ]]; then
  printf 'Staged replacement certificate at %s.*; active edge was not changed.\n' "${next_prefix}"
  exit 0
fi

archive_dir="${AGENT_FACTORY_EDGE_TLS_DIR}/archive/$(date -u +%Y%m%dT%H%M%SZ)"
install -d -m 700 "${archive_dir}"
for suffix in key csr ext crt; do
  [[ -f "${AGENT_FACTORY_EDGE_TLS_DIR}/server.${suffix}" ]] || continue
  mode=600
  [[ "${suffix}" == 'crt' ]] && mode=644
  install -m "${mode}" \
    "${AGENT_FACTORY_EDGE_TLS_DIR}/server.${suffix}" \
    "${archive_dir}/server.${suffix}"
done

install -m 600 "${next_prefix}.key" "${AGENT_FACTORY_EDGE_TLS_DIR}/server.key"
install -m 600 "${next_prefix}.csr" "${AGENT_FACTORY_EDGE_TLS_DIR}/server.csr"
install -m 600 "${next_prefix}.ext" "${AGENT_FACTORY_EDGE_TLS_DIR}/server.ext"
install -m 644 "${next_prefix}.crt" "${AGENT_FACTORY_EDGE_TLS_DIR}/server.crt"

"$(dirname "${BASH_SOURCE[0]}")/agent-factory-edge-prepare-host.sh"
"$(dirname "${BASH_SOURCE[0]}")/agent-factory-edge-validate.sh"
docker compose --profile agent-factory-edge up -d --force-recreate agent-factory-edge
"$(dirname "${BASH_SOURCE[0]}")/agent-factory-edge-smoke-test.sh"
printf 'Applied the replacement certificate; previous material is in %s.\n' "${archive_dir}"
