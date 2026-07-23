#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/apex-validate.sh"
"${PROJECT_ROOT}/scripts/oracle-start.sh"

existing_version="$(
  docker exec -i "${ORACLE_DATABASE_CONTAINER}" sqlplus -s / as sysdba <<SQL
set heading off feedback off pagesize 0 verify off echo off
alter session set container = ${ORACLE_PDB};
select coalesce(max(version), 'NONE') from dba_registry where comp_id = 'APEX';
exit
SQL
)"
existing_version="$(printf '%s' "${existing_version}" | tr -d '[:space:]')"
[[ "${existing_version}" == "NONE" ]] ||
  die "APEX ${existing_version} is already installed; use the documented upgrade procedure"

"${PROJECT_ROOT}/scripts/ords-stop.sh"
"${PROJECT_ROOT}/scripts/apex-stage-source.sh"

printf 'Creating dedicated APEX tablespaces when absent...\n'
docker exec -i "${ORACLE_DATABASE_CONTAINER}" sqlplus -s / as sysdba <<SQL
whenever sqlerror exit failure rollback
alter session set container = ${ORACLE_PDB};
set serveroutput on
declare
  l_count number;
  l_data_directory varchar2(4000);
begin
  select substr(file_name, 1, instr(file_name, '/', -1))
    into l_data_directory
    from (
      select file_name
      from dba_data_files
      where tablespace_name = 'USERS'
      order by file_id
    )
   where rownum = 1;

  select count(*) into l_count from dba_tablespaces where tablespace_name = upper('${APEX_TABLESPACE}');
  if l_count = 0 then
    execute immediate
      'create tablespace ${APEX_TABLESPACE} datafile ''' ||
      l_data_directory || lower('${APEX_TABLESPACE}') ||
      '01.dbf'' size 350M autoextend on next 50M maxsize 2G';
  end if;
  select count(*) into l_count from dba_tablespaces where tablespace_name = upper('${APEX_FILES_TABLESPACE}');
  if l_count = 0 then
    execute immediate
      'create tablespace ${APEX_FILES_TABLESPACE} datafile ''' ||
      l_data_directory || lower('${APEX_FILES_TABLESPACE}') ||
      '01.dbf'' size 150M autoextend on next 25M maxsize 1G';
  end if;
end;
/
exit
SQL

printf 'Installing the full APEX %s development environment. This can take several minutes...\n' "${APEX_VERSION}"
docker exec -i \
  --workdir "${APEX_CONTAINER_SOURCE_DIR}" \
  "${ORACLE_DATABASE_CONTAINER}" \
  sqlplus / as sysdba <<SQL
whenever sqlerror exit failure rollback
alter session set container = ${ORACLE_PDB};
@apexins.sql ${APEX_TABLESPACE} ${APEX_FILES_TABLESPACE} TEMP /i/
exit
SQL

printf 'APEX database installation completed. Next run apex-create-admin.sh.\n'
