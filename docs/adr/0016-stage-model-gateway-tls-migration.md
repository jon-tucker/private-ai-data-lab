# ADR 0016: Stage the model-gateway TLS migration

## Status

Accepted

## Context

The v0.15 gateway is authenticated and private but uses HTTP across the
libvirt bridge. Moving the saved Agent Factory connection directly to a new
HTTPS endpoint would combine certificate deployment, application trust, and
client migration in one irreversible step.

## Decision

Add a hardened Nginx TLS proxy on port 4001 while temporarily retaining the
authenticated HTTP endpoint on port 4000. Use a dedicated private CA, merge
its public certificate with the existing Agent Factory MCP trust chain, and
verify a separate saved HTTPS connection before retiring HTTP.

## Consequences

- Model traffic can be verified over authenticated TLS without disrupting the
  working v0.15 connection.
- Agent Factory retains trust in both the MCP and LiteLLM private CAs.
- Port 4000 remains a temporary rollback path and must be removed only after
  all intended clients have migrated.
- Certificate lifecycle becomes part of unified platform health monitoring.
