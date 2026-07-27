# Model gateway operations

Version 0.16.0 adds private TLS and operational controls to LiteLLM.

## Deployment sequence

```bash
./scripts/model-gateway-operations-configure-env.sh
./scripts/model-gateway-operations-create-tls.sh
./scripts/model-gateway-operations-prepare-host.sh
./scripts/model-gateway-operations-validate.sh
./scripts/model-gateway-operations-start.sh
./scripts/model-gateway-operations-smoke-test.sh
./scripts/model-gateway-operations-install-agent-ca.sh
./scripts/model-gateway-operations-agent-factory-smoke-test.sh
```

The TLS endpoint is `https://192.168.122.1:4001/v1`. It uses the same stable
model alias and LiteLLM master key as v0.15.

## Agent Factory migration

Create and test a second OpenAI-compatible generative-model connection:

- Configuration name: `litellm_tls_qwen3_4b_instruct`
- Base URL: `https://192.168.122.1:4001/v1`
- Model ID: `local-qwen3-4b-instruct`
- API key: the existing protected LiteLLM master key

Do not delete or edit the working HTTP connection during initial validation.
After Prompt Lab succeeds through HTTPS, migrate flows individually.

## Rollback

Stop only the TLS proxy:

```bash
./scripts/model-gateway-operations-stop.sh
```

The authenticated v0.15 HTTP endpoint remains available on port 4000.

## Verification

The staged HTTPS model-gateway path was verified through Oracle AI Database
Private Agent Factory 26.4.

Verification confirmed:

- The TLS proxy and LiteLLM containers reached healthy states.
- The proxy allowed only localhost, the libvirt host and Agent Factory
  addresses, and the dynamically discovered Docker backend gateway.
- An authenticated HTTPS request returned `MODEL_GATEWAY_TLS_OK`.
- Agent Factory trusted the combined persistent MCP and LiteLLM CA bundle.
- The saved generative-model connection
  `litellm_tls_qwen3_4b_instruct` reached the HTTPS endpoint.
- Prompt Lab returned exactly `LITELLM_TLS_AGENT_FACTORY_OK`.
- Agent Factory displayed a non-blocking Top K compatibility warning while
  still returning the correct response.
- The authenticated HTTP endpoint on port 4000 remained available for rollback.
