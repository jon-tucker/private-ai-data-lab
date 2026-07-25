#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

compose --profile mcp-http ps mcp-http mcp-tls
for container in "${MCP_HTTP_CONTAINER}" "${MCP_TLS_CONTAINER}"; do
  docker inspect "${container}" \
    --format 'name={{.Name}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} status={{.State.Status}}' \
    2>/dev/null || true
done
