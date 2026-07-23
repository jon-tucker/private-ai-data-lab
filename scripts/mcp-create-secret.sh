#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

mkdir -p "${PLATFORM_SECRETS_ROOT}"
chmod 700 "${PLATFORM_SECRETS_ROOT}"

if [[ -e "${MCP_DATABASE_PASSWORD_FILE}" ]]; then
  die "Secret already exists: ${MCP_DATABASE_PASSWORD_FILE}"
fi

read -r -s -p 'New MCP database password: ' password
printf '\n'
read -r -s -p 'Confirm password: ' confirmation
printf '\n'

[[ "${password}" == "${confirmation}" ]] || die 'Passwords do not match'
(( ${#password} >= 12 && ${#password} <= 30 )) || die 'Password must be 12 to 30 characters'
[[ "${password}" =~ [[:upper:]] ]] || die 'Password must contain an uppercase letter'
[[ "${password}" =~ [[:lower:]] ]] || die 'Password must contain a lowercase letter'
[[ "${password}" =~ [[:digit:]] ]] || die 'Password must contain a number'
[[ "${password}" =~ ^[A-Za-z0-9_#-]+$ ]] ||
  die 'Password may contain only letters, numbers, underscore, hash, and hyphen'

umask 077
printf '%s' "${password}" >"${MCP_DATABASE_PASSWORD_FILE}"
chmod 600 "${MCP_DATABASE_PASSWORD_FILE}"
unset password confirmation
printf 'Created %s with mode 0600.\n' "${MCP_DATABASE_PASSWORD_FILE}"
