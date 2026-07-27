#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command openssl

if [[ -e "${LITELLM_TLS_DIR}" ]]; then
  die "TLS directory already exists: ${LITELLM_TLS_DIR}"
fi

umask 077
mkdir -p "${LITELLM_TLS_DIR}"

openssl genrsa -out "${LITELLM_TLS_DIR}/ca.key" 4096
openssl req -x509 -new -sha256 -days 1825 \
  -key "${LITELLM_TLS_DIR}/ca.key" \
  -out "${LITELLM_TLS_DIR}/ca.crt" \
  -subj '/CN=Oracle AI LiteLLM Private CA'

openssl genrsa -out "${LITELLM_TLS_DIR}/server.key" 3072
openssl req -new -sha256 \
  -key "${LITELLM_TLS_DIR}/server.key" \
  -out "${LITELLM_TLS_DIR}/server.csr" \
  -subj '/CN=192.168.122.1'

cat >"${LITELLM_TLS_DIR}/server.ext" <<'EOF'
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=IP:192.168.122.1,DNS:litellm-tls
EOF

openssl x509 -req -sha256 -days 825 \
  -in "${LITELLM_TLS_DIR}/server.csr" \
  -CA "${LITELLM_TLS_DIR}/ca.crt" \
  -CAkey "${LITELLM_TLS_DIR}/ca.key" \
  -CAcreateserial \
  -extfile "${LITELLM_TLS_DIR}/server.ext" \
  -out "${LITELLM_TLS_DIR}/server.crt"

chmod 600 "${LITELLM_TLS_DIR}/ca.key" "${LITELLM_TLS_DIR}/server.key"
chmod 644 "${LITELLM_TLS_DIR}/ca.crt" "${LITELLM_TLS_DIR}/server.crt"
openssl verify -CAfile "${LITELLM_TLS_DIR}/ca.crt" "${LITELLM_TLS_DIR}/server.crt"
printf 'Created private LiteLLM TLS material in %s.\n' "${LITELLM_TLS_DIR}"
