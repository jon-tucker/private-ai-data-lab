#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
compose --profile model-gateway ps litellm litellm-tls
docker inspect "${LITELLM_TLS_CONTAINER}" \
  --format 'health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} status={{.State.Status}} started={{.State.StartedAt}}'
openssl x509 -noout -subject -issuer -enddate \
  -in "${LITELLM_TLS_DIR}/server.crt"
