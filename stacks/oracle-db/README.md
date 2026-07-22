# Oracle AI Database 26ai Free stack

This stack deploys Oracle AI Database 26ai Free as the platform's persistent database service.

## Fixed database identity

- SID: `FREE`
- Root service: `FREE`
- PDB: `FREEPDB1`
- Listener port: `1521`

Oracle AI Database Free does not permit changing the SID or PDB name.

## Persistent storage

The host directory `${PLATFORM_DATA_ROOT}/oracle` is mounted at `/opt/oracle/oradata`. It must be writable by UID and GID `54321`, the Oracle account inside the image.

## Health

The official image supplies its own health check. Platform scripts wait for Docker to report `healthy` before changing passwords or declaring the service ready.

## References

- [Oracle AI Database Free quick start](https://www.oracle.com/database/free/get-started/)
- [Oracle Database container image documentation](https://github.com/oracle/docker-images/blob/main/OracleDatabase/SingleInstance/README.md)
