# Operator runbook

This runbook is the concise operational entry point for the Oracle AI Data
Platform. Detailed procedures remain in the component documents.

## Routine readiness check

Run:

```bash
./scripts/platform-readiness-validate.sh
```

A ready platform ends with:

```text
PLATFORM_READINESS=PASS
```

The validator checks runtime health, the Agent Factory browser edge, host and
guest startup configuration, container restart policies, scheduled health and
backup timers, recovery-set availability, and source configuration.

## After a host reboot

Allow the Agent Factory VM and application time to start, then run the
readiness validator. The supported browser endpoint is:

`https://oracle-ai.local/agentFactory/`

## Backups

The weekly coordinated-backup timer is enabled. Review its status with:

```bash
systemctl list-timers oracle-ai-backup.timer --all --no-pager
```

Use the documented agent-operations and backup-lifecycle procedures for
manual creation, independent verification, retention, or an isolated restore
drill. Never delete a recovery set outside the guarded retention workflow.
Secrets are backed up separately in encrypted form; follow
[secret recovery](secret-recovery.md) before planning a complete service restore.

## Certificates

The unified health check monitors the MCP, LiteLLM, and Agent Factory edge
certificate lifetimes. Stage an edge replacement before applying it:

```bash
./scripts/agent-factory-edge-renew-tls.sh
```

After review, apply it with the explicit `--apply` flag.

## Recovery paths

- Agent Factory browser edge: use the documented SSH tunnel.
- LiteLLM HTTPS: use the explicit HTTP rollback Compose override temporarily.
- Platform data: restore only through an isolated restore drill before any
  recovery decision affecting active paths.
- Source: recover the tagged release from Git or its matching source archive.
