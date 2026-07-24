#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command virsh

virsh -c "${AGENT_FACTORY_VM_URI}" dominfo "${AGENT_FACTORY_VM_NAME}"
virsh -c "${AGENT_FACTORY_VM_URI}" domblklist "${AGENT_FACTORY_VM_NAME}" --details
virsh -c "${AGENT_FACTORY_VM_URI}" domifaddr "${AGENT_FACTORY_VM_NAME}" --source agent

timeout 3 bash -c "</dev/tcp/${AGENT_FACTORY_VM_IP}/22" ||
  die "SSH is not reachable at ${AGENT_FACTORY_VM_IP}:22"
printf 'Agent Factory VM SSH endpoint is reachable.\n'
