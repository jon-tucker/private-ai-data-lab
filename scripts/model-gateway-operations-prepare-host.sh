#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

backend_gateway="$(
  docker network inspect "${BACKEND_NETWORK:-oracle-ai-backend}" \
    --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}'
)"
[[ -n "${backend_gateway}" ]] ||
  die 'Could not determine the backend Docker network gateway'

mkdir -p "$(dirname "${LITELLM_NGINX_CONFIG}")"
install -m 600 \
  "${PROJECT_ROOT}/stacks/litellm/nginx.conf.template" \
  "${LITELLM_NGINX_CONFIG}"
sed -i \
  "s/__BACKEND_GATEWAY__/${backend_gateway}/g" \
  "${LITELLM_NGINX_CONFIG}"
printf 'Rendered LiteLLM TLS proxy configuration: %s\n' "${LITELLM_NGINX_CONFIG}"
