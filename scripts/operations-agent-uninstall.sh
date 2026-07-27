#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

[[ "${1:-}" == '--confirm' ]] ||
  die 'This removes operational history; rerun with --confirm'

{
  printf 'define oracle_pdb = %s\n' "${ORACLE_PDB}"
  printf 'define app_schema = %s\n' "${MCP_SOURCE_SCHEMA}"
  cat "${PROJECT_ROOT}/sql/operations-agent/uninstall.sql"
} | "${PROJECT_ROOT}/scripts/oracle-sqlplus.sh"

printf 'Removed the operations-agent repository from %s.\n' \
  "${MCP_SOURCE_SCHEMA}"
