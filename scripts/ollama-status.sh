#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
compose --profile "${OLLAMA_ACCELERATOR}" ps "ollama-${OLLAMA_ACCELERATOR}"
docker inspect --format 'health={{if .State.Health}}{{.State.Health.Status}}{{else}}not-defined{{end}} status={{.State.Status}} started={{.State.StartedAt}}' "${OLLAMA_CONTAINER}" 2>/dev/null || true
docker exec "${OLLAMA_CONTAINER}" ollama list 2>/dev/null || true
docker exec "${OLLAMA_CONTAINER}" ollama ps 2>/dev/null || true
