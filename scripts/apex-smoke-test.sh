#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command curl

landing_status="$(curl --silent --output /dev/null --write-out '%{http_code}' --location --max-redirs 0 "${APEX_URL}" || true)"
case "${landing_status}" in
  200|301|302|303) ;;
  *) die "APEX/ORDS landing endpoint returned HTTP ${landing_status}" ;;
esac

images_url="${APEX_URL%/ords/}/i/apex_version.txt"
images_status="$(curl --silent --output /dev/null --write-out '%{http_code}' "${images_url}")"
[[ "${images_status}" == "200" ]] || die "APEX static resources returned HTTP ${images_status}: ${images_url}"

printf 'APEX landing endpoint and local static resources responded successfully.\n'
