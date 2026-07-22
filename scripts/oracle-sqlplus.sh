#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
docker exec -it "${ORACLE_DATABASE_CONTAINER}" sqlplus / as sysdba
