# ADR 0012: Schedule observability with systemd

## Status

Accepted

## Context

The platform has verified health, capacity, backup, and backup-verification
commands, but they depend on manual execution. Missed checks are invisible,
and coordinated backups require privileged access to VM images and persistent
database files.

## Decision

Use host systemd services and timers for scheduled operations.

- Run daily health checks as the unprivileged platform owner.
- Run coordinated cold backups as root because they must quiesce services and
  copy protected VM and database state.
- Keep the backup timer disabled until explicitly enabled by the operator.
- Use persistent timers with randomized delays and UTC calendar expressions.
- Write operational output to journald.
- Send failure notifications only when a protected webhook URL file exists.
- Continue reporting retention candidates without deleting backups.

## Consequences

Health checks resume after missed schedules and have a durable journal trail.
Backups can run unattended only after an explicit opt-in. Root execution is
limited to a fixed repository command in a static systemd unit, and webhook
credentials remain outside Git.
