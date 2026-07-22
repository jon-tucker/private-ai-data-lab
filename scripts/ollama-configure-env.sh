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

append_default OLLAMA_ACCELERATOR rocm
append_default OLLAMA_ROCM_IMAGE ollama/ollama:0.32.0-rocm
append_default OLLAMA_CPU_IMAGE ollama/ollama:0.32.0
append_default OLLAMA_CONTAINER oracle-ai-ollama
append_default OLLAMA_HOST_BIND 127.0.0.1
append_default OLLAMA_IGPU_ENABLE 1
append_default OLLAMA_CPUS 8.0
append_default OLLAMA_MEMORY 12g
append_default OLLAMA_CONTEXT_LENGTH 8192
append_default OLLAMA_KEEP_ALIVE 10m
append_default OLLAMA_DEFAULT_MODEL qwen3:4b-instruct
