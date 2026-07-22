#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command openssl

mkdir -p "${PLATFORM_SECRETS_ROOT}"
chmod 700 "${PLATFORM_SECRETS_ROOT}"

if [[ -e "${OPEN_WEBUI_SECRET_FILE}" ]]; then
  die "Secret already exists: ${OPEN_WEBUI_SECRET_FILE}"
fi

umask 077
openssl rand -hex 32 >"${OPEN_WEBUI_SECRET_FILE}"
chmod 600 "${OPEN_WEBUI_SECRET_FILE}"
printf 'Created %s with mode 0600. Back up this key securely.\n' "${OPEN_WEBUI_SECRET_FILE}"
