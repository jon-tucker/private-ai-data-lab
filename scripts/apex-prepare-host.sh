#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

[[ -d "${APEX_SOURCE_DIR}" ]] || die "APEX source directory is missing: ${APEX_SOURCE_DIR}"
[[ -f "${APEX_SOURCE_DIR}/apexins.sql" ]] || die "APEX installer is missing: ${APEX_SOURCE_DIR}/apexins.sql"
[[ -d "${APEX_SOURCE_DIR}/images" ]] || die "APEX images directory is missing: ${APEX_SOURCE_DIR}/images"

sudo install -d -m 0755 -o "$(id -u)" -g "$(id -g)" "$(dirname "${APEX_IMAGES_DIR}")"
sudo rm -rf "${APEX_IMAGES_DIR}"
sudo cp -a "${APEX_SOURCE_DIR}/images" "${APEX_IMAGES_DIR}"
sudo chown -R 54321:54321 "${APEX_IMAGES_DIR}"
sudo find "${APEX_IMAGES_DIR}" -type d -exec chmod 0755 {} +
sudo find "${APEX_IMAGES_DIR}" -type f -exec chmod 0644 {} +

printf 'Prepared APEX static resources: %s\n' "${APEX_IMAGES_DIR}"
