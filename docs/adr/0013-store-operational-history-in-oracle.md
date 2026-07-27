# ADR 0013: Store operational history in Oracle

## Status

Accepted

## Context

The platform's health checks and coordinated backups already emit structured
results to journald and backup manifests. Those sources are useful for host
diagnostics but do not provide a durable, queryable history to the read-only
operations agent.

## Decision

Persist a normalized subset of scheduled health and backup results in the
`ORACLE_AI` application schema. Store each execution, its individual
`PASS`/`WARN`/`FAIL` checks, and recovery-set metadata. Expose the repository
through the existing read-only SQLcl MCP role.

Recording is best effort: an unavailable database must not change the original
health or backup exit status. Raw logs remain in journald and backup artifacts;
the database stores bounded excerpts and structured facts.

Retention is explicit and destructive only with `--confirm`.

## Consequences

Agents can answer operational questions using the same least-privilege MCP
path as the sales agent. Database growth is bounded by configured retention.
Repository writes remain host-side administrative actions and are never
granted to Agent Factory or the MCP database account.
