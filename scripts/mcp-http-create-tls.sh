#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command openssl

mkdir -p "${MCP_TLS_DIR}"
chmod 0700 "${MCP_TLS_DIR}"

for file in ca.key ca.crt server.key server.crt; do
  [[ ! -e "${MCP_TLS_DIR}/${file}" ]] ||
    die "Refusing to overwrite existing TLS material: ${MCP_TLS_DIR}/${file}"
done

openssl genrsa -out "${MCP_TLS_DIR}/ca.key" 4096
openssl req -x509 -new -sha256 -days 3650 \
  -key "${MCP_TLS_DIR}/ca.key" \
  -subj '/CN=Oracle AI private MCP CA' \
  -out "${MCP_TLS_DIR}/ca.crt"

openssl genrsa -out "${MCP_TLS_DIR}/server.key" 3072
openssl req -new -sha256 \
  -key "${MCP_TLS_DIR}/server.key" \
  -subj "/CN=${MCP_HTTPS_HOST_BIND}" \
  -addext "subjectAltName=IP:${MCP_HTTPS_HOST_BIND}" \
  -out "${MCP_TLS_DIR}/server.csr"

openssl x509 -req -sha256 -days 825 \
  -in "${MCP_TLS_DIR}/server.csr" \
  -CA "${MCP_TLS_DIR}/ca.crt" \
  -CAkey "${MCP_TLS_DIR}/ca.key" \
  -CAcreateserial \
  -extfile <(printf 'subjectAltName=IP:%s\nextendedKeyUsage=serverAuth\n' "${MCP_HTTPS_HOST_BIND}") \
  -out "${MCP_TLS_DIR}/server.crt"

rm "${MCP_TLS_DIR}/server.csr" "${MCP_TLS_DIR}/ca.srl"
chmod 0600 "${MCP_TLS_DIR}/ca.key" "${MCP_TLS_DIR}/server.key"
chmod 0644 "${MCP_TLS_DIR}/ca.crt" "${MCP_TLS_DIR}/server.crt"

openssl verify -CAfile "${MCP_TLS_DIR}/ca.crt" "${MCP_TLS_DIR}/server.crt"
printf 'Created private MCP TLS material in %s.\n' "${MCP_TLS_DIR}"
