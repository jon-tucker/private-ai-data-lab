#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

printf '%s\n' 'Active model allocation:'
docker exec "${OLLAMA_CONTAINER}" ollama ps
printf '\n%s\n' 'GPU-related startup messages:'
docker logs "${OLLAMA_CONTAINER}" 2>&1 | grep -Ei 'rocm|amdgpu|gfx|gpu|vram|hip' | tail -n 50 || true
