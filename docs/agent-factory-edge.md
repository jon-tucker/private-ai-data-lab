# Agent Factory private browser edge

The browser edge provides trusted LAN access at:

`https://oracle-ai.local/agentFactory/`

The host proxy terminates the client TLS connection and independently verifies
the Agent Factory VM certificate. The VM listener is bound to
`192.168.122.202:8080` and its firewall accepts that port only from
`192.168.122.1`.

## Host workflow

Run the configure, TLS creation, host preparation, validation, start, status,
and smoke-test scripts in that order. Install the generated edge CA on each
authorized client.

The Nginx configuration preserves the public host and port. This is required
for Agent Factory Socket.IO polling and WebSocket traffic.

## Certificate lifecycle

The edge certificate includes `oracle-ai.local`, the short host name, and the
LAN address. The renewal script stages a replacement certificate without
touching the active edge. Applying a staged certificate archives the current
material, recreates the edge container, and runs the trusted smoke test.

The platform health check warns before the edge certificate reaches the
configured certificate-expiry threshold.

## Rollback

Stop the edge container and use the documented SSH local-forwarding tunnel.
Rebinding the VM to loopback is a separate rollback step and requires
recreating the Agent Factory container.

## Verification

The production browser edge was verified from a trusted macOS client.

Verification confirmed:

- The edge certificate was rejected before its private CA was trusted.
- A CA-verified request from macOS returned HTTP 200.
- The managed edge container became healthy.
- The proxy verified the Agent Factory VM certificate.
- Agent Factory Socket.IO polling and WebSocket traffic completed successfully.
- A read-only operations query returned through the browser normally.
- Direct VM access remained restricted to the host bridge.
- Unified platform health passed with zero failures and zero warnings.
