#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/livestack-smoke-test.sh"
"${PROJECT_ROOT}/scripts/livestack-edge-validate.sh"
compose --profile livestack --profile livestack-edge up -d livestack livestack-edge

for attempt in {1..60}; do
  state="$(docker inspect --format '{{.State.Status}}' "${LIVESTACK_EDGE_CONTAINER}" 2>/dev/null || true)"
  health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "${LIVESTACK_EDGE_CONTAINER}" 2>/dev/null || true)"
  if [[ "${state}" == 'running' && "${health}" == 'healthy' ]]; then
    printf 'LiveStack edge is healthy.\n'
    break
  fi
  if [[ "${state}" == 'exited' || "${state}" == 'dead' ]]; then
    die "LiveStack edge stopped before becoming healthy; state=${state}"
  fi
  if ((attempt == 60)); then
    die "LiveStack edge did not become healthy; state=${state:-missing} health=${health:-missing}"
  fi
  sleep 2
done

"${PROJECT_ROOT}/scripts/livestack-edge-smoke-test.sh"
