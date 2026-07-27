#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

name="${1:-}"
shift || true
[[ -n "${name}" && "$#" -gt 0 ]] ||
  die 'Usage: observability-run.sh NAME COMMAND [ARGUMENT ...]'

require_command curl

output_file="$(mktemp)"
started_utc="$(date -u +'%Y-%m-%dT%H:%M:%S+00:00')"
cleanup() {
  rm -f "${output_file}"
}
trap cleanup EXIT

set +e
"$@" 2>&1 | tee "${output_file}"
result=${PIPESTATUS[0]}
set -e

if [[ "${OPERATIONS_AGENT_ENABLED}" == '1' &&
      -x "${PROJECT_ROOT}/scripts/operations-agent-record.sh" ]]; then
  if ! "${PROJECT_ROOT}/scripts/operations-agent-record.sh" \
    "${name}" "${result}" "${output_file}" "${started_utc}"; then
    printf 'WARN: operational repository recording failed\n' >&2
  fi
fi

if ((result == 0)); then
  printf 'OBSERVABILITY_OK name=%s\n' "${name}"
  exit 0
fi

printf 'OBSERVABILITY_FAILURE name=%s exit=%d\n' "${name}" "${result}" >&2

if [[ -s "${OBSERVABILITY_WEBHOOK_URL_FILE}" ]]; then
  require_command python3
  webhook_url="$(<"${OBSERVABILITY_WEBHOOK_URL_FILE}")"
  payload="$(
    python3 - "${name}" "${result}" "${output_file}" <<'PY'
import json
import socket
import sys
from pathlib import Path

name, result, output_path = sys.argv[1:]
output = Path(output_path).read_text(errors="replace")[-6000:]
print(json.dumps({
    "text": (
        f"Oracle AI observability failure on {socket.gethostname()}: "
        f"{name} exited {result}\n{output}"
    )
}))
PY
  )"
  if ! curl --fail --silent --show-error \
    --connect-timeout 10 \
    --max-time 30 \
    -H 'Content-Type: application/json' \
    --data "${payload}" \
    "${webhook_url}" >/dev/null; then
    printf 'WARN: webhook notification failed\n' >&2
  fi
else
  printf 'INFO: webhook notification is not configured\n' >&2
fi

exit "${result}"
