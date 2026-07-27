# Private model gateway

Version 0.15.0 introduces LiteLLM as an authenticated, OpenAI-compatible
gateway in front of Ollama.

## Network boundary

The host publishes LiteLLM only at `192.168.122.1:4000`, the libvirt bridge
used by the Agent Factory VM. The gateway reaches Ollama over the private
Docker backend network at `http://ollama:11434`.

## Install

```bash
./scripts/model-gateway-configure-env.sh
./scripts/model-gateway-create-secret.sh
./scripts/model-gateway-prepare-host.sh
./scripts/model-gateway-validate.sh
./scripts/model-gateway-start.sh
```

The key-creation command intentionally fails if a key already exists. Never
replace the key casually because saved clients will stop authenticating.

## Verify

```bash
./scripts/model-gateway-status.sh
./scripts/model-gateway-smoke-test.sh
./scripts/model-gateway-agent-factory-smoke-test.sh
```

The first smoke test performs an authenticated OpenAI-compatible chat request.
The second confirms that the Agent Factory VM can reach the private endpoint.

## Agent Factory connection

Create an OpenAI-compatible LLM connection with:

- Base URL: `http://192.168.122.1:4000/v1`
- Model ID: `local-qwen3-4b-instruct`
- API key: the exact content of
  `/srv/oracle-ai-secrets/litellm-master-key`

Test and save the new connection before changing an existing flow. Keep the
known-good direct Ollama connection until an Agent Factory prompt succeeds
through LiteLLM.

## Rollback

Stop only the gateway:

```bash
./scripts/model-gateway-stop.sh
```

Existing direct Ollama connections remain available.

## Verification

The private model gateway was verified through Oracle AI Database Private
Agent Factory 26.4.

Verification confirmed:

- The pinned LiteLLM container reached a healthy state.
- The authenticated OpenAI-compatible API published
  `local-qwen3-4b-instruct`.
- An authenticated gateway smoke test returned `MODEL_GATEWAY_OK`.
- The Agent Factory VM reached the gateway over the private libvirt bridge.
- A saved generative-model connection named
  `litellm_qwen3_4b_instruct` passed its connection test.
- Prompt Lab returned exactly `LITELLM_AGENT_FACTORY_OK` through LiteLLM.
- The direct Ollama connection remained available as a rollback path.
