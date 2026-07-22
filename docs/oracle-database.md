# Oracle AI Database 26ai Free

## Scope

Version 0.2.0 deploys Oracle AI Database 26ai Free as a single persistent container. ORDS, APEX, MCP, and agent services are deliberately added in later milestones.

## Image

```text
container-registry.oracle.com/database/free:23.26.2.0
```

The version tag is explicit for reproducibility. Before upgrading, pull and test the new tag, review Oracle's current documentation, update `.env.example`, and document the result in the changelog.

## Initial deployment

```bash
cd /srv/oracle-ai
cp .env.example .env
./scripts/oracle-create-secret.sh
./scripts/oracle-prepare-host.sh
./scripts/validate.sh
./scripts/oracle-start.sh
```

The start script pulls the image when necessary, waits as long as 30 minutes for first-time initialization, applies the password stored outside Git, and reports the connection services.

## Operations

```bash
./scripts/oracle-status.sh
./scripts/oracle-logs.sh
./scripts/oracle-sqlplus.sh
./scripts/oracle-stop.sh
./scripts/oracle-start.sh
./scripts/oracle-rotate-password.sh
```

## Connections

| Purpose | Connect descriptor |
| --- | --- |
| Root container | `oracle-ai:1521/FREE` |
| Pluggable database | `oracle-ai:1521/FREEPDB1` |

From outside Docker, use the server's DNS name or reserved LAN address. From future containers on the backend network, use hostname `oracle-db` and port `1521`.

## Persistence

Database files live under `/srv/oracle-ai-data/oracle`. The directory is owned by UID/GID `54321`, matching the Oracle account inside the official image. Removing the container does not remove these files.

Do not delete or replace this directory as part of ordinary Compose operations. A database backup is not equivalent to copying live datafiles; later milestones will add documented RMAN backup and restore automation.

## Initialization hooks

- `stacks/oracle-db/setup` runs after initial database creation.
- `stacks/oracle-db/startup` runs after every startup, including the initial one.

SQL setup scripts execute as SYSDBA. Startup scripts must be idempotent.

## Archive logging

Archive logging and force logging default to enabled because this project is production-inspired and will add recovery exercises. Archive logs consume storage and require a later deletion/backup policy. Change these settings only before first database creation; environment changes do not reconfigure existing datafiles.

## Password model

The official Docker image accepts `ORACLE_PWD` as an environment variable, which would persist in container inspection metadata. This project instead lets the image generate its initial random password, waits for health, and invokes Oracle's supported `setPassword.sh` using a temporary in-container file. See ADR 0002 for limitations.

## Official references

- [Oracle AI Database Free quick start](https://www.oracle.com/database/free/get-started/)
- [Oracle Database container image README](https://github.com/oracle/docker-images/blob/main/OracleDatabase/SingleInstance/README.md)
- [Oracle AI Database Free licensing restrictions](https://docs.oracle.com/en/database/oracle/oracle-database/26/xeinw/licensing-restrictions.html)
