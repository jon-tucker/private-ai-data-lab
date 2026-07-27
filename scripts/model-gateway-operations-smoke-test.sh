#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command curl
require_command jq

key="$(<"${LITELLM_MASTER_KEY_FILE}")"
response="$(
  curl --fail --silent --show-error \
    --cacert "${LITELLM_TLS_DIR}/ca.crt" \
    --header "Authorization: Bearer ${key}" \
    --header 'Content-Type: application/json' \
    --data "$(jq -nc --arg model "${LITELLM_MODEL_ALIAS}" '{
      model: $model,
      messages: [{role: "user", content: "Reply with exactly: MODEL_GATEWAY_TLS_OK"}],
      temperature: 0
    }')" \
    "https://${LITELLM_HTTPS_HOST_BIND}:${LITELLM_HTTPS_PORT}/v1/chat/completions"
)"
content="$(jq -r '.choices[0].message.content // empty' <<<"${response}")"
[[ "${content}" == *MODEL_GATEWAY_TLS_OK* ]] ||
  die "Unexpected HTTPS gateway response: ${content:-empty}"
printf 'Authenticated LiteLLM HTTPS returned MODEL_GATEWAY_TLS_OK.\n'
