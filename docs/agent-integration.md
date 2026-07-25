# Agent Factory and SQLcl MCP integration

## Scope

Version 0.9.0 connects Oracle AI Database Private Agent Factory 26.4 to the
read-only Oracle SQLcl MCP Server 26.2 deployment.

```text
Agent Factory VM
  -> https://192.168.122.1:8182/mcp
  -> Nginx private TLS proxy
  -> mcp-http:8181 on oracle-ai-backend
  -> Supergateway
  -> SQLcl -mcp
  -> oracle_ai_readonly
  -> ORACLE_AI_MCP@FREEPDB1
```

The plain HTTP adapter has no published host port. Only the TLS endpoint is
bound to the private libvirt bridge, which is not directly routed to the LAN.
Nginx does not filter by client IP because Docker forwarding can translate
the source address. If source-address filtering is required, enforce it in
the host firewall before Docker network translation.

## Configure and start

Add the v0.9.0 defaults to the local environment:

```bash
./scripts/mcp-configure-env.sh
./scripts/agent-factory-configure-env.sh
./scripts/mcp-http-prepare-host.sh
```

The existing prototype certificates can be retained. For a new deployment,
create a private CA and server certificate once:

```bash
./scripts/mcp-http-create-tls.sh
```

Do not run the creation script over an existing TLS directory. It deliberately
refuses to overwrite keys.

Validate and start the bridge:

```bash
./scripts/mcp-http-validate.sh
./scripts/mcp-http-start.sh
./scripts/mcp-http-status.sh
./scripts/mcp-http-smoke-test.sh
```

When replacing the manually tested containers, validate and build the durable
configuration first. Then remove only the two explicitly named prototype
containers so their port bindings do not conflict:

```bash
docker rm --force \
  oracle-ai-sqlcl-mcp-tls-test \
  oracle-ai-sqlcl-mcp-http-test

./scripts/mcp-http-start.sh
```

Install the private trust chain in Agent Factory:

```bash
./scripts/agent-integration-install-mcp-ca.sh
./scripts/agent-integration-smoke-test.sh
```

The installation script backs up `source_env.sh` once as
`source_env.sh.pre-mcp-tls`, sets `SSL_CERTIFICATE_FILE` to the persistent
trust chain under `/mount`, and restarts Agent Factory.

## Agent Factory settings

Under **Application Settings → Proxy Settings**:

| Preference | Value |
| --- | --- |
| Allow Insecure HTTP URLs | No |
| Allow User Supplied Proxy | No |
| Block Private Outbound URLs | No |

Allowing private outbound URLs is required for this private bridge. Register
only reviewed endpoints.

Register the server under **MCP Servers**:

| Field | Value |
| --- | --- |
| Server name | `oracle_sqlcl_readonly` |
| Server URL | `https://192.168.122.1:8182/mcp` |
| Authentication | Direct |

Direct mode does not require a token. Agent Factory 26.4 can emit a noisy
failed wallet lookup for `mcp_auth_<id>` while the Direct connection continues
successfully. Do not create a dummy token.

## Flow policy

Connect the MCP server node's **Tools** output to the Agent node's **Tools**
input. Use a 90-second timeout and allow only:

- `connections_list`
- `connect`
- `disconnect`
- `schema_information`
- `sql_run`
- `request_status`

Do not expose `sqlcl_run`, `skills_sync`, or `annotation_generate` to the
read-only flow.

Use instructions that require `oracle_ai_readonly`, permit only `SELECT` and
metadata inspection, and prohibit DDL, DML, PL/SQL, administrative commands,
and SQLcl commands.

## End-to-end verification

Submit this in a new flow chat:

```text
Use the MCP tools exactly as follows:

1. Call connect using connection_name oracle_ai_readonly.
2. Do not call schema_information.
3. Call sql_run exactly once with this SQL:

SELECT
  SYS_CONTEXT('USERENV', 'SESSION_USER') AS session_user,
  SYS_CONTEXT('USERENV', 'CON_NAME') AS container_name
FROM dual

4. Return only SESSION_USER and CONTAINER_NAME.
Do not perform any additional tool calls.
```

Expected values:

```text
SESSION_USER: ORACLE_AI_MCP
CONTAINER_NAME: FREEPDB1
```

This exact test was verified through Agent Factory, the private TLS bridge,
SQLcl MCP, and Oracle Database.

## Lifecycle

```bash
./scripts/mcp-http-start.sh
./scripts/mcp-http-status.sh
./scripts/mcp-http-stop.sh
```

The services use `restart: unless-stopped`. The SQLcl home and TLS directory
must be backed up independently of the repository.
