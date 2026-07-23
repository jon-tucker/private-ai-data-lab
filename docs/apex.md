# Oracle APEX

Version 0.6.0 adds Oracle APEX 26.1 as a full development environment in
`FREEPDB1`.

## Version choice

The public Oracle download installs APEX 26.1.0. Oracle's May 25, 2026
English-only archive has SHA-256:

```text
b277aa4650d2d4c5e88e8e3738e8098cddd7be7443376ae590ae8fab8b427919
```

The 26.1.2 Patch Set Bundle is distributed separately through My Oracle Support.
It is an upgrade milestone, not silently folded into the base installation.

## Storage boundaries

| Content | Location |
| --- | --- |
| Download and expanded installer | `/srv/oracle-ai-work/apex` |
| Runtime static resources | `/srv/oracle-ai-data/apex/images` |
| APEX database metadata | Dedicated `APEX` tablespace |
| Uploaded APEX files | Dedicated `APEX_FILES` tablespace |
| Git-managed automation | `/srv/oracle-ai/scripts` |

## Prepare

Download `apex_26.1_en.zip` from Oracle, verify the published checksum, and
expand it so `APEX_SOURCE_DIR` points to the directory containing
`apexins.sql`.

```bash
./scripts/apex-configure-env.sh
./scripts/apex-prepare-host.sh
./scripts/apex-validate.sh
./scripts/apex-preflight.sh
```

The reference host passed these prerequisites:

- Oracle AI Database 26ai Free 23.26.2
- ORDS 26.2.0
- Oracle XML DB valid
- `WORKAREA_SIZE_POLICY=AUTO`
- PGA 512 MB
- total SGA approximately 1,529 MB
- autoextending `SYSTEM`, `SYSAUX`, and `USERS` datafiles

## Install

Do not disconnect or interrupt this operation. Run it inside tmux:

```bash
./scripts/apex-install.sh
```

The installer stops ORDS, stages the software temporarily inside the database
container, derives the PDB datafile directory from the existing `USERS`
tablespace, creates dedicated tablespaces if absent, and runs:

```sql
@apexins.sql APEX APEX_FILES TEMP /i/
```

After a successful database installation:

```bash
./scripts/apex-create-admin.sh
./scripts/apex-configure-ords.sh
./scripts/apex-status.sh
./scripts/apex-smoke-test.sh
```

The administrator helper is intentionally interactive so its password does not
appear in command arguments, Compose configuration, shell history, or Git.

APEX 26.1 performs its ORDS database integration during `apexins.sql`. A separate
`apex_rest_config.sql` run is neither required nor included in this workflow.

## ORDS integration

ORDS continues connecting as `ORDS_PUBLIC_USER`. APEX uses proxied PL/SQL
gateway mode:

```text
ORDS_PUBLIC_USER -> APEX_PUBLIC_USER
```

The local APEX images directory is mounted read-only in the runtime container and
served under `/i/`. The ORDS request-validation function remains
`ords_util.authorize_plsql_gateway`.

## Verification

Confirm the registry component, database accounts, and object validity:

```bash
./scripts/apex-status.sh
```

Confirm both the ORDS landing endpoint and `/i/` static resources:

```bash
./scripts/apex-smoke-test.sh
```

Then open:

```text
http://192.168.0.209:8080/ords/
```

## Upgrade policy

Before applying an APEX Patch Set Bundle or installing a newer APEX release:

1. Back up the Oracle database and ORDS configuration.
2. Record the currently installed APEX and ORDS versions.
3. Verify the patch archive checksum and included README.
4. Stop ORDS.
5. Apply the patch using Oracle's instructions.
6. Update the local static images or CDN version to match.
7. Run `sys.validate_apex`.
8. Restart ORDS and repeat all status and smoke tests.

Do not replace APEX database files by recreating a container. APEX is database
metadata and must be patched or upgraded using Oracle's supported SQL workflow.

## Verified v0.6.0 deployment

The reference deployment was verified on July 23, 2026:

- Oracle APEX `26.1.0` installed in schema `APEX_260100`.
- APEX registry component reported `VALID`.
- 4,492 valid `APEX_260100` objects and 13 valid `FLOWS_FILES` objects.
- `APEX_PUBLIC_USER` and `APEX_PUBLIC_ROUTER` open; `FLOWS_FILES` locked.
- Instance administrator `ADMIN` created and authenticated through the browser.
- ORDS `26.2.0` healthy with `plsql.gateway.mode=proxied`.
- `ORDS_PUBLIC_USER` configured to proxy to `APEX_PUBLIC_USER`.
- Local `/i/` static resources and the APEX landing endpoint passed smoke tests.
- Cold pre-installation database backup created with SHA-256
  `6c94c163d471044805f262b6e2518c52fa6bd763f5ec941ea3219c2fb8aec984`.
- APEX installation log retained at
  `/srv/oracle-ai-data/logs/apex/apex-install-20260723-183527.log`.
