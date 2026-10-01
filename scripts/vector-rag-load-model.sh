#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command docker
require_command sha256sum

[[ "$#" -eq 1 ]] || die 'Usage: vector-rag-load-model.sh /path/to/model.onnx'
model_file="$1"
[[ -f "${model_file}" && -r "${model_file}" ]] ||
  die "Model file is not readable: ${model_file}"
[[ "${model_file##*.}" == onnx ]] || die 'The supplied model file must have the .onnx extension'
[[ "${MCP_SOURCE_SCHEMA}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'MCP_SOURCE_SCHEMA must be an uppercase simple Oracle identifier'
[[ "${ORACLE_PDB}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'ORACLE_PDB must be an uppercase simple Oracle identifier'

container_state="$(docker inspect --format '{{.State.Status}}' "${ORACLE_DATABASE_CONTAINER}" 2>/dev/null || true)"
container_health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "${ORACLE_DATABASE_CONTAINER}" 2>/dev/null || true)"
[[ "${container_state}" == running && "${container_health}" == healthy ]] ||
  die "Database must already be running and healthy; this command will not start it"

stage_dir="/tmp/private-ai-vector-rag-model-${BASHPID}"
directory_name="VRA_M_${BASHPID}"
[[ "${directory_name}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'Could not create a safe temporary Oracle directory name'
if docker exec -u 0 "${ORACLE_DATABASE_CONTAINER}" test -e "${stage_dir}"; then
  die "Temporary staging path already exists; refusing to reuse it: ${stage_dir}"
fi

staged=false
cleanup() {
  if [[ "${staged}" == true ]]; then
    docker exec -u 0 "${ORACLE_DATABASE_CONTAINER}" \
      rm -f "${stage_dir}/all_MiniLM_L12_v2.onnx" >/dev/null 2>&1 || true
    docker exec -u 0 "${ORACLE_DATABASE_CONTAINER}" \
      rmdir "${stage_dir}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

printf 'Model SHA-256: '
sha256sum "${model_file}"
docker exec -u 0 "${ORACLE_DATABASE_CONTAINER}" mkdir -m 0755 "${stage_dir}"
staged=true
docker cp "${model_file}" "${ORACLE_DATABASE_CONTAINER}:${stage_dir}/all_MiniLM_L12_v2.onnx" >/dev/null
docker exec -u 0 "${ORACLE_DATABASE_CONTAINER}" \
  chmod 0644 "${stage_dir}/all_MiniLM_L12_v2.onnx"

{
  printf 'define oracle_pdb = %s\n' "${ORACLE_PDB}"
  printf 'define app_schema = %s\n' "${MCP_SOURCE_SCHEMA}"
  printf 'define model_directory_name = %s\n' "${directory_name}"
  printf 'define model_directory_path = %s\n' "${stage_dir}"
  cat "${PROJECT_ROOT}/sql/vector-rag/load-model.sql"
} | "${PROJECT_ROOT}/scripts/oracle-sqlplus.sh"

printf 'Loaded VECTOR_RAG_MINILM into %s. Temporary model files will now be removed.\n' \
  "${MCP_SOURCE_SCHEMA}"
