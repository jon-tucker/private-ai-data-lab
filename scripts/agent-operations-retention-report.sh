#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

printf '=== Agent-operations backup sets ===\n'
if [[ ! -d "${AGENT_OPERATIONS_BACKUP_ROOT}" ]]; then
  printf 'No agent-operations backup directory exists: %s\n' \
    "${AGENT_OPERATIONS_BACKUP_ROOT}"
  exit 0
fi

sudo find "${AGENT_OPERATIONS_BACKUP_ROOT}" \
  -mindepth 1 \
  -maxdepth 1 \
  -type d \
  -printf '%TY-%Tm-%Td %TH:%TM  %p\n' |
  sort

printf '\n=== Allocation by backup set ===\n'
sudo du -sh "${AGENT_OPERATIONS_BACKUP_ROOT}"/* 2>/dev/null | sort -h || true

printf '\nReport only: no retention or deletion action was performed.\n'
printf 'Use backup-lifecycle-retention.sh for policy evaluation and explicit cleanup.\n'
