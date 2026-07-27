#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

apply=false
confirm=false
for argument in "$@"; do
  case "${argument}" in
    --apply) apply=true ;;
    --confirm-delete) confirm=true ;;
    *) die "Unknown argument: ${argument}" ;;
  esac
done

if [[ "${apply}" == true && "${confirm}" != true ]]; then
  die 'Deletion requires both --apply and --confirm-delete'
fi

"${PROJECT_ROOT}/scripts/agent-operations-validate.sh"
require_command readlink

root="$(readlink -f "${AGENT_OPERATIONS_BACKUP_ROOT}")"
[[ -d "${root}" ]] || {
  printf 'No coordinated backup root exists: %s\n' "${root}"
  exit 0
}

mapfile -t sets < <(
  sudo find "${root}" -mindepth 1 -maxdepth 1 -type d \
    -name '????????T??????Z' -printf '%f\n' |
    sort -r
)

now_epoch="$(date -u +%s)"
eligible=()
protected=()
skipped=()

for index in "${!sets[@]}"; do
  name="${sets[index]}"
  path="${root}/${name}"
  resolved="$(readlink -f "${path}")"
  [[ "$(dirname "${resolved}")" == "${root}" ]] ||
    die "Backup path escaped configured root: ${path}"
  [[ "${name}" =~ ^[0-9]{8}T[0-9]{6}Z$ ]] ||
    die "Unexpected backup-set name: ${name}"

  if ((index < BACKUP_LIFECYCLE_MINIMUM_SETS)); then
    protected+=("${path}|minimum-set protection")
    continue
  fi

  created_epoch="$(date -u -d "${name:0:8} ${name:9:2}:${name:11:2}:${name:13:2}" +%s)"
  age_days=$(((now_epoch - created_epoch) / 86400))
  if ((age_days < BACKUP_LIFECYCLE_RETENTION_DAYS)); then
    protected+=("${path}|age ${age_days}d")
    continue
  fi

  marker="${path}/VERIFICATION.txt"
  if [[ ! -f "${marker}" ]] ||
    ! grep -q '^status=VERIFIED$' "${marker}"; then
    skipped+=("${path}|not independently verified")
    continue
  fi
  eligible+=("${path}|age ${age_days}d")
done

printf 'mode=%s\n' "$([[ "${apply}" == true ]] && printf apply || printf dry-run)"
printf 'retention_days=%s\n' "${BACKUP_LIFECYCLE_RETENTION_DAYS}"
printf 'minimum_sets=%s\n' "${BACKUP_LIFECYCLE_MINIMUM_SETS}"

for item in "${protected[@]}"; do
  printf 'PROTECT %s (%s)\n' "${item%%|*}" "${item#*|}"
done
for item in "${skipped[@]}"; do
  printf 'SKIP %s (%s)\n' "${item%%|*}" "${item#*|}"
done
for item in "${eligible[@]}"; do
  printf 'ELIGIBLE %s (%s)\n' "${item%%|*}" "${item#*|}"
done

if [[ "${apply}" != true ]]; then
  printf 'Dry run only: no backup set was deleted.\n'
  exit 0
fi

for item in "${eligible[@]}"; do
  path="${item%%|*}"
  printf 'DELETE %s\n' "${path}"
  sudo find "${path}" -depth -delete
done

printf 'Retention completed: deleted_sets=%s\n' "${#eligible[@]}"
