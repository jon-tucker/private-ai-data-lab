#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

read -r -s -p 'New Oracle administrator password: ' password
printf '\n'
read -r -s -p 'Confirm password: ' confirmation
printf '\n'
[[ "${password}" == "${confirmation}" ]] || die 'Passwords do not match'
(( ${#password} >= 12 && ${#password} <= 30 )) || die 'Password must be 12 to 30 characters'
[[ "${password}" =~ [[:upper:]] && "${password}" =~ [[:lower:]] && "${password}" =~ [[:digit:]] ]] || die 'Password must contain uppercase, lowercase, and numeric characters'

temporary_file="$(mktemp)"
trap 'rm -f "${temporary_file}"' EXIT
chmod 600 "${temporary_file}"
printf '%s' "${password}" >"${temporary_file}"
docker cp "${temporary_file}" "${ORACLE_DATABASE_CONTAINER}:/tmp/oracle-ai-db-password" >/dev/null
docker exec --user root "${ORACLE_DATABASE_CONTAINER}" chown 54321:54321 /tmp/oracle-ai-db-password
docker exec --user root "${ORACLE_DATABASE_CONTAINER}" chmod 600 /tmp/oracle-ai-db-password
docker exec "${ORACLE_DATABASE_CONTAINER}" bash -c '/opt/oracle/setPassword.sh "$(cat /tmp/oracle-ai-db-password)"; rc=$?; rm -f /tmp/oracle-ai-db-password; exit $rc'
umask 077
printf '%s' "${password}" >"${ORACLE_PASSWORD_FILE}"
chmod 600 "${ORACLE_PASSWORD_FILE}"
unset password confirmation
printf 'Database and local password file updated.\n'
