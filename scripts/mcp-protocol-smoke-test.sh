#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/mcp-validate.sh"

export MCP_TEST_SERVER="${PROJECT_ROOT}/scripts/mcp-server.sh"
export MCP_TEST_MODEL="${MCP_TEST_MODEL:-gpt-5}"

exec python3 "${PROJECT_ROOT}/scripts/mcp-protocol-smoke-test.py"
