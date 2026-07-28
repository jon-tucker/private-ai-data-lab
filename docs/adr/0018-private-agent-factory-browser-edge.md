# ADR 0018: Private Agent Factory browser edge

## Status

Accepted.

## Decision

Expose Agent Factory to the trusted LAN through a dedicated, hardened Nginx
HTTPS proxy. Keep the VM on the private libvirt network, restrict its port 8080
to the host bridge address, verify the VM's self-signed certificate at the
proxy, and retain the SSH tunnel as a rollback path.

The edge uses its own private CA. Client devices must explicitly trust that CA.
Socket.IO traffic preserves the public host and port and supports WebSocket
upgrade and long polling.

## Consequences

Agent Factory receives a stable browser URL without exposing its VM directly
to the LAN. CA distribution and certificate renewal become explicit platform
operations.
