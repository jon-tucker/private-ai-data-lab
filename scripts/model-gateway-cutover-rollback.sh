#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

docker compose \
  --project-directory "${PROJECT_ROOT}" \
  --env-file "${ENV_FILE}" \
  -f "${PROJECT_ROOT}/compose.yaml" \
  -f "${PROJECT_ROOT}/stacks/litellm/compose.http-rollback.yaml" \
  --profile model-gateway \
  up -d --force-recreate litellm litellm-tls

printf 'Waiting for %s to become healthy' "${LITELLM_CONTAINER}"
deadline=$((SECONDS + 300))
status=''
while ((SECONDS < deadline)); do
  status="$(
    docker inspect \
      --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
      "${LITELLM_CONTAINER}" 2>/dev/null || true
  )"
  [[ "${status}" == 'healthy' ]] && {
    printf ' healthy.\n'
    break
  }
  printf '.'
  sleep 3
done
[[ "${status}" == 'healthy' ]] ||
  die 'Timed out waiting for the LiteLLM rollback endpoint'

"${PROJECT_ROOT}/scripts/model-gateway-smoke-test.sh"
printf 'Rollback enabled: LiteLLM HTTP is again published on port %s.\n' "${LITELLM_PORT}"
