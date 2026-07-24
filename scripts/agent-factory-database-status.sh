#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

"${PROJECT_ROOT}/scripts/oracle-sqlplus.sh" <<SQL
alter session set container = ${ORACLE_PDB};
set linesize 240
set pagesize 100

select name, value
from v\$parameter
where name = 'max_string_size';

select username, account_status, default_tablespace, temporary_tablespace
from dba_users
where username in ('${AGENT_FACTORY_DB_USER}', '${AGENT_FACTORY_DB_READ_USER}')
order by username;

select grantee, granted_role, admin_option
from dba_role_privs
where grantee = '${AGENT_FACTORY_DB_USER}'
order by granted_role;

select grantee, privilege, admin_option
from dba_sys_privs
where grantee in ('${AGENT_FACTORY_DB_USER}', '${AGENT_FACTORY_DB_READ_USER}')
order by grantee, privilege;

exit
SQL
