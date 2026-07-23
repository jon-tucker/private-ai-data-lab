#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command docker
docker info >/dev/null

[[ "${MCP_RESTRICT_LEVEL}" =~ ^[0-4]$ ]] ||
  die 'MCP_RESTRICT_LEVEL must be an integer from 0 through 4'
[[ "${MCP_DATABASE_USER}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'MCP_DATABASE_USER must be an uppercase simple Oracle identifier'
[[ "${MCP_DATABASE_ROLE}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'MCP_DATABASE_ROLE must be an uppercase simple Oracle identifier'
[[ "${MCP_SOURCE_SCHEMA}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'MCP_SOURCE_SCHEMA must be an uppercase simple Oracle identifier'
[[ "${MCP_CONNECTION_NAME}" =~ ^[A-Za-z][A-Za-z0-9_-]{0,63}$ ]] ||
  die 'MCP_CONNECTION_NAME contains unsupported characters'
[[ -d "${MCP_SQLCL_HOME}" ]] ||
  die 'SQLcl home directory is missing; run mcp-prepare-host.sh'
[[ "$(stat -c '%u:%g' "${MCP_SQLCL_HOME}")" == "${MCP_UID}:${MCP_GID}" ]] ||
  die "SQLcl home must be owned by ${MCP_UID}:${MCP_GID}; run mcp-prepare-host.sh"
[[ "$(stat -c '%a' "${MCP_SQLCL_HOME}")" == '700' ]] ||
  die 'SQLcl home must have mode 0700; run mcp-prepare-host.sh'
[[ -r "${MCP_DATABASE_PASSWORD_FILE}" ]] ||
  die "MCP database password is missing or unreadable: ${MCP_DATABASE_PASSWORD_FILE}"
[[ "$(stat -c '%a' "${MCP_DATABASE_PASSWORD_FILE}")" == '600' ]] ||
  die 'MCP database password must have mode 0600'

compose --profile mcp config --quiet
printf 'SQLcl MCP configuration validation passed at restriction level %s.\n' "${MCP_RESTRICT_LEVEL}"
