#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

load_env
require_command docker
docker info >/dev/null

[[ -r "${ORACLE_PASSWORD_FILE}" ]] || die "Oracle password file is missing or unreadable: ${ORACLE_PASSWORD_FILE}"
[[ "$(stat -c '%a' "${ORACLE_PASSWORD_FILE}")" == "600" ]] || die 'Oracle password file must have mode 0600'
[[ -d "${PLATFORM_DATA_ROOT}/oracle" ]] || die 'Oracle data directory is missing; run oracle-prepare-host.sh'
[[ "$(stat -c '%u:%g' "${PLATFORM_DATA_ROOT}/oracle")" == "54321:54321" ]] || die 'Oracle data directory must be owned by 54321:54321'

compose config --quiet
printf 'Configuration validation passed.\n'
