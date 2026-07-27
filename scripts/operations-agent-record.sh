#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

name="${1:-}"
result="${2:-}"
output_file="${3:-}"
started_utc="${4:-}"

[[ "${name}" =~ ^(backup|health)$ ]] ||
  die 'Run name must be backup or health'
[[ "${result}" =~ ^[0-9]+$ ]] ||
  die 'Result must be a non-negative integer'
[[ -r "${output_file}" ]] ||
  die "Output file is not readable: ${output_file}"
[[ "${started_utc}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]] ||
  die 'Started timestamp must be an ISO-8601 UTC value'
[[ "${ORACLE_PDB}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'ORACLE_PDB must be an uppercase simple Oracle identifier'
[[ "${MCP_SOURCE_SCHEMA}" =~ ^[A-Z][A-Z0-9_]{0,29}$ ]] ||
  die 'MCP_SOURCE_SCHEMA must be an uppercase simple Oracle identifier'

require_command python3

sql_file="$(mktemp)"
sql_output="$(mktemp)"
cleanup() {
  rm -f "${sql_file}" "${sql_output}"
}
trap cleanup EXIT

python3 - "${name}" "${result}" "${output_file}" "${started_utc}" \
  "${ORACLE_PDB}" "${MCP_SOURCE_SCHEMA}" >"${sql_file}" <<'PY'
import re
import socket
import sys
from datetime import datetime, timezone
from pathlib import Path

name, result_text, output_path, started, pdb, schema = sys.argv[1:]
result = int(result_text)
text = Path(output_path).read_text(errors="replace")
now = datetime.now(timezone.utc).isoformat(timespec="seconds")

checks = []
for line in text.splitlines():
    match = re.match(r"^(PASS|WARN|FAIL):\s*(.+)$", line)
    if match:
        checks.append((match.group(1), match.group(2)[:1000]))

failure_match = re.findall(r"failures=(\d+)", text)
warning_match = re.findall(r"warnings=(\d+)", text)
failure_count = int(failure_match[-1]) if failure_match else sum(
    status == "FAIL" for status, _ in checks
)
warning_count = int(warning_match[-1]) if warning_match else sum(
    status == "WARN" for status, _ in checks
)
status = "FAIL" if result else ("WARN" if warning_count else "PASS")
excerpt = text[-3000:].replace("\r", "").replace("\n", "\\n")

def literal(value):
    if value is None:
        return "null"
    return "'" + str(value).replace("'", "''") + "'"

print("whenever sqlerror exit failure rollback")
print("set define off")
print(f"alter session set container = {pdb};")
print("variable run_id number")
print(
    f"insert into {schema}.operations_run ("
    "run_name, started_utc, completed_utc, result_status, exit_code, "
    "failure_count, warning_count, host_name, output_excerpt"
    ") values ("
    f"{literal(name)}, to_timestamp_tz({literal(started)}, "
    "'YYYY-MM-DD\"T\"HH24:MI:SSTZH:TZM'), "
    f"to_timestamp_tz({literal(now)}, "
    "'YYYY-MM-DD\"T\"HH24:MI:SSTZH:TZM'), "
    f"{literal(status)}, {result}, {failure_count}, {warning_count}, "
    f"{literal(socket.gethostname())}, {literal(excerpt)}"
    ") returning run_id into :run_id;"
)
for sequence, (check_status, message) in enumerate(checks, 1):
    print(
        f"insert into {schema}.operations_check ("
        "run_id, check_sequence, check_status, check_message"
        f") values (:run_id, {sequence}, {literal(check_status)}, "
        f"{literal(message)});"
    )

if name == "backup":
    path_matches = re.findall(r"Cold backup completed:\s*(\S+)", text)
    if path_matches:
        recovery_path = path_matches[-1]
        manifest = Path(recovery_path) / "MANIFEST.txt"
        metadata = {}
        if manifest.is_file():
            for line in manifest.read_text(errors="replace").splitlines():
                key, separator, value = line.partition("=")
                if separator:
                    metadata[key] = value
        created = metadata.get("created_utc")
        created_sql = "null"
        if created and re.fullmatch(r"\d{8}T\d{6}Z", created):
            created_sql = (
                f"from_tz(to_timestamp({literal(created)}, "
                "'YYYYMMDD\"T\"HH24MISS\"Z\"'), 'UTC')"
            )
        dirty = metadata.get("git_worktree_dirty")
        dirty = "Y" if dirty == "true" else "N" if dirty == "false" else None
        print(
            f"insert into {schema}.backup_catalog ("
            "run_id, recovery_set_path, created_utc, git_commit, "
            "git_worktree_dirty, verified_status"
            f") values (:run_id, {literal(recovery_path)}, {created_sql}, "
            f"{literal(metadata.get('git_commit'))}, {literal(dirty)}, "
            "'NOT_VERIFIED');"
        )

print("commit;")
print("exit")
PY

if ! "${PROJECT_ROOT}/scripts/oracle-sqlplus.sh" \
  <"${sql_file}" >"${sql_output}" 2>&1; then
  cat "${sql_output}" >&2
  exit 1
fi
printf 'Recorded operational run: name=%s result=%s\n' "${name}" "${result}"
