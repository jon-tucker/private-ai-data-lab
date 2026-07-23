# Oracle SQLcl MCP Server

## Scope

Version 0.7.0 introduces Oracle SQLcl 26.2 as the local Oracle Database MCP
Server. It exposes Oracle database tools to an MCP-compatible client through
standard input/output.

This is distinct from OCI Database Tools MCP Server and the managed Autonomous
AI Database MCP endpoint. This platform uses SQLcl because the database runs
locally and SQLcl supports Oracle Database 19c and later without requiring OCI.

Official references:

- [Oracle SQLcl](https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/)
- [SQLcl downloads](https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/download/)
- [Starting and managing the SQLcl MCP Server](https://docs.oracle.com/en/database/oracle/sql-developer-command-line/25.3/sqcug/starting-and-managing-sqlcl-mcp-server.html)
- [Configuring SQLcl MCP restriction levels](https://docs.oracle.com/en/database/oracle/sql-developer-command-line/25.3/sqcug/configuring-restrict-levels-sqlcl-mcp-server.html)

## Pinned software

```text
Image:  container-registry.oracle.com/database/sqlcl:26.2.0
Build:  26.2.0.181.2110
Digest: sha256:e0bddbcdfda9b2d83ce91af74c3f5ed71768ad29bbcd5523da837c4051056a54
Java:   Oracle Java 17.0.10
```

## Security model

The upstream image declares no user and therefore defaults to root. The
platform overrides it with numeric UID:GID `54321:54321`, matching the
image-provided `oracle` account.

Additional boundaries:

- SQLcl defaults to MCP restriction level 4, its most restrictive mode.
- The container root filesystem is read-only.
- All Linux capabilities are dropped.
- Privilege escalation is disabled.
- No host port is published.
- The SQLcl home is mode `0700`.
- The database password file is mode `0600` and never mounted into the
  long-running database, ORDS, Open WebUI, or Ollama containers.
- SQLcl does not record `CONNECT` commands in command history, and the
  connection store is hardened after creation.
- The MCP account does not receive the `ORACLE_AI` workspace-owner password.

## Persistent state and secrets

```text
/srv/oracle-ai-data/mcp/sqlcl-home/
└── .dbtools/
    ├── connections/       # SQLcl encrypted saved connections
    └── sqlcl/             # SQLcl local state

/srv/oracle-ai-secrets/
├── mcp-database-password
└── .mcp-database-user-created
```

Back up the SQLcl home and its password file together. A saved connection is
not a substitute for the original database credential.

## Database authorization

The default database objects are:

```text
User:          ORACLE_AI_MCP
Role:          ORACLE_AI_MCP_READ_ROLE
Source schema: ORACLE_AI
```

The user receives only:

- `CREATE SESSION`
- `ORACLE_AI_MCP_READ_ROLE`

SQLcl also requires its connection user to own `DBTOOLS$MCP_LOG` for its
documented activity log. The bootstrap script temporarily grants `CREATE
TABLE`, runs the protocol test that creates the table, and immediately revokes
the privilege. A bounded `25M` `USERS` quota remains for this audit table.

The synchronization script grants `SELECT` on existing `ORACLE_AI` tables,
views, and materialized views to the role. It intentionally does not grant:

- DBA or catalog roles
- object creation privileges
- `EXECUTE` on PL/SQL
- modification privileges
- access to other application schemas

Run the synchronization script again after adding approved objects to the
source schema.

## Foundation workflow

Configure the local environment, create the credential, and prepare the SQLcl
home:

```bash
./scripts/mcp-configure-env.sh
./scripts/mcp-create-secret.sh
./scripts/mcp-prepare-host.sh
./scripts/mcp-validate.sh
```

Review the pending database identity in `.env`, then create it:

```bash
./scripts/mcp-create-database-user.sh
./scripts/mcp-sync-read-grants.sh
```

Save and verify the SQLcl connection:

```bash
./scripts/mcp-save-connection.sh
./scripts/mcp-list-connections.sh
./scripts/mcp-smoke-test.sh
./scripts/mcp-status.sh
```

Bootstrap and verify the SQLcl audit table:

```bash
./scripts/mcp-bootstrap-audit.sh
```

After bootstrap, the user again has only `CREATE SESSION`; the quota supports
the existing audit table but does not allow new tables without `CREATE TABLE`.

Launch the server manually for inspection:

```bash
./scripts/mcp-server.sh
```

An MCP client normally launches this script itself and manages its lifetime.
Pressing `Ctrl+C` during a manual test may produce an end-of-input stack trace
from the upstream Java MCP transport; this is not a failed startup.

## Client configuration

An MCP client running directly on `oracle-ai` can use:

```json
{
  "mcpServers": {
    "oracle-ai-sqlcl": {
      "command": "/srv/oracle-ai/scripts/mcp-server.sh"
    }
  }
}
```

For a client running on another computer, use an SSH wrapper that preserves
standard input and output without allocating a pseudo-terminal:

```json
{
  "mcpServers": {
    "oracle-ai-sqlcl": {
      "command": "ssh",
      "args": [
        "-T",
        "oracle-ai",
        "/srv/oracle-ai/scripts/mcp-server.sh"
      ]
    }
  }
}
```

Do not add `-t` or `-tt`; a pseudo-terminal can corrupt MCP protocol traffic.

## Increasing capabilities

Keep `MCP_RESTRICT_LEVEL=4` unless a documented use case requires more SQLcl
commands. Levels 0 through 3 expand SQLcl capabilities and must be treated as
a separate security decision.

Database write access is independent of the SQLcl restriction level. Never
grant modification privileges merely to make a generated prompt succeed.
Design a separate reviewed role or connection for an explicitly authorized
write workflow.
