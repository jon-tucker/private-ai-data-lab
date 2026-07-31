#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

docker exec -i "${ORACLE_DATABASE_CONTAINER}" sqlplus -s / as sysdba <<'SQL'
set linesize 220 pagesize 100 feedback on
alter session set container = FREEPDB1;

column username format a18
column account_status format a22
column object_type format a28
column privilege format a32

select username, account_status
from dba_users
where username = 'LIVESTACK';

select object_type, count(*) as object_count
from dba_objects
where owner = 'LIVESTACK'
group by object_type
order by object_type;

select object_type, object_name, status
from dba_objects
where owner = 'LIVESTACK'
  and status <> 'VALID'
order by object_type, object_name;

select granted_role
from dba_role_privs
where grantee = 'LIVESTACK'
order by granted_role;

select privilege
from dba_sys_privs
where grantee = 'LIVESTACK'
order by privilege;

exit
SQL
