# ADR 0024: Adopt an independent project identity

## Status

Accepted

## Context

The original Oracle AI Data Platform name can be confused with Oracle commercial offerings even though this repository is an independently created reference environment with a different product set and architecture.

The deployed environment already uses stable paths, container names, Compose identity, systemd units, and Docker label keys containing `oracle-ai`. Renaming those identifiers would create operational risk without improving the public distinction.

## Decision

Rename the public project to **Private AI Data Lab** and rename its repository to `private-ai-data-lab`.

State clearly that the lab is an independent project created by Jon Tucker with ChatGPT, is not an Oracle product, and is not affiliated with or endorsed by Oracle Corporation.

Retain the existing `/srv/oracle-ai*` paths, `oracle-ai-*` runtime names, `oracle-ai-data-platform` Compose project name, and Docker label namespace as compatibility identifiers.

## Consequences

- Public documentation and user-facing labels use Private AI Data Lab.
- Existing deployments can upgrade without moving data or recreating services.
- New installations initially use the compatibility identifiers documented by this repository.
- A future migration of runtime identifiers requires a separate ADR and an explicit, tested migration procedure.
