#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

require_command openssl
require_command ss
require_command systemctl

"$(dirname "${BASH_SOURCE[0]}")/agent-factory-edge-validate.sh"

[[ "${AGENT_FACTORY_EDGE_PORT}" == '443' ]] ||
  die "Agent Factory edge must use host port 443"
[[ "${AGENT_FACTORY_EDGE_SERVER_NAME}" == *.local ]] ||
  die "Agent Factory edge server name must be an mDNS .local name"

systemctl is-enabled avahi-daemon >/dev/null ||
  die "Avahi must be enabled for stable mDNS discovery"
systemctl is-active avahi-daemon >/dev/null ||
  die "Avahi must be active for stable mDNS discovery"

openssl x509 \
  -in "${AGENT_FACTORY_EDGE_TLS_DIR}/server.crt" \
  -noout \
  -checkhost "${AGENT_FACTORY_EDGE_SERVER_NAME}" >/dev/null ||
  die "Agent Factory edge certificate does not cover ${AGENT_FACTORY_EDGE_SERVER_NAME}"

if ss -ltn | grep -Eq ':8443[[:space:]]'; then
  die "Legacy Agent Factory edge port 8443 is still published"
fi

"$(dirname "${BASH_SOURCE[0]}")/agent-factory-edge-smoke-test.sh"
printf 'Edge completion validation passed.\n'
