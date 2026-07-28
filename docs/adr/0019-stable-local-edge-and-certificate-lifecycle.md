# ADR 0019: Stable local edge and certificate lifecycle

## Status

Accepted

## Decision

Publish the Agent Factory browser edge on the standard HTTPS port using the
mDNS name `oracle-ai.local`. Issue the edge certificate from the existing
private edge CA with SAN entries for the mDNS name, short host name, and LAN
address.

Certificate replacement is a two-stage operation. Staging creates and verifies
new material without changing the active edge. Applying archives the current
material, installs the staged certificate, recreates the proxy, and verifies
the trusted endpoint.

## Consequences

- Authorized LAN clients use a stable URL without a nonstandard port.
- Existing clients retain trust because the edge CA is unchanged.
- Certificate replacement has an explicit review point before application.
- mDNS availability and certificate lifetime become operational dependencies.
- Direct VM access and the SSH tunnel remain recovery paths rather than normal
  browser access.
