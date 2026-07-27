#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/model-gateway-validate.sh"
"${PROJECT_ROOT}/scripts/ollama-start.sh"
compose --profile model-gateway up -d litellm

printf 'Waiting for %s to become healthy' "${LITELLM_CONTAINER}"
deadline=$((SECONDS + 900))
status=''
while ((SECONDS < deadline)); do
  status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${LITELLM_CONTAINER}" 2>/dev/null || true)"
  case "${status}" in
    healthy)
      printf ' healthy.\n'
      break
      ;;
    unhealthy|exited|dead)
      printf '\n'
      docker logs --tail 150 "${LITELLM_CONTAINER}" >&2 || true
      die "LiteLLM container entered state: ${status}"
      ;;
    *)
      printf '.'
      sleep 3
      ;;
  esac
done
[[ "${status}" == 'healthy' ]] || die 'Timed out waiting for LiteLLM to become healthy'
printf 'LiteLLM is ready at http://%s:%s/v1.\n' "${LITELLM_HOST_BIND}" "${LITELLM_PORT}"
