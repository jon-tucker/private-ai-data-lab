#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command docker
require_command openssl
docker info >/dev/null

"${PROJECT_ROOT}/scripts/mcp-validate.sh"

[[ "${MCP_RESTRICT_LEVEL}" == '4' ]] ||
  die 'The Agent Factory HTTPS bridge requires MCP_RESTRICT_LEVEL=4'
[[ "${MCP_HTTPS_HOST_BIND}" =~ ^[0-9a-fA-F:.]+$ ]] ||
  die 'MCP_HTTPS_HOST_BIND must be an IP address'
[[ "${MCP_HTTPS_PORT}" =~ ^[0-9]+$ ]] &&
  (( MCP_HTTPS_PORT >= 1 && MCP_HTTPS_PORT <= 65535 )) ||
  die 'MCP_HTTPS_PORT must be an integer from 1 through 65535'
[[ "${MCP_HTTP_SESSION_TIMEOUT_MS}" =~ ^[0-9]+$ ]] ||
  die 'MCP_HTTP_SESSION_TIMEOUT_MS must be a positive integer'

[[ -d "${MCP_TLS_DIR}" ]] ||
  die 'MCP TLS directory is missing; run mcp-http-create-tls.sh'
[[ "$(stat -c '%a' "${MCP_TLS_DIR}")" == '700' ]] ||
  die 'MCP TLS directory must have mode 0700'
for file in ca.crt server.crt server.key; do
  [[ -r "${MCP_TLS_DIR}/${file}" ]] ||
    die "Missing or unreadable MCP TLS file: ${MCP_TLS_DIR}/${file}"
done
[[ "$(stat -c '%a' "${MCP_TLS_DIR}/server.key")" == '600' ]] ||
  die 'MCP TLS server key must have mode 0600'
[[ -r "${MCP_NGINX_CONFIG}" ]] ||
  die 'Rendered MCP Nginx configuration is missing; run mcp-http-prepare-host.sh'

openssl verify \
  -CAfile "${MCP_TLS_DIR}/ca.crt" \
  "${MCP_TLS_DIR}/server.crt" >/dev/null

compose --profile mcp-http config --quiet
compose --profile mcp-http run --rm --no-deps \
  --entrypoint nginx \
  mcp-tls -t >/dev/null
printf 'SQLcl MCP HTTPS bridge configuration validation passed.\n'
