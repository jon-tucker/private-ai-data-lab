#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/model-gateway-operations-validate.sh"
compose --profile model-gateway up -d litellm litellm-tls

printf 'Waiting for %s to become healthy' "${LITELLM_TLS_CONTAINER}"
deadline=$((SECONDS + 300))
status=''
while ((SECONDS < deadline)); do
  status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${LITELLM_TLS_CONTAINER}" 2>/dev/null || true)"
  case "${status}" in
    healthy)
      printf ' healthy.\n'
      break
      ;;
    unhealthy|exited|dead)
      printf '\n'
      docker logs --tail 150 "${LITELLM_TLS_CONTAINER}" >&2 || true
      die "LiteLLM TLS proxy entered state: ${status}"
      ;;
    *)
      printf '.'
      sleep 3
      ;;
  esac
done
[[ "${status}" == 'healthy' ]] || die 'Timed out waiting for LiteLLM TLS proxy'
printf 'LiteLLM HTTPS is ready at %s.\n' "${AGENT_FACTORY_LITELLM_HTTPS_URL}"
