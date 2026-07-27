#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

{
  printf 'alter session set container = %s;\n' "${ORACLE_PDB}"
  cat <<SQL
set linesize 220
set pagesize 100

select object_type, object_name, status
from dba_objects
where owner = '${MCP_SOURCE_SCHEMA}'
  and object_name in (
    'OPERATIONS_RUN',
    'OPERATIONS_CHECK',
    'BACKUP_CATALOG',
    'OPERATIONS_LATEST',
    'OPERATIONS_SUMMARY'
  )
order by object_type, object_name;

select run_id, run_name, result_status, failure_count, warning_count,
       completed_utc
from ${MCP_SOURCE_SCHEMA}.operations_latest
order by run_name;

select count(*) as recorded_runs
from ${MCP_SOURCE_SCHEMA}.operations_run;

exit
SQL
} | "${PROJECT_ROOT}/scripts/oracle-sqlplus.sh"
