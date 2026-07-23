#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command docker
docker info >/dev/null

[[ -d "${ORDS_CONFIG_DIR}" ]] || die 'ORDS configuration directory is missing; run ords-prepare-host.sh'
[[ "$(stat -c '%u:%g' "${ORDS_CONFIG_DIR}")" == '54321:54321' ]] ||
  die 'ORDS configuration directory must be owned by numeric UID:GID 54321:54321; run ords-prepare-host.sh'
[[ "$(stat -c '%a' "${ORDS_CONFIG_DIR}")" == '755' ]] ||
  die 'ORDS configuration directory must have mode 0755; run ords-prepare-host.sh'
[[ -r "${ORACLE_PASSWORD_FILE}" ]] || die "Oracle administrator password is missing or unreadable: ${ORACLE_PASSWORD_FILE}"
[[ -r "${ORDS_PUBLIC_PASSWORD_FILE}" ]] || die "ORDS runtime password is missing or unreadable: ${ORDS_PUBLIC_PASSWORD_FILE}"
[[ "$(stat -c '%a' "${ORDS_PUBLIC_PASSWORD_FILE}")" == '600' ]] || die 'ORDS runtime password must have mode 0600'
compose --profile ords-install config --quiet
printf 'ORDS configuration validation passed.\n'
