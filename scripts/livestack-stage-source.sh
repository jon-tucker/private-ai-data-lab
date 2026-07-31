#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

require_command unzip
require_command find

[[ -f "${LIVESTACK_ARCHIVE}" ]] || die "LiveStack archive not found: ${LIVESTACK_ARCHIVE}"
[[ ! -e "${LIVESTACK_SOURCE_DIR}" ]] || die "Staging target already exists: ${LIVESTACK_SOURCE_DIR}"

while IFS= read -r entry; do
  case "${entry}" in
    /* | ../* | */../* | */..)
      die "Archive contains unsafe path: ${entry}"
      ;;
  esac
done < <(unzip -Z1 "${LIVESTACK_ARCHIVE}")

stage_parent="$(dirname "${LIVESTACK_SOURCE_DIR}")"
mkdir -p "${stage_parent}"
temporary="$(mktemp -d "${stage_parent}/.stage.XXXXXX")"
trap 'rm -rf -- "${temporary}"' EXIT

unzip -q "${LIVESTACK_ARCHIVE}" -d "${temporary}"
source_root="${temporary}/utilities"
[[ -f "${source_root}/Containerfile" ]] || die "Expected utilities/Containerfile was not found"
[[ -f "${source_root}/package-lock.json" ]] || die "Expected package lock was not found"

find "${source_root}" -type f \( -name '.env' -o -name '.DS_Store' -o -name '._*' \) -delete
find "${temporary}" -type d -name '__MACOSX' -prune -exec rm -rf -- {} +

# The platform does not use the vendor orchestration or privileged bootstrap.
# Remove these files so their demonstration credentials and unsafe grants
# cannot be invoked from the sanitized application source.
for prohibited in \
  .env.example \
  compose.yml \
  compose.deploy.yml \
  scripts/bootstrap_db.sh \
  db/schema/00_setup.sql
do
  if [[ -e "${source_root}/${prohibited}" ]]; then
    find "${source_root}/${prohibited}" -depth -delete
  fi
done

python3 - "${source_root}/backend/config/database.js" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
text = text.replace("const oracledb = require('oracledb');",
                    "const oracledb = require('oracledb');\nconst fs = require('fs');")
new = """password: process.env.APP_SCHEMA_PASSWORD_FILE
      ? fs.readFileSync(process.env.APP_SCHEMA_PASSWORD_FILE, 'utf8').trim()
      : process.env.APP_SCHEMA_PASSWORD,"""
text, replacements = re.subn(
    r"password:\s*process\.env\.APP_SCHEMA_PASSWORD\s*\|\|\s*'[^']*',",
    new,
    text,
    count=1,
)
if replacements != 1:
    raise SystemExit("Expected database password default was not found")
path.write_text(text)
PY

mv "${source_root}" "${LIVESTACK_SOURCE_DIR}"
printf 'Staged sanitized LiveStack source: %s\n' "${LIVESTACK_SOURCE_DIR}"
printf 'No database schema was created and no container was started.\n'
