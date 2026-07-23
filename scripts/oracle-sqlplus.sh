#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
docker_options=(-i)
if [[ -t 0 && -t 1 ]]; then
  docker_options=(-it)
fi

docker exec "${docker_options[@]}" "${ORACLE_DATABASE_CONTAINER}" sqlplus / as sysdba
