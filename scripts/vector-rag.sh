#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command docker

[[ "${MCP_SOURCE_SCHEMA}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'MCP_SOURCE_SCHEMA must be an uppercase simple Oracle identifier'
[[ "${ORACLE_PDB}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'ORACLE_PDB must be an uppercase simple Oracle identifier'

action="${1:-}"
case "${action}" in
  install) sql_file="install.sql"; expected_args=1 ;;
  verify) sql_file="verify.sql"; expected_args=1 ;;
  queries) sql_file="queries.sql"; expected_args=1 ;;
  uninstall) sql_file="uninstall.sql"; expected_args=2 ;;
  uninstall-model) sql_file="uninstall-model.sql"; expected_args=2 ;;
  *) die 'Usage: vector-rag.sh {install|verify|queries|uninstall --confirm|uninstall-model --confirm}' ;;
esac

[[ "$#" -eq "${expected_args}" ]] ||
  die "Usage for ${action}: vector-rag.sh ${action}$([[ ${expected_args} -eq 2 ]] && printf ' --confirm')"
if [[ "${expected_args}" -eq 2 && "${2}" != "--confirm" ]]; then
  die "${action} removes database objects; repeat with --confirm"
fi

container_state="$(docker inspect --format '{{.State.Status}}' "${ORACLE_DATABASE_CONTAINER}" 2>/dev/null || true)"
container_health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "${ORACLE_DATABASE_CONTAINER}" 2>/dev/null || true)"
[[ "${container_state}" == running && "${container_health}" == healthy ]] ||
  die "Database must already be running and healthy; this command will not start it"

sql_path="${PROJECT_ROOT}/sql/vector-rag/${sql_file}"
[[ -r "${sql_path}" ]] || die "Missing SQL file: ${sql_path}"

{
  printf 'define oracle_pdb = %s\n' "${ORACLE_PDB}"
  printf 'define app_schema = %s\n' "${MCP_SOURCE_SCHEMA}"
  cat "${sql_path}"
} | "${PROJECT_ROOT}/scripts/oracle-sqlplus.sh"
