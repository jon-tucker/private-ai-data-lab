#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

[[ "${LIVESTACK_HOST_BIND}" == '127.0.0.1' ]] ||
  die 'LiveStack must remain published on loopback only'
install -d -m 700 "${LIVESTACK_EDGE_DATA_DIR}"
sed \
  -e "s|__SERVER_NAME__|${LIVESTACK_EDGE_SERVER_NAME}|g" \
  -e "s|__HOST_BIND__|${LIVESTACK_EDGE_HOST_BIND}|g" \
  -e "s|__ALLOWED_CIDR__|${LIVESTACK_EDGE_ALLOWED_CIDR}|g" \
  -e "s|__EDGE_PORT__|${LIVESTACK_EDGE_PORT}|g" \
  "${PROJECT_ROOT}/stacks/livestack-edge/nginx.conf.template" \
  >"${LIVESTACK_EDGE_DATA_DIR}/nginx.conf"
printf 'Rendered LiveStack edge configuration: %s/nginx.conf\n' "${LIVESTACK_EDGE_DATA_DIR}"
