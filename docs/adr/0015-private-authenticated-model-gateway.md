# ADR 0015: Use a private authenticated model gateway

## Status

Accepted

## Context

Agent Factory currently connects directly to Ollama. That works, but it couples
agents to a provider-specific endpoint and model identifier. The platform needs
a stable OpenAI-compatible contract without exposing the local model runtime to
the LAN or storing credentials in Git.

## Decision

Run a pinned LiteLLM container on the backend network and publish it only on the
libvirt host bridge. Require a master key stored beneath
`/srv/oracle-ai-secrets`, expose a stable model alias, and route that alias to
Ollama by its backend-network name.

Keep direct Ollama access operational until the gateway is verified from Agent
Factory. This provides an immediate rollback path.

## Consequences

- Agent clients use a stable OpenAI-compatible API.
- The gateway is reachable by the Agent Factory VM but not the host LAN.
- Authentication material remains outside source control.
- LiteLLM becomes another health-checked service to patch and monitor.
- Direct Ollama remains a temporary compatibility and rollback path.
