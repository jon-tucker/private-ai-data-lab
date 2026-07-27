#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

"${PROJECT_ROOT}/scripts/model-gateway-cutover-validate.sh"
"${PROJECT_ROOT}/scripts/model-gateway-operations-smoke-test.sh"
"${PROJECT_ROOT}/scripts/model-gateway-operations-agent-factory-smoke-test.sh"

compose --profile model-gateway up -d --force-recreate litellm litellm-tls
"${PROJECT_ROOT}/scripts/model-gateway-operations-start.sh"
"${PROJECT_ROOT}/scripts/model-gateway-cutover-smoke-test.sh"

printf 'LiteLLM HTTPS cutover completed; HTTP port 4000 is no longer published.\n'
