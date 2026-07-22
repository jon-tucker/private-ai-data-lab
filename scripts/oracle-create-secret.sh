#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

load_env
install -d -m 700 "${PLATFORM_SECRETS_ROOT}"

if [[ -f "${ORACLE_PASSWORD_FILE}" ]]; then
  printf 'Password file already exists: %s\n' "${ORACLE_PASSWORD_FILE}"
  printf 'Use scripts/oracle-rotate-password.sh to change an existing database password.\n'
  exit 0
fi

read -r -s -p 'New Oracle administrator password: ' password
printf '\n'
read -r -s -p 'Confirm password: ' confirmation
printf '\n'

[[ "${password}" == "${confirmation}" ]] || die 'Passwords do not match'
(( ${#password} >= 12 && ${#password} <= 30 )) || die 'Password must be 12 to 30 characters'
[[ "${password}" =~ [[:upper:]] ]] || die 'Password must contain an uppercase letter'
[[ "${password}" =~ [[:lower:]] ]] || die 'Password must contain a lowercase letter'
[[ "${password}" =~ [[:digit:]] ]] || die 'Password must contain a number'
[[ ! "${password}" =~ [[:space:]] ]] || die 'Password must not contain whitespace'

umask 077
printf '%s' "${password}" >"${ORACLE_PASSWORD_FILE}"
chmod 600 "${ORACLE_PASSWORD_FILE}"
unset password confirmation
printf 'Created %s with mode 0600.\n' "${ORACLE_PASSWORD_FILE}"
