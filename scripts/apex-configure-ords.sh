#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/apex-validate.sh"

"${PROJECT_ROOT}/scripts/ords-stop.sh"

docker exec -i "${ORACLE_DATABASE_CONTAINER}" sqlplus -s / as sysdba <<SQL
whenever sqlerror exit failure rollback
alter session set container = ${ORACLE_PDB};
alter user APEX_PUBLIC_USER grant connect through ORDS_PUBLIC_USER;
begin
  ords_admin.config_plsql_gateway(
    p_runtime_user       => 'ORDS_PUBLIC_USER',
    p_plsql_gateway_user => 'APEX_PUBLIC_USER',
    p_comments           => 'APEX proxied through ORDS_PUBLIC_USER'
  );
  commit;
end;
/
set serveroutput on
begin
  sys.validate_apex;
end;
/
exit
SQL

docker run --rm \
  --user 54321:54321 \
  --volume "${ORDS_CONFIG_DIR}:/etc/ords/config" \
  --entrypoint /opt/oracle/ords/bin/ords \
  "${ORDS_IMAGE}" \
  --config /etc/ords/config \
  config set plsql.gateway.mode proxied

docker run --rm \
  --user 54321:54321 \
  --volume "${ORDS_CONFIG_DIR}:/etc/ords/config" \
  --entrypoint /opt/oracle/ords/bin/ords \
  "${ORDS_IMAGE}" \
  --config /etc/ords/config \
  config set standalone.static.path /opt/oracle/apex/images

docker run --rm \
  --user 54321:54321 \
  --volume "${ORDS_CONFIG_DIR}:/etc/ords/config" \
  --entrypoint /opt/oracle/ords/bin/ords \
  "${ORDS_IMAGE}" \
  --config /etc/ords/config \
  config set standalone.static.context.path /i

"${PROJECT_ROOT}/scripts/ords-harden-config.sh"
"${PROJECT_ROOT}/scripts/ords-start.sh"

printf 'ORDS is configured for the APEX PL/SQL gateway and local /i/ resources.\n'
