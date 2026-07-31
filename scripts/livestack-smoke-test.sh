#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

[[ "${LIVESTACK_HOST_BIND}" == "127.0.0.1" ]] ||
  die "LiveStack smoke test requires loopback-only publication"

published="$(docker port "${LIVESTACK_CONTAINER}" 3001/tcp)"
[[ "${published}" == "127.0.0.1:${LIVESTACK_PORT}" ]] ||
  die "Unexpected LiveStack publication: ${published:-missing}"

health="$(
  curl --fail --silent --show-error --max-time 10 \
    "http://${LIVESTACK_HOST_BIND}:${LIVESTACK_PORT}/api/health"
)"
[[ "${health}" == *'"status":"healthy"'* &&
   "${health}" == *'"STATUS":"connected"'* ]] ||
  die "LiveStack database-backed health response was not healthy"

frontend_status="$(
  curl --fail --silent --show-error --max-time 10 \
    --output /dev/null --write-out '%{http_code}' \
    "http://${LIVESTACK_HOST_BIND}:${LIVESTACK_PORT}/"
)"
[[ "${frontend_status}" == "200" ]] ||
  die "LiveStack frontend returned HTTP ${frontend_status}"

printf 'LiveStack loopback application, database, and frontend smoke test passed.\n'
