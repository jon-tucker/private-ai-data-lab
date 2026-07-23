#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

printf 'connmgr list\nexit\n' |
  compose --profile mcp run --rm -T mcp /nolog
