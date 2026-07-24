#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command curl
require_command ssh

"${PROJECT_ROOT}/scripts/agent-factory-validate.sh"
"${PROJECT_ROOT}/scripts/agent-factory-vm-status.sh"
"${PROJECT_ROOT}/scripts/oracle-start.sh"

curl --fail --silent --show-error \
  "${AGENT_FACTORY_OLLAMA_URL}/api/version" >/dev/null ||
  die "Ollama is not reachable at ${AGENT_FACTORY_OLLAMA_URL}"

ssh -o BatchMode=yes -o ConnectTimeout=5 \
  "${AGENT_FACTORY_VM_USER}@${AGENT_FACTORY_VM_IP}" bash -s <<'REMOTE'
set -Eeuo pipefail
grep -q 'Oracle Linux Server release 8' /etc/oracle-release
[[ "$(podman info --format '{{.Host.Security.Rootless}}')" == 'true' ]]
[[ "$(findmnt -n -o TARGET /u01)" == '/u01' ]]
[[ "$(df --output=avail -B1 /u01 | tail -1)" -ge 100000000000 ]]
REMOTE

"${PROJECT_ROOT}/scripts/oracle-sqlplus.sh" <<SQL
whenever sqlerror exit failure rollback
alter session set container = ${ORACLE_PDB};

declare
  l_value varchar2(30);
begin
  select value into l_value
  from v\$parameter
  where name = 'max_string_size';

  if l_value <> 'EXTENDED' then
    raise_application_error(-20001, 'MAX_STRING_SIZE must be EXTENDED');
  end if;
end;
/
exit
SQL

printf 'Agent Factory host, VM, database, and Ollama preflight passed.\n'
