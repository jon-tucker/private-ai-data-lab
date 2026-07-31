#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

[[ "${1:-}" == "--confirm-schema-drop" &&
   "${2:-}" == "--confirm-data-loss" ]] ||
  die "Refusing schema removal. Supply --confirm-schema-drop --confirm-data-loss"

docker exec -i "${ORACLE_DATABASE_CONTAINER}" sqlplus -s / as sysdba <<'SQL'
whenever sqlerror exit sql.sqlcode
alter session set container = FREEPDB1;

declare
  schema_count number;
begin
  select count(*) into schema_count
  from dba_users
  where username = 'LIVESTACK';

  if schema_count = 1 then
    execute immediate 'drop user LIVESTACK cascade';
  end if;
end;
/
exit
SQL

printf 'Removed only the LIVESTACK database schema and its objects.\n'
