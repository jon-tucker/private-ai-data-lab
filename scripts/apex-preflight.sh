#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/apex-validate.sh"
"${PROJECT_ROOT}/scripts/oracle-start.sh"

docker exec -i "${ORACLE_DATABASE_CONTAINER}" sqlplus -s / as sysdba <<SQL
whenever sqlerror exit failure rollback
alter session set container = ${ORACLE_PDB};
set linesize 220 pagesize 100 feedback on

prompt === APEX prerequisites ===
select banner_full from v\$version;
show parameter workarea_size_policy
select comp_id, comp_name, version, status
from dba_registry
where comp_id in ('XDB', 'APEX')
order by comp_id;
select round(sum(value) / 1024 / 1024) as total_sga_mb from v\$sga;
select tablespace_name, round(sum(bytes) / 1024 / 1024) as free_mb
from dba_free_space
where tablespace_name in ('SYSTEM', 'SYSAUX', 'USERS')
group by tablespace_name
order by tablespace_name;
select value as db_create_file_dest
from v\$parameter
where name = 'db_create_file_dest';
exit
SQL
