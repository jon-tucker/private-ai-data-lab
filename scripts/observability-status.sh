#!/usr/bin/env bash
set -Eeuo pipefail

for unit in oracle-ai-health.timer oracle-ai-backup.timer; do
  printf '=== %s ===\n' "${unit}"
  systemctl is-enabled "${unit}" 2>/dev/null || true
  systemctl is-active "${unit}" 2>/dev/null || true
  systemctl list-timers "${unit}" --all --no-pager
  printf '\n'
done

printf '=== Recent health executions ===\n'
journalctl -u oracle-ai-health.service --no-pager -n 40

printf '\n=== Recent backup executions ===\n'
journalctl -u oracle-ai-backup.service --no-pager -n 40
