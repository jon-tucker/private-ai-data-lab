#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/ords-validate.sh"

if find "${ORDS_CONFIG_DIR}/databases" -name pool.xml -print -quit 2>/dev/null | grep -q .; then
  die 'ORDS configuration already exists; use the documented upgrade procedure instead of reinstalling'
fi

"${PROJECT_ROOT}/scripts/oracle-start.sh"

printf 'Installing ORDS metadata and creating its runtime connection pool...\n'
{
  printf '%s\n' "$(cat "${ORACLE_PASSWORD_FILE}")"
  printf '%s\n' "$(cat "${ORDS_PUBLIC_PASSWORD_FILE}")"
} | compose --profile ords-install run --rm -T ords-install

"${PROJECT_ROOT}/scripts/ords-harden-config.sh"

printf 'ORDS installation completed. The SYS password was supplied through standard input only.\n'
