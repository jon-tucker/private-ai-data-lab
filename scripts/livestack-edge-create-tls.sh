#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command openssl

install -d -m 700 "${LIVESTACK_EDGE_TLS_DIR}"
if [[ -e "${LIVESTACK_EDGE_TLS_DIR}/ca.key" ||
      -e "${LIVESTACK_EDGE_TLS_DIR}/server.key" ]]; then
  die "TLS keys already exist in ${LIVESTACK_EDGE_TLS_DIR}; refusing to overwrite them"
fi
openssl req -x509 -newkey rsa:3072 -nodes -days 1825 \
  -subj '/CN=Private AI Data Lab LiveStack Edge CA' \
  -keyout "${LIVESTACK_EDGE_TLS_DIR}/ca.key" \
  -out "${LIVESTACK_EDGE_TLS_DIR}/ca.crt"
openssl req -newkey rsa:3072 -nodes \
  -subj "/CN=${LIVESTACK_EDGE_SERVER_NAME}" \
  -keyout "${LIVESTACK_EDGE_TLS_DIR}/server.key" \
  -out "${LIVESTACK_EDGE_TLS_DIR}/server.csr"
printf 'subjectAltName=DNS:%s,DNS:%s,IP:%s\n' \
  "${LIVESTACK_EDGE_SERVER_NAME}" "${PLATFORM_HOSTNAME:-oracle-ai}" \
  "${LIVESTACK_EDGE_HOST_BIND}" \
  >"${LIVESTACK_EDGE_TLS_DIR}/server.ext"
openssl x509 -req -days 825 \
  -in "${LIVESTACK_EDGE_TLS_DIR}/server.csr" \
  -CA "${LIVESTACK_EDGE_TLS_DIR}/ca.crt" \
  -CAkey "${LIVESTACK_EDGE_TLS_DIR}/ca.key" -CAcreateserial \
  -extfile "${LIVESTACK_EDGE_TLS_DIR}/server.ext" \
  -out "${LIVESTACK_EDGE_TLS_DIR}/server.crt"
chmod 600 "${LIVESTACK_EDGE_TLS_DIR}"/*.key
chmod 644 "${LIVESTACK_EDGE_TLS_DIR}"/*.crt
printf 'Created LiveStack edge TLS material in %s.\n' "${LIVESTACK_EDGE_TLS_DIR}"
