#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

[[ "${AGENT_FACTORY_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  die 'AGENT_FACTORY_VERSION must use major.minor.patch format'
[[ "${AGENT_FACTORY_VM_NAME}" =~ ^[A-Za-z0-9_-]+$ ]] ||
  die 'AGENT_FACTORY_VM_NAME contains unsupported characters'
[[ "${AGENT_FACTORY_VM_IP}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  die 'AGENT_FACTORY_VM_IP must be an IPv4 address'
[[ "${AGENT_FACTORY_DB_USER}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'AGENT_FACTORY_DB_USER must be an uppercase simple Oracle identifier'
[[ "${AGENT_FACTORY_DB_READ_USER}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'AGENT_FACTORY_DB_READ_USER must be an uppercase simple Oracle identifier'
[[ "${AGENT_FACTORY_DB_READ_USER}" == "AAI_RO_${AGENT_FACTORY_DB_USER}" ]] ||
  die 'AGENT_FACTORY_DB_READ_USER must equal AAI_RO_<AGENT_FACTORY_DB_USER>'
[[ -r "${AGENT_FACTORY_DB_PASSWORD_FILE}" ]] ||
  die "Agent Factory database password is missing: ${AGENT_FACTORY_DB_PASSWORD_FILE}"
[[ "$(stat -c '%a' "${AGENT_FACTORY_DB_PASSWORD_FILE}")" == '600' ]] ||
  die 'Agent Factory database password must have mode 0600'

printf 'Agent Factory configuration validation passed for version %s.\n' \
  "${AGENT_FACTORY_VERSION}"
