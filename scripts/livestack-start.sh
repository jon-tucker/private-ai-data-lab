#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

"${PROJECT_ROOT}/scripts/livestack-validate.sh"
"${PROJECT_ROOT}/scripts/livestack-schema-smoke-test.sh"

docker image inspect "${LIVESTACK_IMAGE}" >/dev/null 2>&1 ||
  die "LiveStack image is missing; build it with: docker compose --profile livestack build livestack"

compose --profile livestack up -d --no-build livestack

printf 'Waiting for %s to become healthy' "${LIVESTACK_CONTAINER}"
deadline=$((SECONDS + 180))
status=''
while ((SECONDS < deadline)); do
  status="$(
    docker inspect \
      --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
      "${LIVESTACK_CONTAINER}" 2>/dev/null || true
  )"
  case "${status}" in
    healthy)
      printf ' healthy.\n'
      break
      ;;
    unhealthy|exited|dead)
      printf '\n'
      docker logs --tail 150 "${LIVESTACK_CONTAINER}" >&2 || true
      die "LiveStack container entered state: ${status}"
      ;;
    *)
      printf '.'
      sleep 3
      ;;
  esac
done
[[ "${status}" == "healthy" ]] ||
  die "Timed out waiting for LiveStack; last state=${status:-missing}"

"${PROJECT_ROOT}/scripts/livestack-smoke-test.sh"
