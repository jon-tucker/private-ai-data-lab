#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

output="$(
  {
    printf 'alter session set container = %s;\n' "${ORACLE_PDB}"
    cat <<SQL
set heading off feedback off pagesize 0
select case
         when count(*) = 5 then 'OBJECTS_OK'
         else 'OBJECTS_BAD:' || count(*)
       end
from dba_objects
where owner = '${MCP_SOURCE_SCHEMA}'
  and object_name in (
    'OPERATIONS_RUN',
    'OPERATIONS_CHECK',
    'BACKUP_CATALOG',
    'OPERATIONS_LATEST',
    'OPERATIONS_SUMMARY'
  )
  and status = 'VALID';

select case
         when count(*) = 5 then 'GRANTS_OK'
         else 'GRANTS_BAD:' || count(*)
       end
from dba_tab_privs
where owner = '${MCP_SOURCE_SCHEMA}'
  and grantee = '${MCP_DATABASE_ROLE}'
  and privilege = 'SELECT'
  and table_name in (
    'OPERATIONS_RUN',
    'OPERATIONS_CHECK',
    'BACKUP_CATALOG',
    'OPERATIONS_LATEST',
    'OPERATIONS_SUMMARY'
  );
exit
SQL
  } | "${PROJECT_ROOT}/scripts/oracle-sqlplus.sh"
)"

grep -q 'OBJECTS_OK' <<<"${output}" ||
  die 'Operations-agent repository objects are missing or invalid'
grep -q 'GRANTS_OK' <<<"${output}" ||
  die 'Operations-agent MCP read grants are incomplete'

printf 'Operations-agent repository and read grants passed.\n'
