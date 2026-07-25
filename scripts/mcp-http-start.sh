#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
"${PROJECT_ROOT}/scripts/mcp-http-validate.sh"

compose --profile mcp-http up -d --build mcp-http mcp-tls

printf 'Waiting for %s to become healthy' "${MCP_TLS_CONTAINER}"
deadline=$((SECONDS + 300))
status=''
while (( SECONDS < deadline )); do
  status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${MCP_TLS_CONTAINER}" 2>/dev/null || true)"
  case "${status}" in
    healthy)
      printf ' healthy.\n'
      break
      ;;
    unhealthy|exited|dead)
      printf '\n'
      docker logs --tail 150 "${MCP_TLS_CONTAINER}" >&2 || true
      die "MCP TLS container entered state: ${status}"
      ;;
    *)
      printf '.'
      sleep 3
      ;;
  esac
done
[[ "${status}" == healthy ]] || die 'Timed out waiting for the MCP HTTPS bridge'
printf 'SQLcl MCP is ready at https://%s:%s/mcp\n' "${MCP_HTTPS_HOST_BIND}" "${MCP_HTTPS_PORT}"
