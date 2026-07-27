# Scheduled observability

Version 0.12 adds systemd scheduling around the verified v0.11 operational
commands. Host schedules use UTC even when user-facing services use a different
timezone.

## Default schedules

- Health check: daily at 06:15 UTC, with up to 15 minutes randomized delay.
- Coordinated backup: Sunday at 04:00 UTC, with up to 30 minutes randomized
  delay.

Persistent timers run a missed job after the host becomes available again.
The health timer is enabled during installation. The backup timer is opt-in
because it stops Agent Factory, MCP, ORDS, and Oracle Database while creating
the coordinated recovery set.

## Install

```bash
./scripts/observability-configure-env.sh
./scripts/observability-validate.sh
./scripts/observability-install.sh
./scripts/observability-test-health.sh
./scripts/observability-status.sh
```

After reviewing the schedule and available capacity:

```bash
./scripts/observability-install.sh --enable-backup
```

## Failure notifications

Webhook alerts are optional. Put a single HTTPS webhook URL in the configured
file and protect it:

```bash
install -m 0600 /dev/null /srv/oracle-ai-secrets/observability-webhook-url
```

Edit the file locally without printing its value. If the file is absent or
empty, failures remain visible in journald and no network notification is
attempted.

## Logs and status

```bash
./scripts/observability-status.sh
journalctl -u oracle-ai-health.service
journalctl -u oracle-ai-backup.service
```

## Restore drill

Automated backup creation does not prove recovery. Before release and after
material storage changes:

1. Select a completed recovery set.
2. Run `agent-operations-verify-backup.sh` against it.
3. Record its manifest, checksum result, size, and creation time.
4. Restore copies of both QCOW2 images to an isolated libvirt pool.
5. Extract Oracle and MCP archives to an isolated filesystem.
6. Confirm image checks, archive integrity, expected paths, and ownership.
7. Do not attach restored storage to production service names.
8. Record elapsed time and cleanup of the isolated drill.

Automatic deletion remains out of scope. Use the retention report to make an
explicit, reviewed decision.

## Verified deployment

The observability services were verified on 2026-07-26:

- the daily health service completed with zero failures and zero warnings;
- a 38 GB coordinated recovery set passed checksum and QCOW2 validation;
- all stopped platform services recovered healthy after backup;
- recovery-set directories use mode `0700` and sensitive files use mode `0600`;
- `oracle-ai-health.timer` and `oracle-ai-backup.timer` are enabled and active.
