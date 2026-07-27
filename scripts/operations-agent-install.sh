#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

[[ "${MCP_SOURCE_SCHEMA}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'MCP_SOURCE_SCHEMA must be an uppercase simple Oracle identifier'
[[ "${ORACLE_PDB}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'ORACLE_PDB must be an uppercase simple Oracle identifier'

"${PROJECT_ROOT}/scripts/oracle-start.sh"

{
  printf 'define oracle_pdb = %s\n' "${ORACLE_PDB}"
  printf 'define app_schema = %s\n' "${MCP_SOURCE_SCHEMA}"
  cat "${PROJECT_ROOT}/sql/operations-agent/install.sql"
} | "${PROJECT_ROOT}/scripts/oracle-sqlplus.sh"

"${PROJECT_ROOT}/scripts/mcp-sync-read-grants.sh"
"${PROJECT_ROOT}/scripts/operations-agent-validate.sh"

printf 'Installed the operations-agent repository in %s.\n' \
  "${MCP_SOURCE_SCHEMA}"
