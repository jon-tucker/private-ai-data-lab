# ADR 0007: Isolate SQLcl MCP identity, state, and capabilities

- Status: Accepted
- Date: 2026-07-23

## Context

The SQLcl MCP Server allows an AI client to select saved Oracle connections and
execute database tools. Combining an unrestricted SQLcl process with a
workspace-owner or administrative database account would make prompt mistakes
and untrusted content unnecessarily dangerous.

The official SQLcl container also defaults to root and MCP uses standard
input/output rather than an authenticated network endpoint.

## Decision

The platform will:

1. Pin SQLcl to the verified `26.2.0` image.
2. Run the container as numeric UID:GID `54321:54321`.
3. Use SQLcl's default restriction level 4.
4. Launch SQLcl on demand over standard input/output with no published port.
5. Persist only `/home/oracle` under `/srv/oracle-ai-data/mcp/sqlcl-home`.
6. Store the database password under `/srv/oracle-ai-secrets`.
7. Use a dedicated `ORACLE_AI_MCP` account rather than `SYS`, `SYSTEM`, or the
   `ORACLE_AI` APEX workspace owner.
8. Grant read access through `ORACLE_AI_MCP_READ_ROLE` only after an explicit
   synchronization operation.
9. Keep database write access and lower SQLcl restriction levels outside the
   default deployment.
10. Keep object-creation privileges and tablespace quota out of the default MCP
    account. SQLcl 26.2 did not create its documented `DBTOOLS$MCP_LOG` during
    successful protocol calls or a controlled temporary-privilege test.

## Consequences

- MCP can inspect approved application data without owning it.
- Newly created source objects are invisible until grants are synchronized.
- Some SQLcl tools and generated operations will be rejected by design.
- The deployment does not rely on SQLcl's documented MCP audit table because it
  was not created by the verified 26.2 image.
- Database-native auditing should be introduced separately if detailed MCP
  activity records are required.
- Remote clients require an SSH standard-input/standard-output wrapper or
  another deliberately reviewed transport bridge.
- Backups must preserve both the SQLcl connection store and its corresponding
  secret material.
