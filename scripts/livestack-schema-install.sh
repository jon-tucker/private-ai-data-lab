#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

require_command docker
require_command sudo

[[ "${LIVESTACK_DATABASE_USER}" == "LIVESTACK" ]] ||
  die "LIVESTACK_DATABASE_USER must be LIVESTACK"
[[ "${LIVESTACK_DATABASE_QUOTA_MB}" =~ ^[0-9]+$ ]] ||
  die "LIVESTACK_DATABASE_QUOTA_MB must be numeric"
(( LIVESTACK_DATABASE_QUOTA_MB >= 256 && LIVESTACK_DATABASE_QUOTA_MB <= 2048 )) ||
  die "LIVESTACK_DATABASE_QUOTA_MB must be between 256 and 2048"
[[ -d "${LIVESTACK_SOURCE_DIR}/db/schema" ]] ||
  die "Staged LiveStack schema source is missing"
[[ -d "${LIVESTACK_SOURCE_DIR}/db/data" ]] ||
  die "Staged LiveStack data source is missing"
[[ -f "${LIVESTACK_DATABASE_PASSWORD_FILE}" ]] ||
  die "LiveStack database password file is missing"

password="$(sudo cat "${LIVESTACK_DATABASE_PASSWORD_FILE}")"
password="${password//$'\r'/}"
password="${password//$'\n'/}"
[[ "${password}" =~ ^[[:xdigit:]]{64}$ ]] ||
  die "LiveStack database password must contain exactly 64 hexadecimal characters"

existing="$(
  docker exec -i "${ORACLE_DATABASE_CONTAINER}" sqlplus -s / as sysdba <<'SQL'
set heading off feedback off pagesize 0 verify off echo off
alter session set container = FREEPDB1;
select count(*) from dba_users where username = 'LIVESTACK';
exit
SQL
)"
existing="$(printf '%s' "${existing}" | tr -d '[:space:]')"
[[ "${existing}" == "0" ]] ||
  die "LIVESTACK schema already exists; no changes were made"

stage="/tmp/oracle-ai-livestack-install-$$"
cleanup() {
  docker exec -u 0 "${ORACLE_DATABASE_CONTAINER}" \
    find "${stage}" -depth -delete \
    >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker exec "${ORACLE_DATABASE_CONTAINER}" install -d -m 700 "${stage}/vendor-db" "${stage}/control"
docker cp "${LIVESTACK_SOURCE_DIR}/db/." \
  "${ORACLE_DATABASE_CONTAINER}:${stage}/vendor-db/"
docker cp "${PROJECT_ROOT}/sql/livestack/compatibility.sql" \
  "${ORACLE_DATABASE_CONTAINER}:${stage}/control/compatibility.sql"

driver="$(mktemp)"
trap 'find "${driver}" -delete; cleanup' EXIT
chmod 600 "${driver}"
cat >"${driver}" <<SQL
set echo off verify off define off serveroutput on
whenever oserror exit failure rollback
whenever sqlerror exit sql.sqlcode rollback

alter session set container = FREEPDB1;

create user LIVESTACK
  identified by "${password}"
  default tablespace USERS
  temporary tablespace TEMP
  quota ${LIVESTACK_DATABASE_QUOTA_MB}M on USERS;

grant create session,
      create table,
      create view,
      create sequence,
      create procedure,
      create trigger,
      create type
  to LIVESTACK;
grant soda_app, graph_developer to LIVESTACK;
grant execute on mdsys.sdo_geom to LIVESTACK;
grant execute on mdsys.sdo_util to LIVESTACK;
grant execute on mdsys.sdo_cs to LIVESTACK;

connect LIVESTACK/"${password}"@//localhost:1521/FREEPDB1

@${stage}/vendor-db/schema/01_tables.sql
@${stage}/vendor-db/schema/02_json_collections.sql
@${stage}/vendor-db/schema/03_graph.sql
@${stage}/control/compatibility.sql
@${stage}/vendor-db/schema/05_spatial.sql
@${stage}/vendor-db/schema/10_service_restoration_graph.sql
@${stage}/vendor-db/data/load_all_data.sql
@${stage}/vendor-db/data/load_service_restoration_graph.sql
@${stage}/vendor-db/schema/11_utilities_semantic_views.sql

commit;
exit success
SQL

docker exec -i "${ORACLE_DATABASE_CONTAINER}" sh -c \
  "umask 077; cat > '${stage}/control/install.sql'" <"${driver}"

printf 'Installing the bounded LIVESTACK schema and demonstration data.\n'
if ! docker exec -i "${ORACLE_DATABASE_CONTAINER}" \
  sqlplus -s / as sysdba "@${stage}/control/install.sql"
then
  die "LiveStack installation failed; inspect the output before using the guarded uninstall"
fi

printf 'LiveStack schema installation completed.\n'
printf 'Excluded: cloud AI, database agents, ONNX model loading, unrestricted ACLs, VPD, and global demo roles.\n'
