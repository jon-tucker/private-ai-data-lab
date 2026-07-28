#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env

require_command docker
require_command ssh
require_command systemctl
require_command virsh

pass() {
  printf 'PASS: %s\n' "$*"
}

printf '=== Runtime health ===\n'
"${PROJECT_ROOT}/scripts/agent-operations-health.sh"
"${PROJECT_ROOT}/scripts/edge-completion-validate.sh"

printf '\n=== Host startup ===\n'
systemctl is-enabled docker >/dev/null ||
  die "Docker is not enabled"
systemctl is-active docker >/dev/null ||
  die "Docker is not active"
pass "Docker is enabled and active"

autostart="$(
  virsh -c "${AGENT_FACTORY_VM_URI}" dominfo "${AGENT_FACTORY_VM_NAME}" |
    awk -F: '/^Autostart:/ {gsub(/^[[:space:]]+/, "", $2); print $2}'
)"
[[ "${autostart}" == 'enable' ]] ||
  die "Agent Factory VM autostart is not enabled"
pass "Agent Factory VM autostart is enabled"

remote="${AGENT_FACTORY_VM_USER}@${AGENT_FACTORY_VM_IP}"
remote_startup="$(
  ssh -T -o BatchMode=yes -o ConnectTimeout=5 "${remote}" '
    systemctl --user is-enabled agentfactory_startstop.service
    loginctl show-user "$USER" -p Linger --value
  '
)"
grep -qx 'enabled' <<<"${remote_startup}" ||
  die "Agent Factory user startup service is not enabled"
grep -qx 'yes' <<<"${remote_startup}" ||
  die "Agent Factory VM user lingering is not enabled"
pass "Agent Factory application startup is persistent"

printf '\n=== Container restart policies ===\n'
mapfile -t containers < <(docker ps --format '{{.Names}}' | sort)
((${#containers[@]} > 0)) || die "No running containers were found"
for container in "${containers[@]}"; do
  policy="$(docker inspect --format '{{.HostConfig.RestartPolicy.Name}}' "${container}")"
  [[ "${policy}" == 'unless-stopped' ]] ||
    die "Container ${container} restart policy is ${policy:-unset}"
  pass "${container} restart policy=unless-stopped"
done

printf '\n=== Scheduled operations ===\n'
for timer in oracle-ai-health.timer oracle-ai-backup.timer; do
  systemctl is-enabled "${timer}" >/dev/null ||
    die "${timer} is not enabled"
  systemctl is-active "${timer}" >/dev/null ||
    die "${timer} is not active"
  pass "${timer} is enabled and active"
done

printf '\n=== Recovery readiness ===\n'
mapfile -t recovery_sets < <(
  find "${AGENT_OPERATIONS_BACKUP_ROOT}" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -printf '%f\n' |
    sort -r
)
((${#recovery_sets[@]} >= BACKUP_LIFECYCLE_MINIMUM_SETS)) ||
  die "Only ${#recovery_sets[@]} recovery sets exist; ${BACKUP_LIFECYCLE_MINIMUM_SETS} required"
pass "${#recovery_sets[@]} recovery sets satisfy minimum=${BACKUP_LIFECYCLE_MINIMUM_SETS}"

latest_set="${AGENT_OPERATIONS_BACKUP_ROOT}/${recovery_sets[0]}"
[[ -f "${latest_set}/VERIFICATION.txt" ]] ||
  die "Newest recovery set is not independently verified: ${latest_set}"
grep -qx 'status=VERIFIED' "${latest_set}/VERIFICATION.txt" ||
  die "Newest recovery-set verification marker is invalid"
pass "Newest recovery set is independently verified: ${recovery_sets[0]}"

printf '\n=== Source validation ===\n'
"${PROJECT_ROOT}/scripts/validate.sh"
"${PROJECT_ROOT}/scripts/backup-lifecycle-validate.sh"
bash -n "${PROJECT_ROOT}"/scripts/*.sh
(
  cd "${PROJECT_ROOT}"
  docker compose --profile model-gateway --profile agent-factory-edge config --quiet
)
pass "Shell and Compose source validation passed"

printf '\nPLATFORM_READINESS=PASS\n'
