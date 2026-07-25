# Oracle SQLcl MCP Server

This stack supports two transports for Oracle SQLcl 26.2:

- the original on-demand standard-input/standard-output MCP process;
- a long-running private HTTPS bridge for Agent Factory.

The container runs as numeric UID:GID `54321:54321`, uses a read-only root
filesystem, drops all Linux capabilities, and persists only its Oracle
connection store under `/home/oracle/.dbtools`.

The HTTPS profile uses Supergateway to adapt SQLcl to Streamable HTTP. Its
plain HTTP port remains inside the backend Docker network. A separate
non-root Nginx container publishes certificate-verified TLS only on the
private libvirt bridge.

Use the scripts in `scripts/mcp-*.sh`. Do not start the profile with an
unqualified `docker compose up`.
