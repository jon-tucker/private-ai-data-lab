#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command docker
require_command openssl

[[ "${LITELLM_HTTPS_HOST_BIND}" == '192.168.122.1' ]] ||
  die 'LiteLLM HTTPS must bind only to 192.168.122.1'
[[ -s "${LITELLM_NGINX_CONFIG}" ]] ||
  die 'TLS proxy config is missing; run model-gateway-operations-prepare-host.sh'
[[ -s "${LITELLM_TLS_DIR}/ca.crt" ]] ||
  die 'LiteLLM CA is missing; run model-gateway-operations-create-tls.sh'
[[ -s "${LITELLM_TLS_DIR}/server.crt" ]] || die 'LiteLLM server certificate is missing'
[[ -s "${LITELLM_TLS_DIR}/server.key" ]] || die 'LiteLLM server key is missing'
[[ "$(stat -c '%a' "${LITELLM_TLS_DIR}/server.key")" == '600' ]] ||
  die 'LiteLLM server key must have mode 0600'
openssl verify \
  -CAfile "${LITELLM_TLS_DIR}/ca.crt" \
  "${LITELLM_TLS_DIR}/server.crt" >/dev/null
openssl x509 -checkip 192.168.122.1 \
  -noout -in "${LITELLM_TLS_DIR}/server.crt" >/dev/null
grep -Fq 'allow 192.168.122.202;' "${LITELLM_NGINX_CONFIG}" ||
  die 'Agent Factory IP is not allowed by the TLS proxy'
backend_gateway="$(
  docker network inspect "${BACKEND_NETWORK:-oracle-ai-backend}" \
    --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}'
)"
[[ -n "${backend_gateway}" ]] ||
  die 'Could not determine the backend Docker network gateway'
grep -Fq "allow ${backend_gateway};" "${LITELLM_NGINX_CONFIG}" ||
  die 'Backend Docker gateway is not allowed by the TLS proxy'
grep -Fq 'deny all;' "${LITELLM_NGINX_CONFIG}" ||
  die 'TLS proxy deny-all rule is missing'
compose --profile model-gateway config --quiet
printf 'Model gateway operations configuration validation passed.\n'
