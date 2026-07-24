#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command ip

private_address='192.168.122.1'
ip -brief address show virbr0 | grep -q "${private_address}/24" ||
  die "virbr0 does not own ${private_address}/24"

if grep -q '^OLLAMA_HOST_BIND=' "${ENV_FILE}"; then
  sed -i "s/^OLLAMA_HOST_BIND=.*/OLLAMA_HOST_BIND=${private_address}/" "${ENV_FILE}"
else
  printf 'OLLAMA_HOST_BIND=%s\n' "${private_address}" >>"${ENV_FILE}"
fi

printf 'Configured Ollama to publish only on private bridge %s.\n' \
  "${private_address}"
printf 'Restart Ollama and rerun its smoke test before Agent Factory preflight.\n'
