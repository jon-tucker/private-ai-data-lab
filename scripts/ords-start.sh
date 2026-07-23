#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/ords-validate.sh"

find "${ORDS_CONFIG_DIR}/databases" -name pool.xml -print -quit 2>/dev/null | grep -q . ||
  die 'ORDS is not installed; run ords-install.sh first'

"${PROJECT_ROOT}/scripts/oracle-start.sh"
compose up -d ords

printf 'Waiting for %s to become healthy' "${ORDS_CONTAINER}"
deadline=$((SECONDS + 600))
status=''
while (( SECONDS < deadline )); do
  status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${ORDS_CONTAINER}" 2>/dev/null || true)"
  case "${status}" in
    healthy)
      printf ' healthy.\n'
      break
      ;;
    unhealthy|exited|dead)
      printf '\n'
      docker logs --tail 150 "${ORDS_CONTAINER}" >&2 || true
      die "ORDS container entered state: ${status}"
      ;;
    *)
      printf '.'
      sleep 3
      ;;
  esac
done
[[ "${status}" == healthy ]] || die 'Timed out waiting for ORDS to become healthy'
printf 'ORDS is ready at %s\n' "${ORDS_URL}"
