#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

sudo mkdir -p "${MCP_SQLCL_HOME}"
sudo chown -R "${MCP_UID}:${MCP_GID}" "${MCP_SQLCL_HOME}"
sudo chmod 0700 "${MCP_SQLCL_HOME}"
printf 'Prepared SQLcl home directory: %s\n' "${MCP_SQLCL_HOME}"
