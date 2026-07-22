# ADR 0003: Ollama acceleration profiles

- Status: Accepted
- Date: 2026-07-22

## Context

The reference host has a Ryzen AI 9 HX 370 with Radeon 890M graphics and the required Linux GPU device nodes. Ollama officially supports this APU through ROCm, but the host's Ubuntu 26.04 release is newer than AMD's currently documented production matrix. Other users may have no supported GPU.

## Decision

Provide mutually exclusive `rocm` and `cpu` Compose profiles behind identical operational scripts, persistent storage, networking, and container naming. Select the profile through `OLLAMA_ACCELERATOR` in the ignored local `.env` file.

Bind the host API to loopback by default. Downstream containers use the backend-network alias `ollama`.

## Consequences

- GPU support is tested rather than assumed.
- CPU fallback does not require rewriting Compose definitions or moving models.
- Only one Ollama profile may run at a time because both intentionally share a container name and port.
- Switching profiles recreates the container but preserves downloaded models.
- Direct LAN clients cannot reach Ollama unless the operator deliberately changes the bind address.
