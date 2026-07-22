#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
model="${1:-${OLLAMA_DEFAULT_MODEL:-qwen3:4b}}"
docker exec -it "${OLLAMA_CONTAINER}" ollama run "${model}"
