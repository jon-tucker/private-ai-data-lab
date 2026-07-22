# ADR 0002: Apply the Oracle administrator password after first startup

- **Status:** Accepted
- **Date:** 2026-07-21

## Context

The official Oracle AI Database Free image accepts `ORACLE_PWD`, but Docker stores container environment variables in inspectable metadata. Oracle documents secure encrypted password delivery through Podman secrets; the current platform runtime is Docker Engine.

## Decision

Do not set `ORACLE_PWD` in Compose. On first creation:

1. Allow the official image to generate a random initial password.
2. Wait for the image's built-in health check to report healthy.
3. Copy the locally protected password file into the running container temporarily.
4. Invoke Oracle's supported `/opt/oracle/setPassword.sh` utility.
5. Delete the temporary in-container file and record a local application marker.

Store the durable local password at `/srv/oracle-ai-secrets/oracle-db-password` with mode `0600`.

## Consequences

### Positive

- The chosen password does not persist in Compose configuration or Docker environment metadata.
- Password rotation uses Oracle's supplied utility.
- The public repository contains no credential material.

### Trade-offs

- The image's generated initial password is visible briefly in initialization logs until changed.
- The password exists briefly in the argument list of the in-container password utility.
- The marker file and persistent database state must remain consistent.
- This workflow is Docker-specific; a Podman deployment should use Oracle's documented encrypted secrets mechanism instead.

## Revisit conditions

Revisit this decision if Oracle adds Docker secret-file support, the platform changes to Podman, or a dedicated secrets manager is introduced.
