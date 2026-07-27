# Agent operations and recovery

Version 0.11 introduces coordinated operational checks and cold backups for
the verified Agent Factory, SQLcl MCP, Ollama, and Oracle Database solution.

## Configure

Add the operational defaults to the local environment:

```bash
./scripts/agent-operations-configure-env.sh
```

The defaults warn when the MCP certificate has fewer than 90 days remaining
or when the platform filesystem reaches 80 percent utilization.

Validate the configured paths, thresholds, certificates, and VM definition:

```bash
./scripts/agent-operations-validate.sh
```

## Health

Run the unified health check:

```bash
./scripts/agent-operations-health.sh
```

It checks:

- Oracle Database, Ollama, MCP HTTP, and MCP TLS container states
- Agent Factory VM state, SSH access, and application HTTP response
- trusted access to the private MCP HTTPS health endpoint
- MCP server-certificate lifetime
- platform filesystem utilization

Warnings do not fail the command. Failed required services do.

## Capacity and retention reports

```bash
./scripts/agent-operations-storage-report.sh
./scripts/agent-operations-retention-report.sh
```

The storage report uses `sudo` to read service-owned paths. The retention
report lists coordinated backup sets and their allocation. Neither command
changes or deletes data.

Version 0.14 adds policy evaluation and explicit cleanup through
`backup-lifecycle-retention.sh`. See `docs/backup-lifecycle.md`.

## Coordinated cold backup

Schedule an outage before running:

```bash
./scripts/agent-operations-backup.sh --confirm
```

The command records initial service states, shuts down Agent Factory, stops
the MCP bridge, ORDS, and Oracle Database, creates offline sparse VM copies,
archives the cold database and MCP connection store, validates them, writes
checksums, and restores the prior running states. Output is stored beneath:

```text
/srv/oracle-ai-data/backups/agent-operations/TIMESTAMP/
├── MANIFEST.txt
├── SOURCE_STATE.txt
├── SHA256SUMS
├── database/
│   └── oracle.tar.gz
├── host/
│   └── mcp.tar.gz
└── vm/
    ├── agent-factory.xml
    ├── agent-factory-build.qcow2
    └── agent-factory-ol8.qcow2
```

Verify a completed set independently:

```bash
./scripts/agent-operations-verify-backup.sh \
  /srv/oracle-ai-data/backups/agent-operations/TIMESTAMP
```

New backup sets record the Git revision and dirty-worktree state in
`MANIFEST.txt`. `SOURCE_STATE.txt` records the corresponding short Git status
so a recovery operator does not mistake an uncommitted deployment for a clean
revision.

## Recovery policy

Do not delete the pre-install or post-install VM recovery points until a
restore drill succeeds. Do not restore into the active paths while services
are running. A full restore replaces authoritative data and therefore remains
an explicit, separately reviewed procedure.

Secrets under `/srv/oracle-ai-secrets` require a separate encrypted backup.
The coordinated data backup intentionally does not copy them.
