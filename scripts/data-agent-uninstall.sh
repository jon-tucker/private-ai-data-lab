#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

[[ "${1:-}" == '--confirm' ]] ||
  die 'This removes the v0.10 demonstration objects; rerun with --confirm'
[[ "${MCP_SOURCE_SCHEMA}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'MCP_SOURCE_SCHEMA must be an uppercase simple Oracle identifier'
[[ "${ORACLE_PDB}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'ORACLE_PDB must be an uppercase simple Oracle identifier'

{
  printf 'define oracle_pdb = %s\n' "${ORACLE_PDB}"
  printf 'define app_schema = %s\n' "${MCP_SOURCE_SCHEMA}"
  cat "${PROJECT_ROOT}/sql/data-agent/uninstall.sql"
} | "${PROJECT_ROOT}/scripts/oracle-sqlplus.sh"

printf 'Removed the data-agent demonstration objects from %s.\n' \
  "${MCP_SOURCE_SCHEMA}"
