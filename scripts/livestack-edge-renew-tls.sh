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

install -d -m 700 "${LIVESTACK_EDGE_TLS_DIR}"
[[ -s "${LIVESTACK_EDGE_TLS_DIR}/ca.crt" ]] || die 'Missing LiveStack edge CA'
[[ -s "${LIVESTACK_EDGE_TLS_DIR}/ca.key" ]] || die 'Missing LiveStack edge CA key'
next_prefix="${LIVESTACK_EDGE_TLS_DIR}/server.next"
printf 'subjectAltName=DNS:%s,DNS:%s,IP:%s\n' \
  "${LIVESTACK_EDGE_SERVER_NAME}" "${PLATFORM_HOSTNAME:-oracle-ai}" \
  "${LIVESTACK_EDGE_HOST_BIND}" >"${next_prefix}.ext"
openssl req -newkey rsa:3072 -nodes \
  -subj "/CN=${LIVESTACK_EDGE_SERVER_NAME}" \
  -keyout "${next_prefix}.key" -out "${next_prefix}.csr"
openssl x509 -req -days 825 \
  -in "${next_prefix}.csr" \
  -CA "${LIVESTACK_EDGE_TLS_DIR}/ca.crt" \
  -CAkey "${LIVESTACK_EDGE_TLS_DIR}/ca.key" -CAcreateserial \
  -extfile "${next_prefix}.ext" -out "${next_prefix}.crt"
chmod 600 "${next_prefix}.key" "${next_prefix}.csr" "${next_prefix}.ext"
chmod 644 "${next_prefix}.crt"
openssl verify -CAfile "${LIVESTACK_EDGE_TLS_DIR}/ca.crt" "${next_prefix}.crt"
openssl x509 -in "${next_prefix}.crt" -noout -subject -issuer -dates -ext subjectAltName

if [[ "${apply}" != true ]]; then
  printf 'Staged replacement certificate at %s.*; active edge was not changed.\n' "${next_prefix}"
  exit 0
fi

archive_dir="${LIVESTACK_EDGE_TLS_DIR}/archive/$(date -u +%Y%m%dT%H%M%SZ)"
install -d -m 700 "${archive_dir}"
for suffix in key csr ext crt; do
  [[ -f "${LIVESTACK_EDGE_TLS_DIR}/server.${suffix}" ]] || continue
  mode=600
  [[ "${suffix}" == 'crt' ]] && mode=644
  install -m "${mode}" "${LIVESTACK_EDGE_TLS_DIR}/server.${suffix}" \
    "${archive_dir}/server.${suffix}"
done
install -m 600 "${next_prefix}.key" "${LIVESTACK_EDGE_TLS_DIR}/server.key"
install -m 600 "${next_prefix}.csr" "${LIVESTACK_EDGE_TLS_DIR}/server.csr"
install -m 600 "${next_prefix}.ext" "${LIVESTACK_EDGE_TLS_DIR}/server.ext"
install -m 644 "${next_prefix}.crt" "${LIVESTACK_EDGE_TLS_DIR}/server.crt"
"${PROJECT_ROOT}/scripts/livestack-edge-prepare-host.sh"
"${PROJECT_ROOT}/scripts/livestack-edge-validate.sh"
compose --profile livestack-edge up -d --force-recreate livestack-edge
"${PROJECT_ROOT}/scripts/livestack-edge-smoke-test.sh"
printf 'Applied the replacement certificate; previous material is in %s.\n' "${archive_dir}"
