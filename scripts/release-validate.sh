#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

require_command docker
require_command git
require_command jq

printf '=== Operational acceptance ===\n'
"${PROJECT_ROOT}/scripts/platform-readiness-validate.sh"

printf '\n=== Required project documents ===\n'
for file in \
  README.md \
  CHANGELOG.md \
  LICENSE \
  SECURITY.md \
  CONTRIBUTING.md \
  docs/operator-runbook.md \
  docs/release-checklist.md; do
  [[ -s "${PROJECT_ROOT}/${file}" ]] ||
    die "Required project document is missing or empty: ${file}"
  printf 'PASS: %s\n' "${file}"
done

printf '\n=== Tracked-data boundary ===\n'
if git -C "${PROJECT_ROOT}" ls-files |
  grep -Eq '(^|/)(\.env|[^/]*\.(key|pem|p12|pfx|jks|wallet|dbf|dmp|qcow2))$'; then
  git -C "${PROJECT_ROOT}" ls-files |
    grep -E '(^|/)(\.env|[^/]*\.(key|pem|p12|pfx|jks|wallet|dbf|dmp|qcow2))$'
  die "A prohibited secret or generated-data file is tracked"
fi
printf 'PASS: no prohibited secret or generated-data files are tracked\n'

printf '\n=== Container image policy ===\n'
if (
  cd "${PROJECT_ROOT}"
  docker compose \
    --profile model-gateway \
    --profile agent-factory-edge \
    config --format json |
    jq -e '
      [.services[].image | select(test(":(latest|main|master)$"))] |
      length > 0
    ' >/dev/null
); then
  die "A configured container image uses a floating tag"
fi
printf 'PASS: configured container images do not use floating tags\n'

printf '\n=== Repository checks ===\n'
git -C "${PROJECT_ROOT}" fsck --full --no-dangling
git -C "${PROJECT_ROOT}" diff --check
printf 'PASS: repository integrity and whitespace checks passed\n'

printf '\nRELEASE_VALIDATION=PASS\n'
