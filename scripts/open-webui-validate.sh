#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command docker
docker info >/dev/null

[[ -d "${PLATFORM_DATA_ROOT}/open-webui" ]] || die 'Open WebUI data directory is missing; run open-webui-prepare-host.sh'
[[ -s "${OPEN_WEBUI_SECRET_FILE}" ]] || die 'Open WebUI secret is missing or empty; run open-webui-create-secret.sh'
[[ "$(stat -c '%a' "${OPEN_WEBUI_SECRET_FILE}")" == '600' ]] || die 'Open WebUI secret must have mode 0600'
[[ "$(wc -c <"${OPEN_WEBUI_SECRET_FILE}")" -ge 64 ]] || die 'Open WebUI secret is unexpectedly short'
compose --profile "${OLLAMA_ACCELERATOR}" config --quiet
printf 'Open WebUI configuration validation passed.\n'
