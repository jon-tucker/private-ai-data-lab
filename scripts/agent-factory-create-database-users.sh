#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/agent-factory-validate.sh"
"${PROJECT_ROOT}/scripts/oracle-start.sh"

marker="${PLATFORM_SECRETS_ROOT}/.agent-factory-database-users-created"
[[ ! -e "${marker}" ]] ||
  die "Agent Factory database-user marker already exists: ${marker}"

password="$(<"${AGENT_FACTORY_DB_PASSWORD_FILE}")"

"${PROJECT_ROOT}/scripts/oracle-sqlplus.sh" <<SQL
whenever sqlerror exit failure rollback
alter session set container = ${ORACLE_PDB};

declare
  l_count number;
begin
  select count(*) into l_count
  from dba_users
  where username in ('${AGENT_FACTORY_DB_USER}', '${AGENT_FACTORY_DB_READ_USER}');

  if l_count > 0 then
    raise_application_error(-20001, 'An Agent Factory database user already exists');
  end if;

  execute immediate
    'create user ${AGENT_FACTORY_DB_USER} identified by "${password}" ' ||
    'default tablespace USERS quota unlimited on USERS account unlock';

  execute immediate
    'create user ${AGENT_FACTORY_DB_READ_USER} identified by "${password}" account unlock';
end;
/

grant connect, resource, create table, create synonym, create database link,
  create any index, insert any table, create sequence, create trigger,
  create user, drop user
  to ${AGENT_FACTORY_DB_USER};

grant create session to ${AGENT_FACTORY_DB_USER} with admin option;
grant read, write on directory DATA_PUMP_DIR to ${AGENT_FACTORY_DB_USER};
grant select on SYS.V_\$PARAMETER to ${AGENT_FACTORY_DB_USER};
grant create session to ${AGENT_FACTORY_DB_READ_USER};

exit
SQL

unset password
umask 077
touch "${marker}"
chmod 600 "${marker}"
printf 'Created Agent Factory repository users %s and %s.\n' \
  "${AGENT_FACTORY_DB_USER}" "${AGENT_FACTORY_DB_READ_USER}"
