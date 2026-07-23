#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/mcp-validate.sh"

password="$(<"${MCP_DATABASE_PASSWORD_FILE}")"

{
  printf 'whenever sqlerror exit failure rollback\n'
  printf 'set sqlhistory off\n'
  printf 'conn -save %s -savepwd %s/%s@//oracle-db:1521/%s\n' \
    "${MCP_CONNECTION_NAME}" "${MCP_DATABASE_USER}" "${password}" "${ORACLE_PDB}"
  printf 'show connection\n'
  printf 'exit\n'
} | compose --profile mcp run --rm -T mcp /nolog

unset password
"${PROJECT_ROOT}/scripts/mcp-harden-state.sh"
printf 'Saved SQLcl connection %s in the protected connection store.\n' \
  "${MCP_CONNECTION_NAME}"
