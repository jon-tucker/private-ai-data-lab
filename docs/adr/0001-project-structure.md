# ADR 0001: Separate source, persistent data, and secrets

- **Status:** Accepted
- **Date:** 2026-07-21

## Context

The platform must be reproducible, safe to publish, and practical to operate on a long-running home server. Oracle database files, downloaded AI models, logs, and credentials must survive container replacement but must not enter source control.

## Decision

Use three top-level host paths:

- `/srv/oracle-ai` for the Git working tree.
- `/srv/oracle-ai-data` for persistent application state.
- `/srv/oracle-ai-secrets` for credentials and private configuration.

Organize deployable components beneath `stacks/`, even when a stack initially contains only one container. Keep reusable, non-secret configuration beneath `config/`. Keep operational automation beneath `scripts/` until a distinct automation hierarchy is justified by actual content.

Use a root `compose.yaml` to define shared project infrastructure. Add stack definitions incrementally as components are implemented and tested.

## Consequences

### Positive

- The repository can be cloned or replaced without touching runtime data.
- Persistent data and secrets can follow different backup and access-control policies.
- Public publication is safer because secret and state paths are outside the repository.
- Stack modules can evolve from one container to several without renaming the top-level concept.

### Trade-offs

- Host-path conventions must be configurable for users who cannot deploy under `/srv`.
- Backups require explicit handling of multiple locations.
- Bind-mount ownership and permissions must be documented per stack.

## Alternatives considered

### Keep all data beneath the repository

Rejected because accidental Git staging, destructive repository operations, and unclear backup boundaries create unnecessary risk.

### Use only Docker-managed named volumes

Deferred. Named volumes simplify some deployments but make host-level inspection, backup, and migration less transparent for this educational reference platform. Individual stacks may adopt named volumes when there is a documented advantage.

