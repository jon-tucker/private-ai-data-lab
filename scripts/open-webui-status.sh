#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
compose --profile "${OLLAMA_ACCELERATOR}" ps open-webui
docker inspect --format 'health={{if .State.Health}}{{.State.Health.Status}}{{else}}not-defined{{end}} status={{.State.Status}} started={{.State.StartedAt}}' "${OPEN_WEBUI_CONTAINER}" 2>/dev/null || true
