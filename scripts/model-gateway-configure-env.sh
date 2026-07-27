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

append_default LITELLM_IMAGE ghcr.io/berriai/litellm:v1.92.0
append_default LITELLM_CONTAINER oracle-ai-litellm
append_default LITELLM_HOST_BIND 192.168.122.1
append_default LITELLM_PORT 4000
append_default LITELLM_CPUS 2.0
append_default LITELLM_MEMORY 2g
append_default LITELLM_CONFIG /srv/oracle-ai-data/litellm/config.yaml
append_default LITELLM_MASTER_KEY_FILE /srv/oracle-ai-secrets/litellm-master-key
append_default LITELLM_MODEL_ALIAS local-qwen3-4b-instruct
append_default LITELLM_OLLAMA_MODEL qwen3:4b-instruct
append_default LITELLM_OLLAMA_URL http://ollama:11434
append_default AGENT_FACTORY_LITELLM_URL http://192.168.122.1:4000/v1
