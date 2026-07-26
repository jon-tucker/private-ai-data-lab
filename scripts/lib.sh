#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

load_env() {
  [[ -f "${ENV_FILE}" ]] || die "Missing ${ENV_FILE}; copy .env.example to .env first"
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
  export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-oracle-ai-data-platform}"
  export PLATFORM_DATA_ROOT="${PLATFORM_DATA_ROOT:-/srv/oracle-ai-data}"
  export PLATFORM_SECRETS_ROOT="${PLATFORM_SECRETS_ROOT:-/srv/oracle-ai-secrets}"
  export ORACLE_DATABASE_CONTAINER="${ORACLE_DATABASE_CONTAINER:-oracle-ai-database}"
  export ORACLE_PASSWORD_FILE="${ORACLE_PASSWORD_FILE:-${PLATFORM_SECRETS_ROOT}/oracle-db-password}"
  export OLLAMA_ACCELERATOR="${OLLAMA_ACCELERATOR:-rocm}"
  export OLLAMA_CONTAINER="${OLLAMA_CONTAINER:-oracle-ai-ollama}"
  export OPEN_WEBUI_CONTAINER="${OPEN_WEBUI_CONTAINER:-oracle-ai-open-webui}"
  export OPEN_WEBUI_SECRET_FILE="${OPEN_WEBUI_SECRET_FILE:-${PLATFORM_SECRETS_ROOT}/open-webui-secret-key}"
  export ORDS_CONTAINER="${ORDS_CONTAINER:-oracle-ai-ords}"
  export ORDS_INSTALL_CONTAINER="${ORDS_INSTALL_CONTAINER:-oracle-ai-ords-install}"
  export ORDS_CONFIG_DIR="${ORDS_CONFIG_DIR:-${PLATFORM_DATA_ROOT}/ords}"
  export ORDS_PUBLIC_PASSWORD_FILE="${ORDS_PUBLIC_PASSWORD_FILE:-${PLATFORM_SECRETS_ROOT}/ords-public-user-password}"
  export ORDS_URL="${ORDS_URL:-http://127.0.0.1:8080/ords/}"
  export APEX_VERSION="${APEX_VERSION:-26.1}"
  export APEX_SOURCE_DIR="${APEX_SOURCE_DIR:-/srv/oracle-ai-work/apex/apex}"
  export APEX_IMAGES_DIR="${APEX_IMAGES_DIR:-${PLATFORM_DATA_ROOT}/apex/images}"
  export APEX_CONTAINER_SOURCE_DIR="${APEX_CONTAINER_SOURCE_DIR:-/opt/oracle/apex-26.1}"
  export APEX_TABLESPACE="${APEX_TABLESPACE:-APEX}"
  export APEX_FILES_TABLESPACE="${APEX_FILES_TABLESPACE:-APEX_FILES}"
  export APEX_ADMIN_USERNAME="${APEX_ADMIN_USERNAME:-ADMIN}"
  export APEX_URL="${APEX_URL:-${ORDS_URL}}"
  export MCP_SQLCL_IMAGE="${MCP_SQLCL_IMAGE:-container-registry.oracle.com/database/sqlcl:26.2.0}"
  export MCP_SQLCL_HOME="${MCP_SQLCL_HOME:-${PLATFORM_DATA_ROOT}/mcp/sqlcl-home}"
  export MCP_DATABASE_PASSWORD_FILE="${MCP_DATABASE_PASSWORD_FILE:-${PLATFORM_SECRETS_ROOT}/mcp-database-password}"
  export MCP_DATABASE_USER="${MCP_DATABASE_USER:-ORACLE_AI_MCP}"
  export MCP_DATABASE_ROLE="${MCP_DATABASE_ROLE:-ORACLE_AI_MCP_READ_ROLE}"
  export MCP_CONNECTION_NAME="${MCP_CONNECTION_NAME:-oracle_ai_readonly}"
  export MCP_SOURCE_SCHEMA="${MCP_SOURCE_SCHEMA:-ORACLE_AI}"
  export MCP_RESTRICT_LEVEL="${MCP_RESTRICT_LEVEL:-4}"
  export MCP_UID="${MCP_UID:-54321}"
  export MCP_GID="${MCP_GID:-54321}"
  export MCP_HTTP_IMAGE="${MCP_HTTP_IMAGE:-oracle-ai/sqlcl-mcp-http:26.2.0}"
  export MCP_HTTP_CONTAINER="${MCP_HTTP_CONTAINER:-oracle-ai-sqlcl-mcp-http}"
  export MCP_NODEJS_STREAM="${MCP_NODEJS_STREAM:-22}"
  export MCP_SUPERGATEWAY_VERSION="${MCP_SUPERGATEWAY_VERSION:-3.4.3}"
  export MCP_HTTP_SESSION_TIMEOUT_MS="${MCP_HTTP_SESSION_TIMEOUT_MS:-600000}"
  export MCP_TLS_IMAGE="${MCP_TLS_IMAGE:-nginx:1.30.4-alpine3.24}"
  export MCP_TLS_CONTAINER="${MCP_TLS_CONTAINER:-oracle-ai-sqlcl-mcp-tls}"
  export MCP_TLS_DIR="${MCP_TLS_DIR:-${PLATFORM_SECRETS_ROOT}/mcp-tls}"
  export MCP_NGINX_CONFIG="${MCP_NGINX_CONFIG:-${PLATFORM_DATA_ROOT}/mcp/nginx.conf}"
  export MCP_HTTPS_HOST_BIND="${MCP_HTTPS_HOST_BIND:-192.168.122.1}"
  export MCP_HTTPS_PORT="${MCP_HTTPS_PORT:-8182}"
  export PLATFORM_UID="${PLATFORM_UID:-$(id -u)}"
  export PLATFORM_GID="${PLATFORM_GID:-$(id -g)}"
  export AGENT_FACTORY_VERSION="${AGENT_FACTORY_VERSION:-26.4.0}"
  export AGENT_FACTORY_VM_NAME="${AGENT_FACTORY_VM_NAME:-agent-factory}"
  export AGENT_FACTORY_VM_IP="${AGENT_FACTORY_VM_IP:-192.168.122.202}"
  export AGENT_FACTORY_VM_USER="${AGENT_FACTORY_VM_USER:-jon}"
  export AGENT_FACTORY_VM_URI="${AGENT_FACTORY_VM_URI:-qemu:///system}"
  export AGENT_FACTORY_OS_DISK="${AGENT_FACTORY_OS_DISK:-${PLATFORM_DATA_ROOT}/vms/agent-factory-ol8.qcow2}"
  export AGENT_FACTORY_BUILD_DISK="${AGENT_FACTORY_BUILD_DISK:-${PLATFORM_DATA_ROOT}/vms/agent-factory-build.qcow2}"
  export AGENT_FACTORY_DB_USER="${AGENT_FACTORY_DB_USER:-AGENT_FACTORY}"
  export AGENT_FACTORY_DB_READ_USER="${AGENT_FACTORY_DB_READ_USER:-AAI_RO_AGENT_FACTORY}"
  export AGENT_FACTORY_DB_PASSWORD_FILE="${AGENT_FACTORY_DB_PASSWORD_FILE:-${PLATFORM_SECRETS_ROOT}/agent-factory-db-password}"
  export AGENT_FACTORY_OLLAMA_URL="${AGENT_FACTORY_OLLAMA_URL:-http://192.168.122.1:11434}"
  export AGENT_FACTORY_STAGE_ROOT="${AGENT_FACTORY_STAGE_ROOT:-/u01/agent-factory}"
  export AGENT_FACTORY_INSTALL_DIR="${AGENT_FACTORY_INSTALL_DIR:-${AGENT_FACTORY_STAGE_ROOT}/staging/26.4.0-initial}"
  export AGENT_FACTORY_PORT="${AGENT_FACTORY_PORT:-8080}"
  export AGENT_OPERATIONS_BACKUP_ROOT="${AGENT_OPERATIONS_BACKUP_ROOT:-${PLATFORM_DATA_ROOT}/backups/agent-operations}"
  export AGENT_OPERATIONS_CERT_WARN_DAYS="${AGENT_OPERATIONS_CERT_WARN_DAYS:-90}"
  export AGENT_OPERATIONS_DISK_WARN_PERCENT="${AGENT_OPERATIONS_DISK_WARN_PERCENT:-80}"
  export AGENT_OPERATIONS_VM_SHUTDOWN_TIMEOUT="${AGENT_OPERATIONS_VM_SHUTDOWN_TIMEOUT:-300}"
}

compose() {
  docker compose --project-directory "${PROJECT_ROOT}" --env-file "${ENV_FILE}" "$@"
}
