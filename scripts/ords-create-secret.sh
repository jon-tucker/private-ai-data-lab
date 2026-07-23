#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command openssl

mkdir -p "${PLATFORM_SECRETS_ROOT}"
chmod 700 "${PLATFORM_SECRETS_ROOT}"

if [[ -e "${ORDS_PUBLIC_PASSWORD_FILE}" ]]; then
  die "Secret already exists: ${ORDS_PUBLIC_PASSWORD_FILE}"
fi

umask 077
openssl rand -base64 36 | tr -d '\n' >"${ORDS_PUBLIC_PASSWORD_FILE}"
printf '\n' >>"${ORDS_PUBLIC_PASSWORD_FILE}"
chmod 600 "${ORDS_PUBLIC_PASSWORD_FILE}"
printf 'Created %s with mode 0600. Back it up securely.\n' "${ORDS_PUBLIC_PASSWORD_FILE}"
