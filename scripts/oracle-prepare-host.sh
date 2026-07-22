#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

load_env
require_command docker

sudo mkdir -p "${PLATFORM_DATA_ROOT}/oracle"
sudo chmod 755 "${PLATFORM_DATA_ROOT}/oracle"
sudo chown 54321:54321 "${PLATFORM_DATA_ROOT}/oracle"
install -d -m 700 "${PLATFORM_SECRETS_ROOT}"

printf 'Prepared Oracle data directory: %s\n' "${PLATFORM_DATA_ROOT}/oracle"
printf 'Prepared secrets directory: %s\n' "${PLATFORM_SECRETS_ROOT}"
