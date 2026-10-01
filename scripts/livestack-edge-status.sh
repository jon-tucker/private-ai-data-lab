#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
compose --profile livestack-edge ps livestack-edge
docker inspect "${LIVESTACK_EDGE_CONTAINER}" \
  --format 'health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} status={{.State.Status}} restart={{.HostConfig.RestartPolicy.Name}}'
