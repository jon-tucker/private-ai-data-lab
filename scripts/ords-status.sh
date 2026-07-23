#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
compose ps ords
docker inspect --format 'health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} status={{.State.Status}} started={{.State.StartedAt}}' "${ORDS_CONTAINER}" 2>/dev/null || true
