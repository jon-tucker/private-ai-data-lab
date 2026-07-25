#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command curl

url="https://${MCP_HTTPS_HOST_BIND}:${MCP_HTTPS_PORT}/healthz"

if curl --fail --silent --show-error "${url}" >/dev/null 2>&1; then
  die 'MCP endpoint unexpectedly passed verification without the private CA'
fi

response="$(
  curl --fail --silent --show-error \
    --cacert "${MCP_TLS_DIR}/ca.crt" \
    "${url}"
)"
[[ "${response}" == 'ok' ]] ||
  die "Unexpected MCP health response: ${response}"

printf 'SQLcl MCP private HTTPS endpoint trust and health checks passed.\n'
