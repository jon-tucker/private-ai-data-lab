#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

health="$(curl --fail --silent --show-error --max-time 15 \
  --cacert "${LIVESTACK_EDGE_TLS_DIR}/ca.crt" \
  "https://${LIVESTACK_EDGE_HOST_BIND}:${LIVESTACK_EDGE_PORT}/api/health")"
[[ "${health}" == *'"status":"healthy"'* ]] || die 'LiveStack edge database health failed'
status="$(curl --fail --silent --show-error --max-time 15 \
  --cacert "${LIVESTACK_EDGE_TLS_DIR}/ca.crt" \
  --output /dev/null --write-out '%{http_code}' \
  "https://${LIVESTACK_EDGE_HOST_BIND}:${LIVESTACK_EDGE_PORT}/")"
[[ "${status}" == '200' ]] || die "LiveStack edge frontend returned HTTP ${status}"
printf 'LiveStack trusted HTTPS edge, database, and frontend smoke test passed.\n'
