# ADR 0023: Integrate LiveStack as an isolated workload

## Status

Accepted

## Context

The supplied Energy & Utilities LiveStack package duplicates Oracle Database,
ORDS, and Ollama and publishes a demonstration application without the
platform's established security and lifecycle controls.

## Decision

LiveStack will be integrated as an optional application-only workload. It will
reuse the private backend database and Ollama services. Vendor source remains
outside Git, telemetry is disabled, credentials use the secrets boundary, and
the first publication is loopback-only.

Schema installation uses platform-owned, bounded provisioning that excludes
the vendor privileges, network ACL, public ORDS configuration, model loading,
and caller-trusted VPD design. Application startup remains deferred until the
schema and container pass smoke tests and a protected access boundary exists.

## Consequences

The stable platform is not duplicated or replaced. Integration takes more
work than running the lab unchanged, but preserves rollback, resource
efficiency, Radeon acceleration, and the established trust boundaries.
