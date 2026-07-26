#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

"${PROJECT_ROOT}/scripts/mcp-validate.sh"
"${PROJECT_ROOT}/scripts/data-agent-validate.sh"

output="$(
  {
    printf 'whenever sqlerror exit failure rollback\n'
    printf 'set sqlformat ansiconsole\n'
    printf 'conn -name %s\n' "${MCP_CONNECTION_NAME}"
    printf "select sys_context('USERENV','SESSION_USER') as session_user, "
    printf "count(*) as order_count, "
    printf "sum(case when order_status in ('COMPLETED','SHIPPED') "
    printf "then order_total else 0 end) as recognized_revenue "
    printf 'from %s.order_summary;\n' "${MCP_SOURCE_SCHEMA}"
    printf 'exit\n'
  } | compose --profile mcp run --rm -T mcp /nolog
)"

printf '%s\n' "${output}"
grep -q "${MCP_DATABASE_USER}" <<<"${output}" ||
  die 'Read smoke test did not use the dedicated MCP database account'
grep -Eq '(^|[^0-9])12([^0-9]|$)' <<<"${output}" ||
  die 'Read smoke test did not return 12 orders'
grep -Eq '(^|[^0-9])12027([^0-9]|$)' <<<"${output}" ||
  die 'Read smoke test did not return recognized revenue of 12027'

set +e
write_output="$(
  {
    printf 'whenever sqlerror exit failure rollback\n'
    printf 'conn -name %s\n' "${MCP_CONNECTION_NAME}"
    printf 'create table mcp_write_test (id number);\n'
    printf 'exit\n'
  } | compose --profile mcp run --rm -T mcp /nolog 2>&1
)"
write_status=$?
set -e

[[ "${write_status}" -ne 0 ]] ||
  die 'MCP database account unexpectedly created a table'
grep -Eq 'ORA-01031|insufficient privileges' <<<"${write_output}" ||
  die 'MCP write denial did not report insufficient privileges'

printf 'Data-agent MCP read query and write-denial smoke tests passed.\n'
