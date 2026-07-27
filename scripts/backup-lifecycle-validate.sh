#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

"${PROJECT_ROOT}/scripts/agent-operations-validate.sh"

for script in \
  backup-lifecycle-capacity-check.sh \
  backup-lifecycle-retention.sh \
  backup-lifecycle-restore-drill.sh; do
  [[ -x "${PROJECT_ROOT}/scripts/${script}" ]] ||
    die "Backup-lifecycle script is missing or not executable: ${script}"
done

case "${BACKUP_LIFECYCLE_DRILL_ROOT}/" in
  "${PLATFORM_DATA_ROOT}/oracle/"* | \
  "${PLATFORM_DATA_ROOT}/mcp/"* | \
  "${PLATFORM_DATA_ROOT}/vms/"* | \
  "${AGENT_OPERATIONS_BACKUP_ROOT}/"*)
    die 'BACKUP_LIFECYCLE_DRILL_ROOT overlaps active data or backup storage'
    ;;
esac

printf 'Backup lifecycle configuration validation passed.\n'
