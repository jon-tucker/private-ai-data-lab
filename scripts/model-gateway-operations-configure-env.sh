#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
[[ -f "${ENV_FILE}" ]] || die "Missing ${ENV_FILE}; copy .env.example to .env first"

append_default() {
  local key="$1" value="$2"
  if ! grep -q "^${key}=" "${ENV_FILE}"; then
    printf '%s=%s\n' "${key}" "${value}" >>"${ENV_FILE}"
    printf 'Added %s to .env\n' "${key}"
  fi
}

append_default LITELLM_TLS_IMAGE nginx:1.30.4-alpine3.24
append_default LITELLM_TLS_CONTAINER oracle-ai-litellm-tls
append_default LITELLM_TLS_DIR /srv/oracle-ai-secrets/litellm-tls
append_default LITELLM_NGINX_CONFIG /srv/oracle-ai-data/litellm/nginx.conf
append_default LITELLM_HTTPS_HOST_BIND 192.168.122.1
append_default LITELLM_HTTPS_PORT 4001
append_default AGENT_FACTORY_LITELLM_HTTPS_URL https://192.168.122.1:4001/v1
