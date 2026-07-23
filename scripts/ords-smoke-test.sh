#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command curl

code="$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 20 "${ORDS_URL}")"
case "${code}" in
  200|301|302|401|403|404)
    printf 'ORDS HTTP endpoint responded with status %s.\n' "${code}"
    ;;
  *)
    die "Unexpected ORDS HTTP status: ${code}"
    ;;
esac
