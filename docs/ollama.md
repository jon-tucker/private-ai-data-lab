# Ollama

## Scope

Version 0.3.0 adds Ollama as the platform's local model runtime. Open WebUI, LiteLLM, Oracle MCP, and agent integration remain separate milestones.

## Images

```text
ollama/ollama:0.32.0-rocm
ollama/ollama:0.32.0
```

Both images are pinned. The ROCm profile is the reference-host target; the CPU image is the recovery and portability fallback.

## Reference-host readiness

The Minisforum AI X1 Pro exposes its Radeon 890M through the `amdgpu` driver with `/dev/kfd` and `/dev/dri/renderD128`. Ollama officially lists the Ryzen AI 9 HX 370 (`gfx1150`) as supported by ROCm 7.

Ubuntu Server 26.04 is newer than AMD's currently documented production matrix. GPU acceleration must therefore be demonstrated through Ollama runtime logs and `ollama ps`, not inferred from device presence alone. BIOS 1.05 is retained because the operating system already discovers the GPU and compute devices.

## Reference-host deployment verification

The ROCm profile was verified on 2026-07-22 with the following deployment:

```text
Host GPU:       AMD Radeon 890M Graphics
ROCm target:    gfx1150
Ollama image:   ollama/ollama:0.32.0-rocm
Image digest:   sha256:ed3ff2d663fba3b089807a8dca022af9fc1870bbcb7ed4bba9ce5f3939821269
Model:          qwen3:4b
Model ID:       359d7dd4bcda
Model size:     2.5 GB
Context:        4096 tokens
Allocation:     100% GPU
Layer offload:  37/37 layers
```

Ollama detects the Radeon as an integrated GPU and excludes it by default. The ROCm deployment therefore sets `OLLAMA_IGPU_ENABLE=1`. Runtime logs confirmed a 14.2 GiB shared-memory GPU allocation, full model-layer offload, ROCm model and KV-cache buffers, and a successful inference response.

The shared-memory figures reported by an integrated GPU are not dedicated VRAM. Oracle Database and Ollama still compete for the host's physical memory, so container limits and concurrent workloads must be monitored.

## Model roles after Open WebUI integration

The everyday default is `qwen3:4b-instruct` (model ID `0edcdef34593`), an official non-thinking model suited to interactive chat. The previously verified `qwen3:4b` model remains installed as an optional thinking model for tasks that benefit from extended reasoning.

Open WebUI system and feature schemas exceeded the original 4,096-token context even for a short user message. Version 0.4.0 therefore raises `OLLAMA_CONTEXT_LENGTH` to 8,192. A `num_ctx` value set by Open WebUI overrides the server default and should not be set lower unintentionally.

## Security boundary

Ollama does not provide native API authentication. The host mapping defaults to `127.0.0.1:11434`; do not change it to `0.0.0.0` without a trusted-LAN requirement or an authenticated proxy. Containers on the backend network use `http://ollama:11434`.

## Deployment

```bash
./scripts/ollama-configure-env.sh
./scripts/ollama-prepare-host.sh
./scripts/ollama-validate.sh
./scripts/ollama-start.sh
./scripts/ollama-pull-model.sh
./scripts/ollama-smoke-test.sh
./scripts/ollama-accelerator-check.sh
```

Set `OLLAMA_ACCELERATOR=cpu` in `.env` if the ROCm profile fails, then stop and restart Ollama using the project scripts.

## Operations

```bash
./scripts/ollama-status.sh
./scripts/ollama-logs.sh
./scripts/ollama-run-model.sh
./scripts/ollama-stop.sh
./scripts/ollama-start.sh
```

Pass a model name to the pull or run scripts to override `OLLAMA_DEFAULT_MODEL`.

## Persistence and capacity

Models and metadata live under `/srv/oracle-ai-data/ollama`. The default 4B model is intentionally modest for a host with 28 GiB usable RAM shared with Oracle Database. Avoid loading several models concurrently until memory use is measured.

## Verification

`ollama ps` exposes the active model's processor allocation. A successful API response does not by itself prove GPU offload; the accelerator check must show GPU participation and the deployment record must capture the image digest.

## Official references

- [Ollama Docker](https://docs.ollama.com/docker)
- [Ollama hardware support](https://docs.ollama.com/gpu)
- [Ollama API](https://docs.ollama.com/api)
