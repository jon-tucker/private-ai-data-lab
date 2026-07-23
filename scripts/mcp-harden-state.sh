#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

[[ -d "${MCP_SQLCL_HOME}" ]] ||
  die "SQLcl home directory is missing: ${MCP_SQLCL_HOME}"

sudo chown -R "${MCP_UID}:${MCP_GID}" "${MCP_SQLCL_HOME}"
sudo find "${MCP_SQLCL_HOME}" -type d -exec chmod 0700 {} +
sudo find "${MCP_SQLCL_HOME}" -type f -exec chmod 0600 {} +
printf 'Hardened SQLcl home directories to 0700 and files to 0600.\n'
