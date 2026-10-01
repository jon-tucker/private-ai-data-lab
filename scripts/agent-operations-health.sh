#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

require_command curl
require_command docker
require_command openssl
require_command ssh
require_command virsh

failures=0
warnings=0

pass() {
  printf 'PASS: %s\n' "$*"
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  failures=$((failures + 1))
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
  warnings=$((warnings + 1))
}

check_container() {
  local name="$1"
  local state
  local health

  state="$(docker inspect --format '{{.State.Status}}' "${name}" 2>/dev/null || true)"
  health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "${name}" 2>/dev/null || true)"

  if [[ "${state}" == 'running' && ( "${health}" == 'healthy' || "${health}" == 'none' ) ]]; then
    pass "container ${name} state=${state} health=${health}"
  else
    fail "container ${name} state=${state:-missing} health=${health:-unknown}"
  fi
}

printf '=== Container services ===\n'
check_container "${ORACLE_DATABASE_CONTAINER}"
check_container "${OLLAMA_CONTAINER}"
check_container "${LITELLM_CONTAINER}"
check_container "${LITELLM_TLS_CONTAINER}"
check_container "${MCP_HTTP_CONTAINER}"
check_container "${MCP_TLS_CONTAINER}"
if docker inspect "${LIVESTACK_CONTAINER}" >/dev/null 2>&1; then
  check_container "${LIVESTACK_CONTAINER}"
  livestack_health="$(
    curl --fail --silent --show-error --max-time 10 \
      "http://${LIVESTACK_HOST_BIND}:${LIVESTACK_PORT}/api/health" \
      2>/dev/null || true
  )"
  if [[ "${livestack_health}" == *'"status":"healthy"'* ]]; then
    pass 'LiveStack loopback application and database connection are healthy'
  else
    fail 'LiveStack loopback health check failed'
  fi
fi
if docker inspect "${LIVESTACK_EDGE_CONTAINER}" >/dev/null 2>&1; then
  check_container "${LIVESTACK_EDGE_CONTAINER}"
  livestack_edge_health="$(
    curl --fail --silent --show-error --max-time 10 \
      --cacert "${LIVESTACK_EDGE_TLS_DIR}/ca.crt" \
      "https://${LIVESTACK_EDGE_HOST_BIND}:${LIVESTACK_EDGE_PORT}/api/health" \
      2>/dev/null || true
  )"
  if [[ "${livestack_edge_health}" == *'"status":"healthy"'* ]]; then
    pass 'LiveStack trusted HTTPS edge and database connection are healthy'
  else
    fail 'LiveStack trusted HTTPS edge health check failed'
  fi
fi

printf '\n=== Agent Factory VM and application ===\n'
vm_state="$(virsh -c "${AGENT_FACTORY_VM_URI}" domstate "${AGENT_FACTORY_VM_NAME}" 2>/dev/null || true)"
if [[ "${vm_state}" == 'running' ]]; then
  pass "VM ${AGENT_FACTORY_VM_NAME} is running"
else
  fail "VM ${AGENT_FACTORY_VM_NAME} state=${vm_state:-unknown}"
fi

if timeout 3 bash -c "</dev/tcp/${AGENT_FACTORY_VM_IP}/22" 2>/dev/null; then
  pass "Agent Factory SSH endpoint ${AGENT_FACTORY_VM_IP}:22 is reachable"
else
  fail "Agent Factory SSH endpoint ${AGENT_FACTORY_VM_IP}:22 is unreachable"
fi

agent_status="$(
  curl --silent --show-error \
    --cacert "${AGENT_FACTORY_EDGE_DATA_DIR}/upstream.crt" \
    --output /dev/null \
    --write-out '%{http_code}' \
    "https://${AGENT_FACTORY_VM_IP}:${AGENT_FACTORY_PORT}/agentFactory/" \
    2>/dev/null || true
)"
if [[ "${agent_status}" == '200' ]]; then
  pass 'Agent Factory application returned HTTP 200'
else
  fail "Agent Factory application returned HTTP ${agent_status:-000}"
fi

if [[ -n "${AGENT_FACTORY_EDGE_CONTAINER:-}" ]]; then
  check_container "${AGENT_FACTORY_EDGE_CONTAINER}"
  edge_status="$(
    curl --silent --show-error \
      --cacert "${AGENT_FACTORY_EDGE_TLS_DIR}/ca.crt" \
      --output /dev/null \
      --write-out '%{http_code}' \
      "https://${AGENT_FACTORY_EDGE_HOST_BIND}:${AGENT_FACTORY_EDGE_PORT}/agentFactory/" \
      2>/dev/null || true
  )"
  if [[ "${edge_status}" == '200' ]]; then
    pass 'Agent Factory browser edge returned HTTP 200'
  else
    fail "Agent Factory browser edge returned HTTP ${edge_status:-000}"
  fi
