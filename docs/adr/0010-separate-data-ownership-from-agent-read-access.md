# ADR 0010: Separate data ownership from agent read access

## Status

Accepted

## Context

The first Agent Factory database solution needs useful data while preserving
the read-only boundary proven in version 0.9. The `ORACLE_AI` APEX parsing
schema can own application objects, but its broad object-creation privileges
must not be exposed to an autonomous agent.

## Decision

`ORACLE_AI` owns the versioned demonstration tables and views.
`ORACLE_AI_MCP_READ_ROLE` receives `SELECT` on those objects, and the saved
SQLcl connection authenticates as `ORACLE_AI_MCP`.

Installation data is deterministic and guarded against overwriting existing
objects. Grants are synchronized only by an explicit administrative script.
Validation checks row counts, reporting totals, object grants, MCP system
privileges, and tablespace quota. A smoke test also proves that the MCP
identity cannot create a table.

## Consequences

- Agent queries cannot mutate the application schema through database
  privileges.
- APEX and future application code can manage data as `ORACLE_AI` without
  sharing that credential with MCP.
- New tables or views are invisible to MCP until grants are synchronized.
- Demonstration data is reproducible and suitable for regression testing.
- The Agent Factory prompt and allowed-tool list remain defense-in-depth, not
  the primary authorization boundary.
