#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

[[ "${AGENT_FACTORY_VM_IP}" =~ ^[0-9a-fA-F:.]+$ ]] ||
  die 'AGENT_FACTORY_VM_IP must be an IP address'

template="${PROJECT_ROOT}/stacks/mcp/nginx.conf.template"
[[ -r "${template}" ]] || die "Missing Nginx template: ${template}"

rendered="$(mktemp)"
trap 'rm -f "${rendered}"' EXIT

sed \
  -e "s|@@MCP_HTTPS_HOST_BIND@@|${MCP_HTTPS_HOST_BIND}|g" \
  -e "s|@@AGENT_FACTORY_VM_IP@@|${AGENT_FACTORY_VM_IP}|g" \
  "${template}" >"${rendered}"

grep -q '@@' "${rendered}" &&
  die 'Unresolved placeholder remains in rendered MCP Nginx configuration'

sudo install -d \
  -o "${PLATFORM_UID}" \
  -g "${PLATFORM_GID}" \
  -m 0750 \
  "$(dirname "${MCP_NGINX_CONFIG}")"
sudo install \
  -o "${PLATFORM_UID}" \
  -g "${PLATFORM_GID}" \
  -m 0644 \
  "${rendered}" \
  "${MCP_NGINX_CONFIG}"

printf 'Rendered MCP TLS proxy configuration: %s\n' "${MCP_NGINX_CONFIG}"
