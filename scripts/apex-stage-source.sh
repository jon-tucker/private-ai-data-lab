#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/apex-validate.sh"

docker exec --user 0 "${ORACLE_DATABASE_CONTAINER}" \
  rm -rf "${APEX_CONTAINER_SOURCE_DIR}"
docker exec --user 0 "${ORACLE_DATABASE_CONTAINER}" \
  mkdir -p "${APEX_CONTAINER_SOURCE_DIR}"
docker cp "${APEX_SOURCE_DIR}/." \
  "${ORACLE_DATABASE_CONTAINER}:${APEX_CONTAINER_SOURCE_DIR}/"
docker exec --user 0 "${ORACLE_DATABASE_CONTAINER}" \
  chown -R oracle:oinstall "${APEX_CONTAINER_SOURCE_DIR}"

printf 'Staged APEX %s source inside %s:%s\n' \
  "${APEX_VERSION}" "${ORACLE_DATABASE_CONTAINER}" "${APEX_CONTAINER_SOURCE_DIR}"
