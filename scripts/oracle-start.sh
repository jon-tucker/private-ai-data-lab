#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

load_env
require_command docker
"${PROJECT_ROOT}/scripts/validate.sh"

data_was_empty=false
if [[ -z "$(find "${PLATFORM_DATA_ROOT}/oracle" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
  data_was_empty=true
  rm -f "${PLATFORM_SECRETS_ROOT}/.oracle-db-password-applied"
fi

compose up -d oracle-db

printf 'Waiting for %s to become healthy' "${ORACLE_DATABASE_CONTAINER}"
deadline=$((SECONDS + 1800))
while (( SECONDS < deadline )); do
  status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${ORACLE_DATABASE_CONTAINER}" 2>/dev/null || true)"
  case "${status}" in
    healthy)
      printf ' healthy.\n'
      break
      ;;
    unhealthy|exited|dead)
      printf '\n'
      docker logs --tail 100 "${ORACLE_DATABASE_CONTAINER}" >&2 || true
      die "Database container entered state: ${status}"
      ;;
    *)
      printf '.'
      sleep 5
      ;;
  esac
done
[[ "${status:-}" == "healthy" ]] || die 'Timed out waiting for the database to become healthy'

marker="${PLATFORM_SECRETS_ROOT}/.oracle-db-password-applied"
if [[ ! -f "${marker}" ]]; then
  temporary_secret="/tmp/oracle-ai-db-password"
  docker cp "${ORACLE_PASSWORD_FILE}" "${ORACLE_DATABASE_CONTAINER}:${temporary_secret}" >/dev/null
  docker exec --user root "${ORACLE_DATABASE_CONTAINER}" chown 54321:54321 "${temporary_secret}"
  docker exec --user root "${ORACLE_DATABASE_CONTAINER}" chmod 600 "${temporary_secret}"
  docker exec "${ORACLE_DATABASE_CONTAINER}" bash -c '/opt/oracle/setPassword.sh "$(cat /tmp/oracle-ai-db-password)"; rc=$?; rm -f /tmp/oracle-ai-db-password; exit $rc'
  touch "${marker}"
  chmod 600 "${marker}"
  printf 'Applied the local administrator password.\n'
elif [[ "${data_was_empty}" == true ]]; then
  die 'Unexpected password marker state for an empty database directory'
fi

printf 'Oracle AI Database is ready on port %s (services FREE and FREEPDB1).\n' "${ORACLE_DATABASE_PORT:-1521}"
