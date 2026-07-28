# ADR 0021: Declare a stable reference release

## Status

Accepted

## Decision

Version 1.0.0 declares the documented platform topology, security boundaries,
operator workflows, and validation interfaces stable for the reference
environment.

A v1.0 release requires the unified platform-readiness gate, repository
release validation, current project policies, a reviewed changelog, an
annotated tag, and a checksum-verified source archive.

Stability applies to the repository's documented interfaces and procedures.
It does not convert third-party Oracle or open-source components into services
maintained by this project.

## Consequences

- Incompatible repository-interface changes require explicit migration
  documentation and semantic-version consideration.
- Security and contribution policies become part of the supported project
  surface.
- Operational readiness is required for release, not inferred from deployment
  success alone.
- Licensed third-party installation media and runtime secrets remain outside
  the source release.
