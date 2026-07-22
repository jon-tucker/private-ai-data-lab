# Ollama stack

This stack serves local language and embedding models through Ollama's HTTP API.

- `ollama-rocm` passes the AMD KFD and DRI devices into the official ROCm image.
- `ollama-cpu` provides a portable fallback with no GPU-device dependency.
- Both profiles use the same container name, backend alias, API port, and persistent model directory, so only one profile may run at a time.

Select `OLLAMA_ACCELERATOR=rocm` or `OLLAMA_ACCELERATOR=cpu` in `.env`, then use the project scripts rather than invoking the profile directly.

The API binds to `127.0.0.1:11434` by default. Future platform containers use `http://ollama:11434` on the backend network.
