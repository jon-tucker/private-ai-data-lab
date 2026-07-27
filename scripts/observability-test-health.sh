#!/usr/bin/env bash
set -Eeuo pipefail

sudo systemctl start oracle-ai-health.service
service_result="$(
  systemctl show oracle-ai-health.service \
    --property Result \
    --value
)"
[[ "${service_result}" == 'success' ]] || {
  printf 'ERROR: health service result=%s\n' "${service_result}" >&2
  exit 1
}

sudo systemctl --no-pager --full status oracle-ai-health.service || true
journalctl -u oracle-ai-health.service --no-pager -n 80
printf 'Scheduled health-check execution passed.\n'
