# Model gateway HTTPS cutover

Version 0.17.0 makes the verified LiteLLM HTTPS endpoint the supported private
Agent Factory model-gateway path.

## Preconditions

- `litellm_tls_qwen3_4b_instruct` is active in Agent Factory.
- Prompt Lab returns `LITELLM_TLS_AGENT_FACTORY_OK`.
- The combined Agent Factory trust bundle is active.
- Both v0.16.0 HTTPS smoke tests pass.

## Apply

```bash
./scripts/model-gateway-cutover-validate.sh
./scripts/model-gateway-cutover-apply.sh
./scripts/model-gateway-cutover-status.sh
```

The apply command recreates LiteLLM without a host HTTP publication. The TLS
proxy continues to reach LiteLLM through the private Docker backend network.

## Verify

```bash
./scripts/model-gateway-cutover-smoke-test.sh
./scripts/agent-operations-health.sh
```

Verification requires HTTPS inference and Agent Factory trust to pass while
port 4000 is absent and unreachable from Agent Factory.

## Rollback

```bash
./scripts/model-gateway-cutover-rollback.sh
```

Rollback uses a separate Compose override to restore
`192.168.122.1:4000`. Reapply the cutover after resolving the problem.
