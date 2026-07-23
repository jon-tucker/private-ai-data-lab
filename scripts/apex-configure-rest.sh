#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/apex-validate.sh"
docker exec "${ORACLE_DATABASE_CONTAINER}" test -r \
  "${APEX_CONTAINER_SOURCE_DIR}/apex_rest_config.sql" ||
  die 'Staged APEX source is missing from the database container; run apex-stage-source.sh'

docker exec "${ORACLE_DATABASE_CONTAINER}" bash -c \
  "printf '%s\n%s\n' 'alter session set container = ${ORACLE_PDB};' '@apex_rest_config.sql' > '${APEX_CONTAINER_SOURCE_DIR}/platform-apex-rest-config.sql'"

printf '%s\n' \
  'APEX will prompt for passwords for its REST accounts.' \
  'Use strong, unique values and record them in your password manager.'
docker exec -it \
  --workdir "${APEX_CONTAINER_SOURCE_DIR}" \
  "${ORACLE_DATABASE_CONTAINER}" \
  sqlplus / as sysdba @platform-apex-rest-config.sql
