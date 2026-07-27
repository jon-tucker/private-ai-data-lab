#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

record=false
if [[ "${1:-}" == '--record' ]]; then
  record=true
  shift
fi

backup_dir="${1:-}"
[[ -n "${backup_dir}" ]] ||
  die "Usage: $0 ${AGENT_OPERATIONS_BACKUP_ROOT}/TIMESTAMP"
[[ -d "${backup_dir}" ]] || die "Backup directory not found: ${backup_dir}"

os_disk_name="$(basename "${AGENT_FACTORY_OS_DISK}")"
build_disk_name="$(basename "${AGENT_FACTORY_BUILD_DISK}")"

for file in \
  MANIFEST.txt \
  SHA256SUMS \
  database/oracle.tar.gz \
  host/mcp.tar.gz \
  vm/agent-factory.xml \
  "vm/${os_disk_name}" \
  "vm/${build_disk_name}"; do
  [[ -f "${backup_dir}/${file}" ]] || die "Backup file is missing: ${file}"
done

(
  cd "${backup_dir}"
  sha256sum --check SHA256SUMS
)
gzip --test "${backup_dir}/database/oracle.tar.gz"
gzip --test "${backup_dir}/host/mcp.tar.gz"
qemu-img check "${backup_dir}/vm/${os_disk_name}"
qemu-img check "${backup_dir}/vm/${build_disk_name}"

if [[ "${record}" == true ]]; then
  {
    printf 'status=VERIFIED\n'
    printf 'verified_utc=%s\n' "$(date -u +%Y%m%dT%H%M%SZ)"
    printf 'verified_by=%s\n' "$(id -un)"
  } >"${backup_dir}/VERIFICATION.txt"
  chmod 0600 "${backup_dir}/VERIFICATION.txt"
fi

printf 'Backup verification passed: %s\n' "${backup_dir}"
