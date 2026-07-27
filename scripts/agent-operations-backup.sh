#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

[[ "${1:-}" == '--confirm' ]] ||
  die 'Cold backup stops Agent Factory, ORDS, and Oracle Database; rerun with --confirm'

"${PROJECT_ROOT}/scripts/agent-operations-validate.sh"
"${PROJECT_ROOT}/scripts/backup-lifecycle-capacity-check.sh"

for command in cp docker find git gzip qemu-img sha256sum sudo tar virsh xargs; do
  require_command "${command}"
done

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_dir="${AGENT_OPERATIONS_BACKUP_ROOT}/${timestamp}"
vm_dir="${backup_dir}/vm"
database_dir="${backup_dir}/database"
host_dir="${backup_dir}/host"
manifest="${backup_dir}/MANIFEST.txt"
checksums="${backup_dir}/SHA256SUMS"
source_state="${backup_dir}/SOURCE_STATE.txt"
os_disk_name="$(basename "${AGENT_FACTORY_OS_DISK}")"
build_disk_name="$(basename "${AGENT_FACTORY_BUILD_DISK}")"

database_was_running=false
ords_was_running=false
mcp_was_running=false
vm_was_running=false
recovery_required=true

container_running() {
  [[ "$(docker inspect --format '{{.State.Running}}' "$1" 2>/dev/null || true)" == 'true' ]]
}

start_previous_services() {
  local best_effort="${1:-false}"
  local failures=0

  if [[ "${database_was_running}" == true ]]; then
    "${PROJECT_ROOT}/scripts/oracle-start.sh" || failures=$((failures + 1))
  fi
  if [[ "${ords_was_running}" == true ]]; then
    "${PROJECT_ROOT}/scripts/ords-start.sh" || failures=$((failures + 1))
  fi
  if [[ "${mcp_was_running}" == true ]]; then
    "${PROJECT_ROOT}/scripts/mcp-http-start.sh" || failures=$((failures + 1))
  fi
  if [[ "${vm_was_running}" == true ]]; then
    "${PROJECT_ROOT}/scripts/agent-factory-vm-start.sh" || failures=$((failures + 1))
  fi

  if ((failures > 0)); then
    printf 'Failed to restore %d previously running service group(s).\n' \
      "${failures}" >&2
    [[ "${best_effort}" == true ]] || return 1
  fi
}

restore_services() {
  local result=$?
  trap - EXIT INT TERM
  start_previous_services true

  if [[ "${recovery_required}" == true ]]; then
    printf 'Service recovery was attempted after an incomplete backup.\n' >&2
  fi
  exit "${result}"
}
trap restore_services EXIT INT TERM

container_running "${ORACLE_DATABASE_CONTAINER}" && database_was_running=true
container_running "${ORDS_CONTAINER}" && ords_was_running=true
if container_running "${MCP_HTTP_CONTAINER}" ||
  container_running "${MCP_TLS_CONTAINER}"; then
  mcp_was_running=true
fi
[[ "$(virsh -c "${AGENT_FACTORY_VM_URI}" domstate "${AGENT_FACTORY_VM_NAME}")" == 'running' ]] &&
  vm_was_running=true

sudo install -d -o "${PLATFORM_UID}" -g "${PLATFORM_GID}" -m 0700 \
  "${backup_dir}" "${vm_dir}" "${database_dir}" "${host_dir}"

git -c "safe.directory=${PROJECT_ROOT}" \
  -C "${PROJECT_ROOT}" status --short >"${source_state}"
if [[ -s "${source_state}" ]]; then
  git_worktree_dirty=true
else
  git_worktree_dirty=false
fi

