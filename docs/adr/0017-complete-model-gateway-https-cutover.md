# ADR 0017: Complete the model-gateway HTTPS cutover

## Status

Accepted

## Context

Version 0.16.0 verified a private HTTPS endpoint while retaining the original
HTTP publication on port 4000. Keeping both endpoints indefinitely expands the
network surface and allows clients to bypass TLS.

## Decision

Use the HTTPS connection on port 4001 as the supported Agent Factory path.
Keep LiteLLM port 4000 available only inside the Docker backend network and
remove its host publication. Provide an explicit, reviewed rollback override
that can temporarily restore port 4000.

The cutover must verify HTTPS from both the host and Agent Factory, and must
prove that Agent Factory can no longer reach HTTP port 4000.

## Consequences

- LiteLLM remains reachable by its TLS proxy over the Docker backend network.
- Agent Factory uses the saved `litellm_tls_qwen3_4b_instruct` configuration.
- The normal Compose configuration publishes only HTTPS port 4001.
- Rollback requires an explicit command and is visible in listener checks.
