#!/usr/bin/env bash
set -Eeuo pipefail

units=(
  oracle-ai-health.timer
  oracle-ai-backup.timer
  oracle-ai-health.service
  oracle-ai-backup.service
)

sudo systemctl disable --now \
  oracle-ai-health.timer \
  oracle-ai-backup.timer >/dev/null 2>&1 || true
sudo rm -f "${units[@]/#//etc/systemd/system/}"
sudo systemctl daemon-reload
sudo systemctl reset-failed

printf 'Observability systemd units removed; platform data and logs were preserved.\n'
