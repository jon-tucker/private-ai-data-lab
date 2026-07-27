# Backup lifecycle

Version 0.14 adds conservative lifecycle controls around coordinated recovery
sets.

## Configure and validate

```bash
./scripts/agent-operations-configure-env.sh
./scripts/backup-lifecycle-validate.sh
./scripts/backup-lifecycle-capacity-check.sh
```

Defaults retain at least the two newest coordinated sets, require a set to be
30 days old before it can be considered, and preserve a 15 percent filesystem
reserve for the next backup.

## Record independent verification

Verification is read-only unless `--record` is supplied:

```bash
./scripts/agent-operations-verify-backup.sh \
  --record \
  /srv/oracle-ai-data/backups/agent-operations/TIMESTAMP
```

`--record` writes `VERIFICATION.txt` only after checksums, compressed archives,
and both QCOW2 images pass.

## Evaluate and apply retention

The default mode reports policy decisions without deleting data:

```bash
./scripts/backup-lifecycle-retention.sh
```

Deletion requires both explicit flags:

```bash
./scripts/backup-lifecycle-retention.sh \
  --apply \
  --confirm-delete
```

Unverified sets, recent sets, and the configured minimum number of newest sets
are never eligible. Only timestamp-named directories directly beneath the
coordinated backup root are considered. Historical backup groups elsewhere
under `/srv/oracle-ai-data/backups` are excluded.

## Stage a restore drill

```bash
./scripts/backup-lifecycle-restore-drill.sh \
  /srv/oracle-ai-data/backups/agent-operations/TIMESTAMP \
  --confirm-staging
```

The command re-verifies the recovery set and extracts the Oracle and MCP
archives into the isolated restore-drill root. It does not stop services,
replace active files, define a VM, or modify an active deployment. Review the
staged contents and remove them only through a separately approved cleanup.

## Verification

The backup lifecycle was verified with the coordinated recovery set created at
`20260726T234403Z`.

Verification confirmed:

- All recorded SHA-256 checksums passed.
- Both Agent Factory QCOW2 images passed `qemu-img check`.
- Database and MCP archives passed integrity checks.
- A durable verification marker was recorded.
- Database and MCP data were staged into an isolated restore-drill directory.
- Active platform data and service paths were not modified.
- Post-drill platform health passed with zero failures and zero warnings.
- Retention dry-run protected both existing coordinated backup sets.
