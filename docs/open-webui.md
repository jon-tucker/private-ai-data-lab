# Open WebUI

## Scope

Version 0.4.0 adds Open WebUI as the authenticated browser interface for Ollama. Oracle MCP Server and application integration remain separate milestones.

## Image

```text
ghcr.io/open-webui/open-webui:v0.10.2
```

The image is pinned rather than using the floating `main` tag. Record the immutable digest after the first successful pull.

## Architecture

Open WebUI publishes container port `8080` on host port `3000`. It reaches Ollama at `http://ollama:11434` through the backend Docker network; the Ollama API remains bound to host loopback.

Persistent state is stored under `/srv/oracle-ai-data/open-webui` and includes users, chats, configuration, uploads, and knowledge content.

## Stable secret key

Open WebUI uses its secret key to sign sessions and encrypt sensitive values, including future MCP OAuth credentials. The platform creates a 256-bit key at:

```text
/srv/oracle-ai-secrets/open-webui-secret-key
```

Compose mounts that file read-only as `/app/backend/.webui_secret_key`. Back up the key with the Open WebUI data. Losing or changing it invalidates sessions and can make encrypted credentials unreadable.

## Deployment

```bash
./scripts/open-webui-configure-env.sh
./scripts/open-webui-create-secret.sh
./scripts/open-webui-prepare-host.sh
./scripts/open-webui-validate.sh
./scripts/open-webui-start.sh
./scripts/open-webui-smoke-test.sh
```

Open the configured URL, normally `http://<platform-lan-ip>:3000`.

## First-run security

The first registered account becomes administrator. Perform registration only from the trusted LAN, then open **Admin Panel → Settings → General** and disable sign-up. Confirm the sign-up page is no longer available before considering deployment complete.

Open WebUI persists many settings in its internal database. After initialization, values changed in the Admin Panel can take precedence over Compose environment variables.

This release deliberately provides HTTP only on the trusted LAN. Do not expose port `3000` to the internet. A later reverse-proxy milestone will add TLS and stronger edge controls.

## Reference-host deployment verification

Open WebUI was verified on 2026-07-22 with the following deployment:

```text
Open WebUI image:  ghcr.io/open-webui/open-webui:v0.10.2
Image digest:      sha256:9fcea9c6e32ab60b0498f3986c6cdf651ddbe61db48d2213a3d28048ddd673d4
Browser URL:       http://<platform-lan-ip>:3000
Ollama endpoint:   http://ollama:11434
Default model:     qwen3:4b-instruct
Model ID:          0edcdef34593
Stored size:       2.5 GB
Loaded size:       3.9 GB
Context:           8192 tokens
Allocation:        100% GPU
```

The first administrator was created locally and Open WebUI automatically disabled new sign-ups. A cold backup of application state and the external secret key was created before upgrading the initial `v0.9.5` deployment to `v0.10.2`. The administrator session, persisted state, disabled-sign-up setting, Ollama connection, and model chat remained functional after container replacement.

The automated smoke test confirmed `/health` and backend model discovery. An authenticated browser chat confirmed end-to-end inference through Open WebUI, Ollama, ROCm, and the Radeon 890M.

## Model and context lessons

The floating `qwen3:4b` tag resolved to the thinking-only model ID `359d7dd4bcda`. A trivial request generated more than 3,700 reasoning tokens at approximately 26 tokens per second before the client canceled it. This was expected model behavior, not a GPU or memory failure.

The platform now uses the official non-thinking `qwen3:4b-instruct` model for routine chat and retains `qwen3:4b` as an optional reasoning model.

Open WebUI's system instructions and feature schemas produced a 5,545-token prompt, exceeding the original 4,096-token Ollama context. The default context was raised to 8,192 tokens, after which browser inference completed successfully. Avoid setting a smaller `num_ctx` in Open WebUI because a per-request value overrides `OLLAMA_CONTEXT_LENGTH`.

## Operations

```bash
./scripts/open-webui-status.sh
./scripts/open-webui-logs.sh
./scripts/open-webui-stop.sh
./scripts/open-webui-start.sh
```

## Backup and recovery

Back up these two items together:

```text
/srv/oracle-ai-data/open-webui
/srv/oracle-ai-secrets/open-webui-secret-key
```

For a consistent file-level backup, stop Open WebUI first. Preserve ownership and permissions when restoring. Never delete the data directory merely to resolve a configuration problem without first making a recoverable copy.

## Verification

The smoke test verifies the `/health` endpoint and confirms that Open WebUI can retrieve the model list from Ollama over the backend network. Browser registration and an interactive `qwen3:4b-instruct` chat complete the deployment acceptance test.

## Official references

- [Open WebUI Docker quick start](https://docs.openwebui.com/getting-started/quick-start/)
- [Environment variable configuration](https://docs.openwebui.com/reference/env-configuration/)
- [Open WebUI hardening](https://docs.openwebui.com/getting-started/advanced-topics/hardening/)
- [Connecting to Ollama](https://docs.openwebui.com/getting-started/quick-start/connect-a-provider/starting-with-ollama/)
- [Updating and backup](https://docs.openwebui.com/getting-started/updating/)
