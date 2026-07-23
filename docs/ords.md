# Oracle REST Data Services

## Version

- Image: `container-registry.oracle.com/database/ords:26.2.0`
- Verified digest: `sha256:6c510faf38965e2901b6bbd5ecf179f15af6909481de3e65446505d6d4d1eba0`
- Database service: `oracle-db:1521/FREEPDB1`
- Configuration: `/srv/oracle-ai-data/ords`
- URL: `http://192.168.0.209:8080/ords/`

## Initial deployment

```bash
./scripts/ords-configure-env.sh
./scripts/ords-create-secret.sh
./scripts/ords-prepare-host.sh
./scripts/ords-validate.sh
./scripts/ords-install.sh
./scripts/ords-start.sh
./scripts/ords-smoke-test.sh
```

The installer enables Database Actions, Database API, REST-Enabled SQL, and proxied
PL/SQL gateway mode. The latter prepares ORDS for the later APEX milestone.

## Security

The existing Oracle administrator password and generated ORDS runtime password remain
outside Git. The one-time installer streams them to ORDS over standard input. The normal
container has no administrator password mounted or configured.

## Operations

```bash
./scripts/ords-status.sh
./scripts/ords-logs.sh
./scripts/ords-stop.sh
./scripts/ords-start.sh
```

Back up the ORDS configuration directory and the corresponding secret before upgrades.
ORDS database metadata upgrades are explicit and must not occur through a routine restart.
