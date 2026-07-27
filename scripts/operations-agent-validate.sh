#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

[[ "${OPERATIONS_AGENT_ENABLED}" =~ ^[01]$ ]] ||
  die 'OPERATIONS_AGENT_ENABLED must be 0 or 1'
[[ "${OPERATIONS_AGENT_RETENTION_DAYS}" =~ ^[1-9][0-9]*$ ]] ||
  die 'OPERATIONS_AGENT_RETENTION_DAYS must be a positive integer'
[[ "${MCP_SOURCE_SCHEMA}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'MCP_SOURCE_SCHEMA must be an uppercase simple Oracle identifier'

printf 'Operations-agent configuration validation passed.\n'
