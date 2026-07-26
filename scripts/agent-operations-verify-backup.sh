#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

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

printf 'Backup verification passed: %s\n' "${backup_dir}"
