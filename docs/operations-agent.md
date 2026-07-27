# Operations agent

Version 0.13.0 adds a queryable operational repository for scheduled health
checks and coordinated backups.

## Data model

The repository is owned by `ORACLE_AI`:

- `OPERATIONS_RUN` records execution timing, status, counts, and a bounded log
  excerpt.
- `OPERATIONS_CHECK` records individual `PASS`, `WARN`, and `FAIL` lines.
- `BACKUP_CATALOG` records recovery-set paths and manifest metadata.
- `OPERATIONS_LATEST` exposes the newest run of each type.
- `OPERATIONS_SUMMARY` provides daily totals.

Agent Factory reads these objects as `ORACLE_AI_MCP` through
`ORACLE_AI_MCP_READ_ROLE`. It receives no write privilege.

## Installation

```bash
./scripts/operations-agent-configure-env.sh
./scripts/operations-agent-install.sh
./scripts/operations-agent-status.sh
./scripts/operations-agent-smoke-test.sh
```

Once installed, `observability-run.sh` records health and backup executions.
Recording failures produce a warning but preserve the monitored command's
original result.

## Retention

The default retention period is 365 days. Review the configured value before
deleting anything:

```bash
./scripts/operations-agent-validate.sh
./scripts/operations-agent-purge.sh --confirm
```

## Agent Builder guidance

Attach the existing private `oracle_sqlcl_readonly` MCP server and allow the
connection and read-only SQL tools. Instruct the agent to connect using
`oracle_ai_readonly`, query only `ORACLE_AI.OPERATIONS_*` and
`ORACLE_AI.BACKUP_CATALOG`, and never run DDL, DML, PL/SQL, administrative, or
SQLcl commands.

Useful verification questions include:

- What is the latest health status and when did it complete?
- Show failed or warning checks from the last seven days.
- List recent coordinated recovery sets and their verification status.

## Verification

The published `Read-Only Platform Operations Agent` was verified through
Oracle AI Database Private Agent Factory 26.4 using the saved
`oracle_ai_readonly` SQLcl MCP connection.

Verification confirmed:

- The latest health run returned `PASS` with zero failures and zero warnings.
- Detailed health checks could be aggregated successfully by check status.
- `OPERATIONS_RUN` is the parent record and `OPERATIONS_CHECK` joins to it
  through `RUN_ID`; `RUN_NAME` belongs to `OPERATIONS_RUN`.
- The agent used only the approved read-only MCP tools.
- The agent refused a prohibited write request without attempting DDL or DML.
- Repository objects and `ORACLE_AI_MCP_READ_ROLE` grants passed the automated
  smoke test.
