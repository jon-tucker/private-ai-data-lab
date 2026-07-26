#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

require_command du
require_command find
require_command virsh

printf '=== Filesystem capacity ===\n'
df -h "${PLATFORM_DATA_ROOT}"

printf '\n=== Persistent storage allocation ===\n'
sudo du -sh \
  "${PLATFORM_DATA_ROOT}/oracle" \
  "${PLATFORM_DATA_ROOT}/mcp" \
  "${PLATFORM_DATA_ROOT}/vms" \
  "${PLATFORM_DATA_ROOT}/backups"

printf '\n=== Live VM disk allocation ===\n'
virsh -c "${AGENT_FACTORY_VM_URI}" domblkinfo "${AGENT_FACTORY_VM_NAME}" vda --human
virsh -c "${AGENT_FACTORY_VM_URI}" domblkinfo "${AGENT_FACTORY_VM_NAME}" vdb --human

printf '\n=== Backup groups ===\n'
sudo du -h --max-depth=2 "${PLATFORM_DATA_ROOT}/backups" | sort -h

printf '\n=== Backup files ===\n'
sudo find "${PLATFORM_DATA_ROOT}/backups" \
  -type f \
  -printf '%TY-%Tm-%Td %TH:%TM  %12s  %p\n' |
  sort

printf '\nNo files were changed or removed.\n'
