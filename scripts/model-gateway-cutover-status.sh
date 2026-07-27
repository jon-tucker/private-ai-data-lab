#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command ss

"${PROJECT_ROOT}/scripts/model-gateway-operations-status.sh"

printf '\n=== Published model gateway listeners ===\n'
ss -ltnH |
  awk '{print $4}' |
  grep -E ":(${LITELLM_PORT}|${LITELLM_HTTPS_PORT})$" ||
  true
