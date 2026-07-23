#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

docker image inspect "${MCP_SQLCL_IMAGE}" \
  --format 'image={{index .RepoTags 0}} digest={{index .RepoDigests 0}}' 2>/dev/null ||
  printf 'SQLcl image is not present locally: %s\n' "${MCP_SQLCL_IMAGE}"

stat -c 'sqlcl_home_owner=%u:%g mode=%a path=%n' "${MCP_SQLCL_HOME}"

printf 'connmgr list\nexit\n' |
  compose --profile mcp run --rm -T mcp /nolog
