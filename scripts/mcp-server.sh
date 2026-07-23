#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

case "${MCP_RESTRICT_LEVEL}" in
  4)
    compose --profile mcp run --rm -T mcp -mcp
    ;;
  0|1|2|3)
    compose --profile mcp run --rm -T mcp -R "${MCP_RESTRICT_LEVEL}" -mcp
    ;;
  *)
    die 'MCP_RESTRICT_LEVEL must be an integer from 0 through 4'
    ;;
esac
