#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

mkdir -p "${PLATFORM_DATA_ROOT}/open-webui"
chmod 750 "${PLATFORM_DATA_ROOT}/open-webui"
[[ -r "${OPEN_WEBUI_SECRET_FILE}" ]] || die "Open WebUI secret is missing or unreadable: ${OPEN_WEBUI_SECRET_FILE}"
[[ "$(stat -c '%a' "${OPEN_WEBUI_SECRET_FILE}")" == '600' ]] || die 'Open WebUI secret must have mode 0600'
printf 'Prepared Open WebUI data directory: %s\n' "${PLATFORM_DATA_ROOT}/open-webui"