{
  printf 'created_utc=%s\n' "${timestamp}"
  printf 'git_commit=%s\n' "$(
    git -c "safe.directory=${PROJECT_ROOT}" \
      -C "${PROJECT_ROOT}" rev-parse HEAD
  )"
  printf 'git_worktree_dirty=%s\n' "${git_worktree_dirty}"
  printf 'hostname=%s\n' "$(hostname)"
  printf 'database_was_running=%s\n' "${database_was_running}"
  printf 'ords_was_running=%s\n' "${ords_was_running}"
  printf 'mcp_was_running=%s\n' "${mcp_was_running}"
  printf 'vm_was_running=%s\n' "${vm_was_running}"
  printf 'agent_factory_vm=%s\n' "${AGENT_FACTORY_VM_NAME}"
} >"${manifest}"

if [[ "${vm_was_running}" == true ]]; then
  virsh -c "${AGENT_FACTORY_VM_URI}" shutdown "${AGENT_FACTORY_VM_NAME}"
  deadline=$((SECONDS + AGENT_OPERATIONS_VM_SHUTDOWN_TIMEOUT))
  while [[ "$(virsh -c "${AGENT_FACTORY_VM_URI}" domstate "${AGENT_FACTORY_VM_NAME}")" != 'shut off' ]]; do
    ((SECONDS < deadline)) ||
      die "Agent Factory VM did not stop within ${AGENT_OPERATIONS_VM_SHUTDOWN_TIMEOUT} seconds"
    sleep 5
  done
fi
if [[ "${mcp_was_running}" == true ]]; then
  "${PROJECT_ROOT}/scripts/mcp-http-stop.sh"
fi
if [[ "${ords_was_running}" == true ]]; then
  "${PROJECT_ROOT}/scripts/ords-stop.sh"
fi
if [[ "${database_was_running}" == true ]]; then
  "${PROJECT_ROOT}/scripts/oracle-stop.sh"
fi

virsh -c "${AGENT_FACTORY_VM_URI}" dumpxml "${AGENT_FACTORY_VM_NAME}" \
  >"${vm_dir}/agent-factory.xml"

sudo cp --archive --sparse=always --reflink=auto \
  "${AGENT_FACTORY_OS_DISK}" \
  "${vm_dir}/"
sudo cp --archive --sparse=always --reflink=auto \
  "${AGENT_FACTORY_BUILD_DISK}" \
  "${vm_dir}/"
sudo chown "${PLATFORM_UID}:${PLATFORM_GID}" "${vm_dir}"/*.qcow2
chmod 0600 "${vm_dir}"/*.qcow2

sudo tar --numeric-owner --acls --xattrs --selinux \
  -C "${PLATFORM_DATA_ROOT}" \
  -czf "${database_dir}/oracle.tar.gz" \
  oracle
sudo chown "${PLATFORM_UID}:${PLATFORM_GID}" "${database_dir}/oracle.tar.gz"
chmod 0600 "${database_dir}/oracle.tar.gz"

sudo tar --numeric-owner --acls --xattrs --selinux \
  -C "${PLATFORM_DATA_ROOT}" \
  -czf "${host_dir}/mcp.tar.gz" \
  mcp
sudo chown "${PLATFORM_UID}:${PLATFORM_GID}" "${host_dir}/mcp.tar.gz"
chmod 0600 "${host_dir}/mcp.tar.gz"

qemu-img check "${vm_dir}/${os_disk_name}"
qemu-img check "${vm_dir}/${build_disk_name}"
gzip --test "${database_dir}/oracle.tar.gz"
gzip --test "${host_dir}/mcp.tar.gz"

(
  cd "${backup_dir}"
  find . -type f ! -name SHA256SUMS -print0 |
    sort -z |
    xargs -0 sha256sum >SHA256SUMS
)
chmod 0600 "${manifest}" "${source_state}" "${checksums}"
sudo chown -R "${PLATFORM_UID}:${PLATFORM_GID}" "${backup_dir}"

recovery_required=false
trap - EXIT INT TERM
start_previous_services false

printf 'Cold backup completed: %s\n' "${backup_dir}"
