# ADR 0011: Coordinate agent-platform backups and retention

- Status: Accepted
- Date: 2026-07-26

## Context

The agent solution spans Docker containers, Oracle Database files, a libvirt
virtual machine with two sparse disks, private TLS material, and configuration
stored in Git. Copying a live QCOW2 image is not a reliable backup, and
automatic age-based deletion could remove the only known-good recovery point.

## Decision

Platform backups will be cold and coordinated:

1. Record the Git revision and which services are running.
2. Shut down the Agent Factory VM and wait for `shut off`.
3. Stop the MCP bridge, ORDS, and Oracle Database.
4. Copy both sparse VM images and export the libvirt definition.
5. Archive the stopped Oracle data directory and MCP connection store.
6. Validate the images and archives and generate SHA-256 checksums.
7. Restart only services that were running before the operation, with
   dependencies started before Agent Factory.

The command requires explicit `--confirm`. A failure trap attempts service
recovery. Backup retention is report-only until a recovery drill proves which
restore points are redundant. TLS private keys and other secrets are not
silently copied into the data backup.

## Consequences

- Backups require a planned outage and enough free space for a full VM copy.
- Backup artifacts are independently verifiable and tied to a source revision.
- Administrators must preserve encrypted secret backups separately.
- Deletion remains an explicit reviewed operation.
- A restore procedure can be tested without weakening runtime isolation.
