#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
docker logs --tail "${1:-200}" -f "${OPEN_WEBUI_CONTAINER}"
