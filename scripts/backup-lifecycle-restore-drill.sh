#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

backup_dir="${1:-}"
confirmation="${2:-}"
[[ -n "${backup_dir}" && "${confirmation}" == '--confirm-staging' ]] ||
  die "Usage: $0 ${AGENT_OPERATIONS_BACKUP_ROOT}/TIMESTAMP --confirm-staging"

"${PROJECT_ROOT}/scripts/agent-operations-validate.sh"
"${PROJECT_ROOT}/scripts/agent-operations-verify-backup.sh" "${backup_dir}"

backup_dir="$(readlink -f "${backup_dir}")"
backup_root="$(readlink -f "${AGENT_OPERATIONS_BACKUP_ROOT}")"
[[ "$(dirname "${backup_dir}")" == "${backup_root}" ]] ||
  die 'Backup set must be directly beneath AGENT_OPERATIONS_BACKUP_ROOT'

case "${BACKUP_LIFECYCLE_DRILL_ROOT}/" in
  "${PLATFORM_DATA_ROOT}/oracle/"* | \
  "${PLATFORM_DATA_ROOT}/mcp/"* | \
  "${PLATFORM_DATA_ROOT}/vms/"* | \
  "${AGENT_OPERATIONS_BACKUP_ROOT}/"*)
    die 'Restore-drill root must be isolated from active data and backups'
    ;;
esac

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
drill_dir="${BACKUP_LIFECYCLE_DRILL_ROOT}/${timestamp}"
sudo install -d -o "${PLATFORM_UID}" -g "${PLATFORM_GID}" -m 0700 \
  "${BACKUP_LIFECYCLE_DRILL_ROOT}" \
  "${drill_dir}"
sudo install -d -o "${PLATFORM_UID}" -g "${PLATFORM_GID}" -m 0700 \
  "${drill_dir}/database" "${drill_dir}/host" "${drill_dir}/vm"

tar -xzf "${backup_dir}/database/oracle.tar.gz" \
  -C "${drill_dir}/database"
tar -xzf "${backup_dir}/host/mcp.tar.gz" \
  -C "${drill_dir}/host"
cp "${backup_dir}/vm/agent-factory.xml" "${drill_dir}/vm/"

{
  printf 'status=STAGED\n'
  printf 'created_utc=%s\n' "${timestamp}"
  printf 'source_backup=%s\n' "${backup_dir}"
  printf 'database_tree=%s\n' "${drill_dir}/database"
  printf 'mcp_tree=%s\n' "${drill_dir}/host"
  printf 'note=No active service path was modified\n'
} >"${drill_dir}/RESTORE_DRILL.txt"
chmod 0600 "${drill_dir}/RESTORE_DRILL.txt"

printf 'Restore drill staged successfully: %s\n' "${drill_dir}"
printf 'No active service path was modified. Review and remove staging explicitly.\n'
