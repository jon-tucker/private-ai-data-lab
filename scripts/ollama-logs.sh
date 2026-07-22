#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
compose --profile "${OLLAMA_ACCELERATOR}" logs --follow --tail 100 "ollama-${OLLAMA_ACCELERATOR}"
