#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

[[ -d "${ORDS_CONFIG_DIR}" ]] || die "ORDS configuration directory is missing: ${ORDS_CONFIG_DIR}"

docker run --rm \
  --user 54321:54321 \
  --volume "${ORDS_CONFIG_DIR}:/etc/ords/config" \
  --entrypoint /bin/bash \
  "${ORDS_IMAGE}" \
  -Eeuo pipefail -c '
    find /etc/ords/config -type d -exec chmod 0755 {} +
    find /etc/ords/config -type f -exec chmod 0600 {} +
  '

printf 'Hardened ORDS configuration directories to 0755 and files to 0600.\n'
