#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command scp

install -d -m 700 "${AGENT_FACTORY_EDGE_DATA_DIR}"
scp -q "${AGENT_FACTORY_VM_USER}@${AGENT_FACTORY_VM_IP}:${AGENT_FACTORY_INSTALL_DIR}/applied-ai/volume/config/app/latest/certs/cert.pem" \
  "${AGENT_FACTORY_EDGE_DATA_DIR}/upstream.crt"

sed \
  -e "s|__SERVER_NAME__|${AGENT_FACTORY_EDGE_SERVER_NAME}|g" \
  -e "s|__HOST_BIND__|${AGENT_FACTORY_EDGE_HOST_BIND}|g" \
  -e "s|__ALLOWED_CIDR__|${AGENT_FACTORY_EDGE_ALLOWED_CIDR}|g" \
  -e "s|__UPSTREAM_IP__|${AGENT_FACTORY_VM_IP}|g" \
  -e "s|__UPSTREAM_PORT__|${AGENT_FACTORY_PORT}|g" \
  -e "s|__EDGE_PORT__|${AGENT_FACTORY_EDGE_PORT}|g" \
  "${PROJECT_ROOT}/stacks/agent-factory-edge/nginx.conf.template" \
  >"${AGENT_FACTORY_EDGE_DATA_DIR}/nginx.conf"
printf 'Rendered Agent Factory edge configuration: %s/nginx.conf\n' "${AGENT_FACTORY_EDGE_DATA_DIR}"
