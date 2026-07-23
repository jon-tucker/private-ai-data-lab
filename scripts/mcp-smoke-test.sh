#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/mcp-validate.sh"

output="$(
  {
    printf 'whenever sqlerror exit failure rollback\n'
    printf 'conn -name %s\n' "${MCP_CONNECTION_NAME}"
    printf "select sys_context('USERENV','SESSION_USER') as session_user, "
    printf "sys_context('USERENV','CON_NAME') as container_name from dual;\n"
    printf 'exit\n'
  } | compose --profile mcp run --rm -T mcp /nolog
)"

printf '%s\n' "${output}"
grep -q "${MCP_DATABASE_USER}" <<<"${output}" ||
  die 'SQLcl did not connect as the dedicated MCP database user'
grep -q "${ORACLE_PDB}" <<<"${output}" ||
  die 'SQLcl did not connect to the configured PDB'
printf 'SQLcl MCP saved-connection smoke test passed.\n'
