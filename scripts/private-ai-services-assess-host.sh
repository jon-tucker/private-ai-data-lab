#!/usr/bin/env bash
set -u

failures=0
warnings=0

pass() {
  printf 'PASS: %s\n' "$*"
}

fail() {
  printf 'FAIL: %s\n' "$*"
  failures=$((failures + 1))
}

warn() {
  printf 'WARN: %s\n' "$*"
  warnings=$((warnings + 1))
}

printf '=== Oracle Private AI Services host assessment ===\n'

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
else
  fail 'cannot read /etc/os-release'
  ID=''
  VERSION_ID=''
  PRETTY_NAME='unknown'
fi

printf 'operating_system=%s\n' "${PRETTY_NAME:-unknown}"

if [[ "${ID:-}" == 'ol' ]] &&
   [[ "${VERSION_ID:-}" =~ ^(8([.][0-9]+)?|9([.][0-9]+)?|10([.][0-9]+)?)$ ]]; then
  if [[ "${VERSION_ID%%.*}" == '8' ]] &&
     (( ${VERSION_ID#*.} < 6 )); then
    fail "Oracle Linux ${VERSION_ID} is older than supported 8.6"
  else
    pass "supported Oracle Linux release=${VERSION_ID}"
  fi
else
  fail 'host must run Oracle Linux 8.6+, 9, or 10'
fi

architecture="$(uname -m)"
printf 'architecture=%s\n' "${architecture}"
if [[ "${architecture}" == 'x86_64' ]]; then
  pass 'x86-64 architecture'
else
  fail 'Private AI Services target must use x86-64'
fi

if [[ -r /proc/meminfo ]]; then
  available_kb="$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)"
else
  available_kb=0
  fail 'cannot read /proc/meminfo'
fi
available_mb=$((available_kb / 1024))
printf 'available_memory_mb=%s\n' "${available_mb}"
if (( available_mb >= 16384 )); then
  pass 'at least 16 GB of memory is available'
else
  fail 'less than 16 GB of memory is available'
fi

assessment_path="${PRIVATE_AI_ASSESSMENT_PATH:-/var/lib}"
available_disk_kb="$(df -Pk "${assessment_path}" | awk 'NR == 2 {print $4}')"
available_disk_gb=$((available_disk_kb / 1024 / 1024))
printf 'assessment_path=%s\n' "${assessment_path}"
printf 'available_disk_gb=%s\n' "${available_disk_gb}"
if (( available_disk_gb >= 22 )); then
  pass 'at least 22 GB of storage is available'
else
  fail 'less than 22 GB of storage is available'
fi

if command -v podman >/dev/null 2>&1; then
  podman_version="$(podman version --format '{{.Client.Version}}' 2>/dev/null)"
  printf 'podman_version=%s\n' "${podman_version:-unknown}"
  pass 'Podman is installed; confirm the version against current Oracle documentation'
else
  fail 'Podman is not installed'
fi

if command -v openssl >/dev/null 2>&1; then
  openssl_version="$(openssl version | awk '{print $2}')"
  printf 'openssl_version=%s\n' "${openssl_version}"
  if openssl ciphers -v 2>/dev/null | grep -q 'TLSv1.3'; then
    pass 'OpenSSL supports TLS 1.3'
  else
    fail 'OpenSSL does not report TLS 1.3 cipher support'
  fi
else
  fail 'OpenSSL is not installed'
fi

printf '\n=== Optional vector index service ===\n'
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi \
    --query-gpu=name,driver_version,memory.total \
    --format=csv,noheader 2>/dev/null ||
    warn 'nvidia-smi is installed but GPU details could not be read'
  warn 'verify compute capability 7.5+ and NVIDIA Container Toolkit separately'
else
  warn 'no NVIDIA GPU detected; vector index service is not eligible'
fi

printf '\n=== Summary ===\n'
printf 'failures=%s warnings=%s\n' "${failures}" "${warnings}"

if (( failures == 0 )); then
  printf 'PRIVATE_AI_SERVICES_HOST=READY_FOR_ORACLE_REVIEW\n'
  exit 0
fi

printf 'PRIVATE_AI_SERVICES_HOST=NOT_READY\n'
exit 1
