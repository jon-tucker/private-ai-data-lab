#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command openssl

mkdir -p "${PLATFORM_SECRETS_ROOT}"
chmod 700 "${PLATFORM_SECRETS_ROOT}"

if [[ -e "${LITELLM_MASTER_KEY_FILE}" ]]; then
  die "Secret already exists: ${LITELLM_MASTER_KEY_FILE}"
fi

umask 077
printf 'sk-%s\n' "$(openssl rand -hex 32)" >"${LITELLM_MASTER_KEY_FILE}"
chmod 600 "${LITELLM_MASTER_KEY_FILE}"
printf 'Created %s with mode 0600. Back up this key securely.\n' "${LITELLM_MASTER_KEY_FILE}"