fi

printf '\n=== Private MCP HTTPS ===\n'
mcp_health="$(
  curl --fail --silent --show-error \
    --cacert "${MCP_TLS_DIR}/ca.crt" \
    "https://${MCP_HTTPS_HOST_BIND}:${MCP_HTTPS_PORT}/healthz" \
    2>/dev/null || true
)"
if [[ "${mcp_health}" == 'ok' ]]; then
  pass 'SQLcl MCP private HTTPS endpoint is trusted and healthy'
else
  fail 'SQLcl MCP private HTTPS endpoint health check failed'
fi

printf '\n=== Certificate lifetime ===\n'
warn_seconds=$((AGENT_OPERATIONS_CERT_WARN_DAYS * 86400))
if openssl x509 -checkend "${warn_seconds}" -noout \
  -in "${MCP_TLS_DIR}/server.crt" >/dev/null; then
  expiry="$(openssl x509 -enddate -noout -in "${MCP_TLS_DIR}/server.crt" | cut -d= -f2-)"
  pass "MCP TLS certificate remains valid beyond ${AGENT_OPERATIONS_CERT_WARN_DAYS} days; expires ${expiry}"
else
  warn "MCP TLS certificate expires within ${AGENT_OPERATIONS_CERT_WARN_DAYS} days"
fi

if openssl x509 -checkend "${warn_seconds}" -noout \
  -in "${LITELLM_TLS_DIR}/server.crt" >/dev/null; then
  expiry="$(openssl x509 -enddate -noout -in "${LITELLM_TLS_DIR}/server.crt" | cut -d= -f2-)"
  pass "LiteLLM TLS certificate remains valid beyond ${AGENT_OPERATIONS_CERT_WARN_DAYS} days; expires ${expiry}"
else
  warn "LiteLLM TLS certificate expires within ${AGENT_OPERATIONS_CERT_WARN_DAYS} days"
fi

if openssl x509 -checkend "${warn_seconds}" -noout \
  -in "${AGENT_FACTORY_EDGE_TLS_DIR}/server.crt" >/dev/null; then
  expiry="$(openssl x509 -enddate -noout -in "${AGENT_FACTORY_EDGE_TLS_DIR}/server.crt" | cut -d= -f2-)"
  pass "Agent Factory edge TLS certificate remains valid beyond ${AGENT_OPERATIONS_CERT_WARN_DAYS} days; expires ${expiry}"
else
  warn "Agent Factory edge TLS certificate expires within ${AGENT_OPERATIONS_CERT_WARN_DAYS} days"
fi

if [[ -s "${LIVESTACK_EDGE_TLS_DIR}/server.crt" ]]; then
  if openssl x509 -checkend "${warn_seconds}" -noout \
    -in "${LIVESTACK_EDGE_TLS_DIR}/server.crt" >/dev/null; then
    expiry="$(openssl x509 -enddate -noout -in "${LIVESTACK_EDGE_TLS_DIR}/server.crt" | cut -d= -f2-)"
    pass "LiveStack edge TLS certificate remains valid beyond ${AGENT_OPERATIONS_CERT_WARN_DAYS} days; expires ${expiry}"
  else
    warn "LiveStack edge TLS certificate expires within ${AGENT_OPERATIONS_CERT_WARN_DAYS} days"
  fi
fi

printf '\n=== Storage capacity ===\n'
usage_percent="$(
  df -P "${PLATFORM_DATA_ROOT}" |
    awk 'NR == 2 {gsub(/%/, "", $5); print $5}'
)"
if ((usage_percent >= AGENT_OPERATIONS_DISK_WARN_PERCENT)); then
  warn "platform filesystem usage=${usage_percent}% threshold=${AGENT_OPERATIONS_DISK_WARN_PERCENT}%"
else
  pass "platform filesystem usage=${usage_percent}% threshold=${AGENT_OPERATIONS_DISK_WARN_PERCENT}%"
fi

printf '\n=== Summary ===\n'
printf 'failures=%d warnings=%d\n' "${failures}" "${warnings}"
((failures == 0)) || exit 1
