# ADR 0009: Private HTTPS bridge for Agent Factory MCP

## Status

Accepted

## Context

Oracle SQLcl 26.2 exposes its MCP server over standard input/output. Oracle AI
Database Private Agent Factory 26.4 requires a network MCP server and, by
default, rejects insecure HTTP and private-network destinations.

Publishing SQLcl directly to the LAN would expand the attack surface of a
database tool endpoint. Disabling all outbound-request safeguards would also
be broader than required.

## Decision

Adapt SQLcl standard input/output to stateful Streamable HTTP with the pinned
Supergateway 3.4.3 package and Node.js 22. Terminate TLS in a separate pinned
Nginx container.

The HTTP adapter is reachable only on the backend Docker network. The TLS
proxy publishes `192.168.122.1:8182`, which is reachable from the isolated
Agent Factory VM but not directly routed to the LAN. Source-address filtering
is not performed inside Nginx because Docker forwarding can translate the
client address before Nginx evaluates it. Deployments that require an
additional source-address restriction must enforce it in the host firewall,
before Docker network translation.

Agent Factory trusts a dedicated private CA. Insecure HTTP remains disabled.
Private outbound URLs are enabled in Agent Factory because this integration
intentionally targets the libvirt bridge. User-supplied proxies remain
disabled.

SQLcl remains at restriction level 4 and connects with the dedicated
`ORACLE_AI_MCP` account. Agent flows explicitly allow only the reviewed MCP
tools needed by the workflow.

## Consequences

- The MCP endpoint is encrypted and certificate-verified.
- The unencrypted adapter port is not published on the host.
- TLS keys and generated certificates remain outside Git.
- Agent Factory can access a private-network URL, so every registered MCP
  endpoint must be reviewed as an SSRF-sensitive trust decision.
- Direct authentication has no application token. Network isolation, TLS
  server authentication, SQLcl restrictions, and database authorization are
  the security boundaries.
- Host-firewall source filtering is an optional additional control; an Nginx
  source-address rule is not used because Docker forwarding obscures the
  original client address.
- Agent Factory 26.4 may log a failed `mcp_auth_<id>` lookup for Direct
  authentication even though tokenless MCP initialization and tool calls
  succeed. This is treated as an upstream logging/runtime limitation, not a
  reason to create a synthetic credential.
