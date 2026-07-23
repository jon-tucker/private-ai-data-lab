# Oracle SQLcl MCP Server

This stack launches Oracle SQLcl 26.2 as a standard-input/standard-output MCP
server. It is an on-demand tool process, not a continuously running HTTP
service.

The container runs as numeric UID:GID `54321:54321`, uses a read-only root
filesystem, drops all Linux capabilities, and persists only its Oracle
connection store under `/home/oracle/.dbtools`.

Use the scripts in `scripts/mcp-*.sh`; do not run this service with
`docker compose up`.
