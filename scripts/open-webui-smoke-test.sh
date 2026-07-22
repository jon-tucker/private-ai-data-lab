#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_env
require_command curl

curl --fail --silent --show-error "http://127.0.0.1:${OPEN_WEBUI_PORT:-3000}/health" >/dev/null
docker exec "${OPEN_WEBUI_CONTAINER}" python -c \
  'import json, urllib.request; data=json.load(urllib.request.urlopen("http://ollama:11434/api/tags", timeout=30)); assert data.get("models"), "no Ollama models returned"; print("Ollama models visible:", ", ".join(m["name"] for m in data["models"]))'
printf 'Open WebUI health and backend Ollama connectivity passed.\n'
