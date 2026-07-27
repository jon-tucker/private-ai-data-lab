#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

for command in curl systemctl systemd-analyze; do
  require_command "${command}"
done

[[ "${OBSERVABILITY_WEBHOOK_URL_FILE}" == /* ]] ||
  die 'OBSERVABILITY_WEBHOOK_URL_FILE must be an absolute path'

for value in \
  "${OBSERVABILITY_HEALTH_CALENDAR}" \
  "${OBSERVABILITY_BACKUP_CALENDAR}"; do
  systemd-analyze calendar "${value}" >/dev/null ||
    die "Invalid systemd calendar expression: ${value}"
done

for value in \
  "${OBSERVABILITY_HEALTH_RANDOM_DELAY}" \
  "${OBSERVABILITY_BACKUP_RANDOM_DELAY}"; do
  systemd-analyze timespan "${value}" >/dev/null ||
    die "Invalid systemd time span: ${value}"
done

if [[ -e "${OBSERVABILITY_WEBHOOK_URL_FILE}" ]]; then
  [[ -f "${OBSERVABILITY_WEBHOOK_URL_FILE}" ]] ||
    die "Webhook URL path is not a regular file: ${OBSERVABILITY_WEBHOOK_URL_FILE}"
  webhook_mode="$(stat -c '%a' "${OBSERVABILITY_WEBHOOK_URL_FILE}")"
  [[ "${webhook_mode}" == '600' ]] ||
    die "Webhook URL file must have mode 0600: ${OBSERVABILITY_WEBHOOK_URL_FILE}"
fi

printf 'Observability configuration validation passed.\n'
