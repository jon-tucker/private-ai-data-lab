#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

[[ "${LIVESTACK_DATABASE_USER}" == "LIVESTACK" ]] ||
  die "LIVESTACK_DATABASE_USER must be LIVESTACK"
telemetry_enabled="$(printf '%s' "${LIVESTACK_TELEMETRY_ENABLED}" | tr '[:upper:]' '[:lower:]')"
[[ "${telemetry_enabled}" == "false" ]] ||
  die "LiveStack usage telemetry must remain disabled"
[[ "${LIVESTACK_HOST_BIND}" == "127.0.0.1" ]] ||
  die "Foundation release requires loopback-only publication"
[[ "${LIVESTACK_PORT}" =~ ^[0-9]+$ ]] ||
  die "LIVESTACK_PORT must be numeric"
[[ "${LIVESTACK_DATABASE_CONNECT_STRING}" == "oracle-db:1521/FREEPDB1" ]] ||
  die "LiveStack must reuse the platform database service"
[[ "${LIVESTACK_DATABASE_QUOTA_MB}" =~ ^[0-9]+$ ]] ||
  die "LIVESTACK_DATABASE_QUOTA_MB must be numeric"
(( LIVESTACK_DATABASE_QUOTA_MB >= 256 && LIVESTACK_DATABASE_QUOTA_MB <= 2048 )) ||
  die "LIVESTACK_DATABASE_QUOTA_MB must be between 256 and 2048"
[[ "${LIVESTACK_OLLAMA_URL}" == "http://ollama:11434" ]] ||
  die "LiveStack must reuse the private platform Ollama service"
[[ -z "${DEMO_USAGE_COUNTER_PAR_URL:-}" ]] ||
  die "DEMO_USAGE_COUNTER_PAR_URL must not be configured"

if [[ -e "${LIVESTACK_SOURCE_DIR}" ]]; then
  [[ -f "${LIVESTACK_SOURCE_DIR}/Containerfile" ]] ||
    die "Staged source is incomplete"
  [[ ! -f "${LIVESTACK_SOURCE_DIR}/.env" ]] ||
    die "A vendor .env file remains in staged source"
  ! find "${LIVESTACK_SOURCE_DIR}" -name '._*' -print -quit | grep -q . ||
    die "macOS metadata remains in staged source"
  for prohibited in \
    .env.example \
    compose.yml \
    compose.deploy.yml \
    scripts/bootstrap_db.sh \
    db/schema/00_setup.sql
  do
    [[ ! -e "${LIVESTACK_SOURCE_DIR}/${prohibited}" ]] ||
      die "Prohibited vendor bootstrap file remains: ${prohibited}"
  done
  grep -q 'APP_SCHEMA_PASSWORD_FILE' \
    "${LIVESTACK_SOURCE_DIR}/backend/config/database.js" ||
    die "Application database password-file support is missing"
fi

if [[ -e "${LIVESTACK_DATABASE_PASSWORD_FILE}" ]]; then
  mode="$(stat -c '%a' "${LIVESTACK_DATABASE_PASSWORD_FILE}")"
  [[ "${mode}" == "600" ]] || die "Database password file must have mode 600"
fi

docker compose \
  --project-directory "${PROJECT_ROOT}" \
  --env-file "${ENV_FILE}" \
  --profile livestack \
  config --quiet

printf 'LiveStack integration configuration validation passed.\n'
