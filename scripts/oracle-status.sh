#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
compose ps oracle-db
docker inspect --format 'health={{if .State.Health}}{{.State.Health.Status}}{{else}}not-defined{{end}} status={{.State.Status}} started={{.State.StartedAt}}' "${ORACLE_DATABASE_CONTAINER}" 2>/dev/null || true
