#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

sudo install -d -m 0755 "${ORDS_CONFIG_DIR}"
sudo install -d -m 0755 "${ORDS_CONFIG_DIR}/logs"
sudo chown -R 54321:54321 "${ORDS_CONFIG_DIR}"
sudo chmod 0755 "${ORDS_CONFIG_DIR}" "${ORDS_CONFIG_DIR}/logs"
printf 'Prepared ORDS configuration directory: %s\n' "${ORDS_CONFIG_DIR}"
