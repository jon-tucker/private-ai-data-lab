#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
[[ -f "${ENV_FILE}" ]] || cp "${PROJECT_ROOT}/.env.example" "${ENV_FILE}"

append_default() {
  local name="$1"
  local value="$2"
  if ! grep -q "^${name}=" "${ENV_FILE}"; then
    printf '%s=%s\n' "${name}" "${value}" >>"${ENV_FILE}"
    printf 'Added %s to .env\n' "${name}"
  fi
}

append_default OBSERVABILITY_HEALTH_CALENDAR '"*-*-* 06:15:00 UTC"'
append_default OBSERVABILITY_HEALTH_RANDOM_DELAY 15m
append_default OBSERVABILITY_BACKUP_CALENDAR '"Sun *-*-* 04:00:00 UTC"'
append_default OBSERVABILITY_BACKUP_RANDOM_DELAY 30m
append_default OBSERVABILITY_WEBHOOK_URL_FILE /srv/oracle-ai-secrets/observability-webhook-url
