#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
compose --profile agent-factory-edge ps agent-factory-edge
docker inspect "${AGENT_FACTORY_EDGE_CONTAINER}" \
  --format 'health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} status={{.State.Status}}'
