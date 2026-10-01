#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command docker
require_command openssl

[[ "${LIVESTACK_HOST_BIND}" == '127.0.0.1' ]] || die 'LiveStack must remain loopback-only'
[[ "${LIVESTACK_EDGE_HOST_BIND}" != '0.0.0.0' ]] || die 'Wildcard edge publication is prohibited'
[[ -s "${LIVESTACK_EDGE_TLS_DIR}/ca.crt" ]] || die 'Missing LiveStack edge CA'
[[ -s "${LIVESTACK_EDGE_TLS_DIR}/server.crt" ]] || die 'Missing LiveStack edge certificate'
[[ -s "${LIVESTACK_EDGE_TLS_DIR}/server.key" ]] || die 'Missing LiveStack edge key'
[[ -s "${LIVESTACK_EDGE_DATA_DIR}/nginx.conf" ]] || die 'Missing rendered Nginx configuration'
openssl verify -CAfile "${LIVESTACK_EDGE_TLS_DIR}/ca.crt" \
  "${LIVESTACK_EDGE_TLS_DIR}/server.crt"
docker run --rm \
  --user "${PLATFORM_UID}:${PLATFORM_GID}" \
  --network "${BACKEND_NETWORK:-oracle-ai-backend}" \
  -v "${LIVESTACK_EDGE_DATA_DIR}/nginx.conf:/etc/nginx/nginx.conf:ro" \
  -v "${LIVESTACK_EDGE_TLS_DIR}:/etc/nginx/tls:ro" \
  --tmpfs /tmp:rw,nosuid,nodev,noexec,mode=1777 \
  --cap-drop ALL --security-opt no-new-privileges:true \
  "${LIVESTACK_EDGE_IMAGE}" nginx -t
printf 'LiveStack edge configuration validation passed.\n'
