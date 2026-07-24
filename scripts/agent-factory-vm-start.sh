#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command virsh

state="$(virsh -c "${AGENT_FACTORY_VM_URI}" domstate "${AGENT_FACTORY_VM_NAME}")"
if [[ "${state}" != 'running' ]]; then
  virsh -c "${AGENT_FACTORY_VM_URI}" start "${AGENT_FACTORY_VM_NAME}"
fi
printf 'Agent Factory VM state: %s\n' \
  "$(virsh -c "${AGENT_FACTORY_VM_URI}" domstate "${AGENT_FACTORY_VM_NAME}")"
