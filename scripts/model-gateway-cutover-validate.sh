#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command jq

"${PROJECT_ROOT}/scripts/model-gateway-operations-validate.sh"

resolved="$(
  compose --profile model-gateway config --format json
)"

http_publish_count="$(
  jq -r '.services.litellm.ports // [] | length' <<<"${resolved}"
)"
[[ "${http_publish_count}" == '0' ]] ||
  die 'The normal LiteLLM service still publishes its HTTP port'

https_publish_count="$(
  jq -r \
    --arg port "${LITELLM_HTTPS_PORT}" \
    '[.services["litellm-tls"].ports[]? | select((.published | tostring) == $port)] | length' \
    <<<"${resolved}"
)"
[[ "${https_publish_count}" == '1' ]] ||
  die 'The LiteLLM HTTPS proxy is not published on the configured port'

printf 'Model gateway cutover configuration validation passed.\n'
