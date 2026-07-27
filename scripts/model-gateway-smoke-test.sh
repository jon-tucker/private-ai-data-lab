#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command curl
require_command jq

key="$(<"${LITELLM_MASTER_KEY_FILE}")"
base_url="http://${LITELLM_HOST_BIND}:${LITELLM_PORT}"

models="$(
  curl --fail --silent --show-error \
    --header "Authorization: Bearer ${key}" \
    "${base_url}/v1/models"
)"
jq -e --arg model "${LITELLM_MODEL_ALIAS}" \
  '.data | any(.id == $model)' <<<"${models}" >/dev/null ||
  die "Model alias not published: ${LITELLM_MODEL_ALIAS}"

response="$(
  curl --fail --silent --show-error \
    --header "Authorization: Bearer ${key}" \
    --header 'Content-Type: application/json' \
    --data "$(jq -nc --arg model "${LITELLM_MODEL_ALIAS}" '{
      model: $model,
      messages: [{role: "user", content: "Reply with exactly: MODEL_GATEWAY_OK"}],
      temperature: 0
    }')" \
    "${base_url}/v1/chat/completions"
)"

content="$(jq -r '.choices[0].message.content // empty' <<<"${response}")"
[[ "${content}" == *MODEL_GATEWAY_OK* ]] ||
  die "Unexpected LiteLLM response: ${content:-empty}"
printf 'LiteLLM model gateway returned MODEL_GATEWAY_OK.\n'
