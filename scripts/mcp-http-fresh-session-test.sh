#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command python3

export MCP_SOURCE_SCHEMA MCP_DATABASE_USER
exec python3 "${PROJECT_ROOT}/scripts/mcp-http-fresh-session-test.py" \
  "https://${MCP_HTTPS_HOST_BIND}:${MCP_HTTPS_PORT}/mcp" \
  "${MCP_TLS_DIR}/ca.crt"
