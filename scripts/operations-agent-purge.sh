#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

[[ "${1:-}" == '--confirm' ]] ||
  die 'This deletes expired operational history; rerun with --confirm'
[[ "${OPERATIONS_AGENT_RETENTION_DAYS}" =~ ^[1-9][0-9]*$ ]] ||
  die 'OPERATIONS_AGENT_RETENTION_DAYS must be a positive integer'
[[ "${ORACLE_PDB}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'ORACLE_PDB must be an uppercase simple Oracle identifier'
[[ "${MCP_SOURCE_SCHEMA}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'MCP_SOURCE_SCHEMA must be an uppercase simple Oracle identifier'

{
  printf 'alter session set container = %s;\n' "${ORACLE_PDB}"
  cat <<SQL
set serveroutput on
declare
  l_deleted number;
begin
  delete from ${MCP_SOURCE_SCHEMA}.operations_run
   where completed_utc <
         systimestamp - numtodsinterval(
           ${OPERATIONS_AGENT_RETENTION_DAYS}, 'DAY'
         );
  l_deleted := sql%rowcount;
  commit;
  dbms_output.put_line('Deleted operational runs: ' || l_deleted);
end;
/
exit
SQL
} | "${PROJECT_ROOT}/scripts/oracle-sqlplus.sh"
