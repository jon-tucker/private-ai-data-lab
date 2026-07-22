#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

install -d -m 755 "${PLATFORM_DATA_ROOT}/ollama"
printf 'Prepared Ollama data directory: %s\n' "${PLATFORM_DATA_ROOT}/ollama"
