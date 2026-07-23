#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

docker exec -i "${ORACLE_DATABASE_CONTAINER}" sqlplus -s / as sysdba <<SQL
whenever sqlerror exit failure rollback
alter session set container = ${ORACLE_PDB};
set linesize 220 pagesize 100
select comp_id, comp_name, version, status from dba_registry where comp_id = 'APEX';
select username, account_status
from dba_users
where username in ('APEX_PUBLIC_USER', 'APEX_PUBLIC_ROUTER', 'FLOWS_FILES')
order by username;
select owner, status, count(*) as object_count
from dba_objects
where owner like 'APEX_26%' or owner in ('FLOWS_FILES', 'APEX_PUBLIC_USER', 'APEX_PUBLIC_ROUTER')
group by owner, status
order by owner, status;
exit
SQL
