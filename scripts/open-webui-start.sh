#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/open-webui-validate.sh"
"${PROJECT_ROOT}/scripts/ollama-start.sh"
compose --profile "${OLLAMA_ACCELERATOR}" up -d open-webui

printf 'Waiting for %s to become healthy' "${OPEN_WEBUI_CONTAINER}"
deadline=$((SECONDS + 900))
status=''
while (( SECONDS < deadline )); do
  status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${OPEN_WEBUI_CONTAINER}" 2>/dev/null || true)"
  case "${status}" in
    healthy)
      printf ' healthy.\n'
      break
      ;;
    unhealthy|exited|dead)
      printf '\n'
      docker logs --tail 150 "${OPEN_WEBUI_CONTAINER}" >&2 || true
      die "Open WebUI container entered state: ${status}"
      ;;
    *)
      printf '.'
      sleep 3
      ;;
  esac
done
[[ "${status}" == 'healthy' ]] || die 'Timed out waiting for Open WebUI to become healthy'
printf 'Open WebUI is ready at %s.\n' "${OPEN_WEBUI_URL}"
