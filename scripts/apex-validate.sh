#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command docker
docker info >/dev/null

[[ -d "${APEX_SOURCE_DIR}" ]] || die "APEX source directory is missing: ${APEX_SOURCE_DIR}"
for required_file in apexins.sql apxchpwd.sql apex_rest_config.sql; do
  [[ -r "${APEX_SOURCE_DIR}/${required_file}" ]] ||
    die "Required APEX file is missing: ${APEX_SOURCE_DIR}/${required_file}"
done
[[ -d "${APEX_IMAGES_DIR}" ]] || die 'APEX images are not prepared; run apex-prepare-host.sh'
[[ -d "${ORDS_CONFIG_DIR}" ]] || die 'ORDS configuration is missing'
[[ -r "${ORACLE_PASSWORD_FILE}" ]] || die "Oracle password file is missing: ${ORACLE_PASSWORD_FILE}"

case "${APEX_TABLESPACE}" in
  *[!A-Za-z0-9_]*|'') die 'APEX_TABLESPACE contains unsupported characters' ;;
esac
case "${APEX_FILES_TABLESPACE}" in
  *[!A-Za-z0-9_]*|'') die 'APEX_FILES_TABLESPACE contains unsupported characters' ;;
esac

compose config --quiet
printf 'APEX configuration validation passed.\n'
