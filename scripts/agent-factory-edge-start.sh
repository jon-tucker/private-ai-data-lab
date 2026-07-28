#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/agent-factory-edge-validate.sh"
compose --profile agent-factory-edge up -d agent-factory-edge
"${PROJECT_ROOT}/scripts/agent-factory-edge-smoke-test.sh"
