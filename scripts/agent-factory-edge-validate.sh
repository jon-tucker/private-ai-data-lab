#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command docker
[[ -s "${AGENT_FACTORY_EDGE_TLS_DIR}/ca.crt" ]] || die 'Missing edge CA'
[[ -s "${AGENT_FACTORY_EDGE_TLS_DIR}/server.crt" ]] || die 'Missing edge certificate'
[[ -s "${AGENT_FACTORY_EDGE_TLS_DIR}/server.key" ]] || die 'Missing edge key'
[[ -s "${AGENT_FACTORY_EDGE_DATA_DIR}/upstream.crt" ]] || die 'Missing Agent Factory upstream certificate'
[[ -s "${AGENT_FACTORY_EDGE_DATA_DIR}/nginx.conf" ]] || die 'Missing rendered Nginx configuration'
docker run --rm \
  --user "${PLATFORM_UID}:${PLATFORM_GID}" \
  --network "${BACKEND_NETWORK:-oracle-ai-backend}" \
  -v "${AGENT_FACTORY_EDGE_DATA_DIR}/nginx.conf:/etc/nginx/nginx.conf:ro" \
  -v "${AGENT_FACTORY_EDGE_TLS_DIR}:/etc/nginx/tls:ro" \
  -v "${AGENT_FACTORY_EDGE_DATA_DIR}/upstream.crt:/etc/nginx/upstream/upstream.crt:ro" \
  --tmpfs /tmp:rw,nosuid,nodev,noexec,mode=1777 \
  --cap-drop ALL --security-opt no-new-privileges:true \
  "${AGENT_FACTORY_EDGE_IMAGE}" nginx -t
printf 'Agent Factory edge configuration validation passed.\n'
