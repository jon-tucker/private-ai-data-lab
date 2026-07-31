#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

result="$(
  docker exec -i "${ORACLE_DATABASE_CONTAINER}" sqlplus -s / as sysdba <<'SQL'
set heading off feedback off pagesize 0 verify off echo off
whenever sqlerror exit sql.sqlcode
alter session set container = FREEPDB1;
select case
         when (select count(*) from dba_users where username = 'LIVESTACK') = 1
          and (select count(*) from dba_objects where owner = 'LIVESTACK' and status <> 'VALID') = 0
          and (select count(*) from LIVESTACK.brands) = 18
          and (select count(*) from LIVESTACK.fulfillment_centers) = 18
          and (select count(*) from dba_sys_privs
               where grantee = 'LIVESTACK'
                 and privilege in ('UNLIMITED TABLESPACE','CREATE ROLE','ALTER SYSTEM')) = 0
         then 'LIVESTACK_SCHEMA_OK'
         else 'LIVESTACK_SCHEMA_FAILED'
       end
from dual;
exit
SQL
)"

result="$(printf '%s' "${result}" | tr -d '[:space:]')"
[[ "${result}" == "LIVESTACK_SCHEMA_OK" ]] ||
  die "LiveStack schema smoke test failed: ${result:-no result}"
printf 'LiveStack schema returned LIVESTACK_SCHEMA_OK.\n'
