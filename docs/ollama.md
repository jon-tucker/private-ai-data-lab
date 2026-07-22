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
