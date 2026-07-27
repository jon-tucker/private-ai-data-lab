#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

filesystem_path="${AGENT_OPERATIONS_BACKUP_ROOT}"
[[ -d "${filesystem_path}" ]] || filesystem_path="$(dirname "${filesystem_path}")"
while [[ ! -e "${filesystem_path}" && "${filesystem_path}" != / ]]; do
  filesystem_path="$(dirname "${filesystem_path}")"
done

read -r total_kb available_kb < <(
  df -Pk "${filesystem_path}" |
    awk 'NR == 2 {print $2, $4}'
)
reserve_kb=$((total_kb * BACKUP_LIFECYCLE_RESERVE_PERCENT / 100))

latest_set="$(
  sudo find "${AGENT_OPERATIONS_BACKUP_ROOT}" \
    -mindepth 1 -maxdepth 1 -type d \
    -name '????????T??????Z' -printf '%f\n' 2>/dev/null |
    sort -r |
    head -1
)"

estimated_kb=0
if [[ -n "${latest_set}" ]]; then
  estimated_kb="$(
    sudo du -sk "${AGENT_OPERATIONS_BACKUP_ROOT}/${latest_set}" |
      awk '{print $1}'
  )"
fi

printf 'filesystem_total_kb=%s\n' "${total_kb}"
printf 'filesystem_available_kb=%s\n' "${available_kb}"
printf 'required_reserve_kb=%s\n' "${reserve_kb}"
printf 'estimated_next_backup_kb=%s\n' "${estimated_kb}"

if ((estimated_kb == 0)); then
  printf 'WARN: no prior coordinated backup exists; capacity estimate is unavailable\n'
  exit 0
fi

if ((available_kb - estimated_kb < reserve_kb)); then
  die "Estimated backup would violate ${BACKUP_LIFECYCLE_RESERVE_PERCENT}% free-space reserve"
fi

printf 'PASS: estimated backup preserves the configured free-space reserve\n'
