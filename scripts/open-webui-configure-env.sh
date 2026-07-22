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

append_default OPEN_WEBUI_IMAGE ghcr.io/open-webui/open-webui:v0.10.2
append_default OPEN_WEBUI_CONTAINER oracle-ai-open-webui
append_default OPEN_WEBUI_HOST_BIND 0.0.0.0
append_default OPEN_WEBUI_PORT 3000
append_default OPEN_WEBUI_CPUS 4.0
append_default OPEN_WEBUI_MEMORY 4g
append_default OPEN_WEBUI_SECRET_FILE /srv/oracle-ai-secrets/open-webui-secret-key
append_default OPEN_WEBUI_URL http://192.168.0.209:3000
append_default OPEN_WEBUI_ENABLE_SIGNUP true
append_default OPEN_WEBUI_DEFAULT_MODEL qwen3:4b-instruct
