#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/mcp-validate.sh"

"${PROJECT_ROOT}/scripts/oracle-sqlplus.sh" <<SQL
whenever sqlerror exit failure rollback
alter session set container = ${ORACLE_PDB};

declare
begin
  for item in (
    select owner, object_name
    from dba_objects
    where owner = '${MCP_SOURCE_SCHEMA}'
      and object_type in ('TABLE', 'VIEW', 'MATERIALIZED VIEW')
      and object_name not like 'BIN\$%'
  ) loop
    execute immediate
      'grant select on ' ||
      dbms_assert.enquote_name(item.owner, false) || '.' ||
      dbms_assert.enquote_name(item.object_name, false) ||
      ' to ${MCP_DATABASE_ROLE}';
  end loop;
end;
/

select privilege, count(*) as grant_count
from dba_tab_privs
where grantee = '${MCP_DATABASE_ROLE}'
  and owner = '${MCP_SOURCE_SCHEMA}'
group by privilege
order by privilege;
exit
SQL

printf 'Synchronized read grants from %s to role %s.\n' \
  "${MCP_SOURCE_SCHEMA}" "${MCP_DATABASE_ROLE}"
