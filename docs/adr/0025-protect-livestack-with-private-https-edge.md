# ADR 0025: Protect LiveStack with a private HTTPS edge

## Status

Accepted

## Context

LiveStack is intentionally published only on host loopback port 8505. Directly
changing that bind address would expose an unauthenticated HTTP application and
break the v1.2 integration boundary. Trusted LAN users nevertheless need a
durable browser endpoint that does not require one SSH tunnel per client.

## Decision

Keep the LiveStack host publication on `127.0.0.1:8505`. Add a separate,
hardened Nginx container on the private Docker backend network. The edge proxies
to `livestack:3001`, publishes TLS on one explicit LAN address and port 8506,
and admits only loopback and a configured trusted CIDR.

Use a dedicated private CA and server certificate with explicit creation,
staged renewal, validation, monitoring, and rollback. Do not reuse Agent
Factory private keys or publish the edge through a wildcard host address.

## Consequences

LAN clients must trust the LiveStack edge CA. LiveStack itself remains
unchanged and unavailable directly from the LAN. Operators must configure the
real LAN address and CIDR locally and must not forward port 8506 through an
internet router.
