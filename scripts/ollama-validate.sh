#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command docker
docker info >/dev/null

case "${OLLAMA_ACCELERATOR}" in
  rocm)
    [[ -c /dev/kfd ]] || die 'ROCm profile requires /dev/kfd'
    [[ -d /dev/dri ]] || die 'ROCm profile requires /dev/dri'
    [[ -c /dev/dri/renderD128 ]] || die 'ROCm profile requires /dev/dri/renderD128'
    ;;
  cpu) ;;
  *) die 'OLLAMA_ACCELERATOR must be rocm or cpu' ;;
esac

[[ -d "${PLATFORM_DATA_ROOT}/ollama" ]] || die 'Ollama data directory is missing; run ollama-prepare-host.sh'
compose --profile "${OLLAMA_ACCELERATOR}" config --quiet
printf 'Ollama configuration validation passed for profile: %s\n' "${OLLAMA_ACCELERATOR}"
