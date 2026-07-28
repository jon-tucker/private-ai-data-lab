#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command openssl

install -d -m 700 "${AGENT_FACTORY_EDGE_TLS_DIR}"
if [[ -e "${AGENT_FACTORY_EDGE_TLS_DIR}/ca.key" ||
      -e "${AGENT_FACTORY_EDGE_TLS_DIR}/server.key" ]]; then
  die "TLS keys already exist in ${AGENT_FACTORY_EDGE_TLS_DIR}; refusing to overwrite them"
fi
openssl req -x509 -newkey rsa:3072 -nodes -days 1825 \
  -subj '/CN=Oracle AI Agent Factory Edge CA' \
  -keyout "${AGENT_FACTORY_EDGE_TLS_DIR}/ca.key" \
  -out "${AGENT_FACTORY_EDGE_TLS_DIR}/ca.crt"
openssl req -newkey rsa:3072 -nodes \
  -subj "/CN=${AGENT_FACTORY_EDGE_SERVER_NAME}" \
  -keyout "${AGENT_FACTORY_EDGE_TLS_DIR}/server.key" \
  -out "${AGENT_FACTORY_EDGE_TLS_DIR}/server.csr"
printf 'subjectAltName=DNS:%s,DNS:%s,IP:%s\n' \
  "${AGENT_FACTORY_EDGE_SERVER_NAME}" "${PLATFORM_HOSTNAME:-oracle-ai}" \
  "${AGENT_FACTORY_EDGE_HOST_BIND}" \
  >"${AGENT_FACTORY_EDGE_TLS_DIR}/server.ext"
openssl x509 -req -days 825 \
  -in "${AGENT_FACTORY_EDGE_TLS_DIR}/server.csr" \
  -CA "${AGENT_FACTORY_EDGE_TLS_DIR}/ca.crt" \
  -CAkey "${AGENT_FACTORY_EDGE_TLS_DIR}/ca.key" -CAcreateserial \
  -extfile "${AGENT_FACTORY_EDGE_TLS_DIR}/server.ext" \
  -out "${AGENT_FACTORY_EDGE_TLS_DIR}/server.crt"
chmod 600 "${AGENT_FACTORY_EDGE_TLS_DIR}"/*.key
chmod 644 "${AGENT_FACTORY_EDGE_TLS_DIR}"/*.crt
printf 'Created Agent Factory edge TLS material in %s.\n' "${AGENT_FACTORY_EDGE_TLS_DIR}"
