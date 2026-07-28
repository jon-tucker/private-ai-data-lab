# Agent Factory private browser edge

The browser edge provides trusted LAN access at:

`https://192.168.0.209:8443/agentFactory/`

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

## Rollback

Stop the edge container and use the documented SSH local-forwarding tunnel.
Rebinding the VM to loopback is a separate rollback step and requires
recreating the Agent Factory container.
