#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command docker

[[ "${LITELLM_HOST_BIND}" == '192.168.122.1' ]] ||
  die 'LiteLLM must bind only to the libvirt host bridge at 192.168.122.1'
[[ "${LITELLM_PORT}" =~ ^[0-9]+$ ]] || die 'LITELLM_PORT must be numeric'
[[ -s "${LITELLM_CONFIG}" ]] ||
  die 'LiteLLM config is missing; run model-gateway-prepare-host.sh'
[[ "$(stat -c '%a' "${LITELLM_CONFIG}")" == '600' ]] ||
  die 'LiteLLM config must have mode 0600'
[[ -s "${LITELLM_MASTER_KEY_FILE}" ]] ||
  die 'LiteLLM key is missing; run model-gateway-create-secret.sh'
[[ "$(stat -c '%a' "${LITELLM_MASTER_KEY_FILE}")" == '600' ]] ||
  die 'LiteLLM key must have mode 0600'
grep -Fq "model_name: ${LITELLM_MODEL_ALIAS}" "${LITELLM_CONFIG}" ||
  die 'LiteLLM model alias is absent from the rendered config'
grep -Fq "model: ollama/${LITELLM_OLLAMA_MODEL}" "${LITELLM_CONFIG}" ||
  die 'LiteLLM Ollama model is absent from the rendered config'

docker info >/dev/null
compose --profile model-gateway config --quiet
printf 'Model gateway configuration validation passed.\n'
