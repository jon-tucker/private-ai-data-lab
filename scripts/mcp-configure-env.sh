#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[[ -f "${ENV_FILE}" ]] || cp "${PROJECT_ROOT}/.env.example" "${ENV_FILE}"

append_default() {
  local key="$1" value="$2"
  if ! grep -q "^${key}=" "${ENV_FILE}"; then
    printf '%s=%s\n' "${key}" "${value}" >>"${ENV_FILE}"
    printf 'Added %s to .env\n' "${key}"
  fi
}

append_default MCP_SQLCL_IMAGE container-registry.oracle.com/database/sqlcl:26.2.0
append_default MCP_SQLCL_HOME /srv/oracle-ai-data/mcp/sqlcl-home
append_default MCP_DATABASE_PASSWORD_FILE /srv/oracle-ai-secrets/mcp-database-password
append_default MCP_DATABASE_USER ORACLE_AI_MCP
append_default MCP_DATABASE_ROLE ORACLE_AI_MCP_READ_ROLE
append_default MCP_CONNECTION_NAME oracle_ai_readonly
append_default MCP_SOURCE_SCHEMA ORACLE_AI
append_default MCP_RESTRICT_LEVEL 4
append_default MCP_AUDIT_QUOTA 25M
append_default MCP_UID 54321
append_default MCP_GID 54321
