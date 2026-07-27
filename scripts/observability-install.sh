#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

enable_backup=false
case "${1:-}" in
  '')
    ;;
  --enable-backup)
    enable_backup=true
    ;;
  *)
    die 'Usage: observability-install.sh [--enable-backup]'
    ;;
esac

"${PROJECT_ROOT}/scripts/observability-validate.sh"

for command in sed sudo systemctl systemd-analyze; do
  require_command "${command}"
done

unit_source="${PROJECT_ROOT}/systemd"
render_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${render_dir}"
}
trap cleanup EXIT

render_unit() {
  local source_name="$1"
  sed \
    -e "s|@PROJECT_ROOT@|${PROJECT_ROOT}|g" \
    -e "s|@PLATFORM_USER@|$(id -un)|g" \
    -e "s|@PLATFORM_GROUP@|$(id -gn)|g" \
    -e "s|@HEALTH_CALENDAR@|${OBSERVABILITY_HEALTH_CALENDAR}|g" \
    -e "s|@HEALTH_RANDOM_DELAY@|${OBSERVABILITY_HEALTH_RANDOM_DELAY}|g" \
    -e "s|@BACKUP_CALENDAR@|${OBSERVABILITY_BACKUP_CALENDAR}|g" \
    -e "s|@BACKUP_RANDOM_DELAY@|${OBSERVABILITY_BACKUP_RANDOM_DELAY}|g" \
    "${unit_source}/${source_name}" >"${render_dir}/${source_name}"
}

for unit in \
  oracle-ai-health.service \
  oracle-ai-health.timer \
  oracle-ai-backup.service \
  oracle-ai-backup.timer; do
  render_unit "${unit}"
done

systemd-analyze verify "${render_dir}"/*.service "${render_dir}"/*.timer

sudo install -o root -g root -m 0644 \
  "${render_dir}"/*.service \
  "${render_dir}"/*.timer \
  /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable --now oracle-ai-health.timer

if [[ "${enable_backup}" == true ]]; then
  sudo systemctl enable --now oracle-ai-backup.timer
  printf 'Weekly coordinated backup timer enabled.\n'
else
  sudo systemctl disable --now oracle-ai-backup.timer >/dev/null 2>&1 || true
  printf 'Weekly coordinated backup timer remains disabled.\n'
  printf 'Enable after reviewing its schedule with:\n'
  printf '  %s --enable-backup\n' "$0"
fi

printf 'Observability systemd units installed.\n'
