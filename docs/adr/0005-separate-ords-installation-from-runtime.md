# ADR 0005: Separate ORDS installation from runtime

## Status

Accepted

## Context

The official ORDS container can install or upgrade database metadata automatically when
SYS credentials are supplied at startup. Keeping those credentials attached to every
runtime restart expands their exposure and makes database-changing upgrades implicit.

## Decision

Use an explicit `ords-install` Compose profile for installation and upgrades. Passwords
are streamed through standard input and are not stored in Compose environment variables.
The normal `ords` service receives no SYS password and uses persisted ORDS configuration.

## Consequences

Installation and upgrades require an intentional administrator command. Routine container
restarts cannot silently modify ORDS database metadata.
