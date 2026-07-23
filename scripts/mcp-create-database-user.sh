#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/mcp-validate.sh"
"${PROJECT_ROOT}/scripts/oracle-start.sh"

marker="${PLATFORM_SECRETS_ROOT}/.mcp-database-user-created"
[[ ! -e "${marker}" ]] ||
  die "MCP database-user marker already exists: ${marker}"

password="$(<"${MCP_DATABASE_PASSWORD_FILE}")"

"${PROJECT_ROOT}/scripts/oracle-sqlplus.sh" <<SQL
whenever sqlerror exit failure rollback
alter session set container = ${ORACLE_PDB};

declare
  l_count number;
begin
  select count(*) into l_count from dba_roles where role = '${MCP_DATABASE_ROLE}';
  if l_count = 0 then
    execute immediate 'create role ${MCP_DATABASE_ROLE}';
  end if;

  select count(*) into l_count from dba_users where username = '${MCP_DATABASE_USER}';
  if l_count > 0 then
    raise_application_error(-20001, 'MCP database user already exists');
  end if;

  execute immediate
    'create user ${MCP_DATABASE_USER} identified by "${password}" ' ||
    'default tablespace USERS temporary tablespace TEMP account unlock';
  execute immediate 'grant create session to ${MCP_DATABASE_USER}';
  execute immediate 'grant ${MCP_DATABASE_ROLE} to ${MCP_DATABASE_USER}';
end;
/
exit
SQL

unset password
umask 077
touch "${marker}"
chmod 600 "${marker}"
printf 'Created least-privilege database user %s and role %s.\n' \
  "${MCP_DATABASE_USER}" "${MCP_DATABASE_ROLE}"
