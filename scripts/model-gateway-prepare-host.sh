#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

config_dir="$(dirname "${LITELLM_CONFIG}")"
template="${PROJECT_ROOT}/stacks/litellm/config.yaml.template"

mkdir -p "${config_dir}"
chmod 700 "${config_dir}"

escape_sed() {
  printf '%s' "$1" | sed 's/[\/&]/\\&/g'
}

sed \
  -e "s/__MODEL_ALIAS__/$(escape_sed "${LITELLM_MODEL_ALIAS}")/g" \
  -e "s/__OLLAMA_MODEL__/$(escape_sed "${LITELLM_OLLAMA_MODEL}")/g" \
  -e "s/__OLLAMA_URL__/$(escape_sed "${LITELLM_OLLAMA_URL}")/g" \
  "${template}" >"${LITELLM_CONFIG}"

chmod 600 "${LITELLM_CONFIG}"
printf 'Rendered LiteLLM configuration: %s\n' "${LITELLM_CONFIG}"
