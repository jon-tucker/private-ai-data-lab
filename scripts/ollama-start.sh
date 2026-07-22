#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/ollama-validate.sh"

service="ollama-${OLLAMA_ACCELERATOR}"
compose --profile "${OLLAMA_ACCELERATOR}" up -d "${service}"

printf 'Waiting for %s to become healthy' "${OLLAMA_CONTAINER}"
deadline=$((SECONDS + 600))
status=''
while (( SECONDS < deadline )); do
  status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${OLLAMA_CONTAINER}" 2>/dev/null || true)"
  case "${status}" in
    healthy)
      printf ' healthy.\n'
      break
      ;;
    unhealthy|exited|dead)
      printf '\n'
      docker logs --tail 100 "${OLLAMA_CONTAINER}" >&2 || true
      die "Ollama container entered state: ${status}"
      ;;
    *)
      printf '.'
      sleep 3
      ;;
  esac
done
[[ "${status}" == 'healthy' ]] || die 'Timed out waiting for Ollama to become healthy'
printf 'Ollama is ready using the %s profile on host port %s.\n' "${OLLAMA_ACCELERATOR}" "${OLLAMA_PORT:-11434}"
