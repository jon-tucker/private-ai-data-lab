#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

compose --profile livestack ps livestack
docker inspect \
  --format 'health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} status={{.State.Status}} restart={{.HostConfig.RestartPolicy.Name}} image={{.Config.Image}}' \
  "${LIVESTACK_CONTAINER}"
docker port "${LIVESTACK_CONTAINER}" 3001/tcp
