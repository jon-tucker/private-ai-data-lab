#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/mcp-validate.sh"

privilege_granted=false

revoke_create_table() {
  if [[ "${privilege_granted}" == true ]]; then
    "${PROJECT_ROOT}/scripts/oracle-sqlplus.sh" >/dev/null <<SQL
whenever sqlerror exit failure rollback
alter session set container = ${ORACLE_PDB};
revoke create table from ${MCP_DATABASE_USER};
exit
SQL
    privilege_granted=false
  fi
}

trap revoke_create_table EXIT

"${PROJECT_ROOT}/scripts/oracle-sqlplus.sh" <<SQL
whenever sqlerror exit failure rollback
alter session set container = ${ORACLE_PDB};
alter user ${MCP_DATABASE_USER} quota ${MCP_AUDIT_QUOTA} on USERS;
grant create table to ${MCP_DATABASE_USER};
exit
SQL
privilege_granted=true

"${PROJECT_ROOT}/scripts/mcp-protocol-smoke-test.sh"
revoke_create_table
trap - EXIT

audit_count="$(
  "${PROJECT_ROOT}/scripts/oracle-sqlplus.sh" <<SQL |
set heading off feedback off pagesize 0 verify off echo off
alter session set container = ${ORACLE_PDB};
select count(*)
from dba_tables
where owner = '${MCP_DATABASE_USER}'
  and table_name = 'DBTOOLS\$MCP_LOG';
exit
SQL
    awk '/^[[:space:]]*[0-9]+[[:space:]]*$/ { value = $1 } END { print value }'
)"

[[ "${audit_count}" == '1' ]] ||
  die 'SQLcl MCP did not create the expected DBTOOLS$MCP_LOG audit table'

"${PROJECT_ROOT}/scripts/oracle-sqlplus.sh" <<SQL
alter session set container = ${ORACLE_PDB};
set linesize 220
set pagesize 100

select owner, table_name, tablespace_name
from dba_tables
where owner = '${MCP_DATABASE_USER}'
  and table_name = 'DBTOOLS\$MCP_LOG';

select privilege, admin_option
from dba_sys_privs
where grantee = '${MCP_DATABASE_USER}'
order by privilege;

select username, tablespace_name,
       round(bytes / 1024 / 1024, 2) as used_mb,
       round(max_bytes / 1024 / 1024, 2) as quota_mb
from dba_ts_quotas
where username = '${MCP_DATABASE_USER}';
exit
SQL

printf 'Bootstrapped SQLcl MCP audit logging and revoked CREATE TABLE.\n'
