# LiveStack integration

The Oracle Energy & Utilities LiveStack demonstration is incorporated as an
optional application workload rather than as a replacement platform.

## Foundation scope

The v1.2.0 foundation:

- reuses the running Oracle Database 23.26.2 service;
- reuses the ROCm-enabled Ollama service and `qwen3:4b-instruct`;
- reserves loopback port 8505 for initial testing;
- stages the vendor archive outside Git;
- removes bundled `.env` files and macOS metadata;
- removes the unused vendor Compose and privileged database-bootstrap files;
- removes the application's built-in database-password default;
- disables outbound usage telemetry;
- provides a bounded schema installer but does not start the application.

The vendor database, ORDS, and Ollama definitions are deliberately excluded.

## Source boundary

The supplied `livestack.zip` is input material and is not committed. Configure
`LIVESTACK_ARCHIVE`, then run:

```bash
./scripts/livestack-stage-source.sh
```

The sanitized result is stored beneath `/srv/oracle-ai-work/livestack`, outside
the repository, persistent data, and secrets roots.

## Controlled schema installation

Create the protected password file before installation. It must contain exactly
64 hexadecimal characters and be owned by `root:root` with mode `0600`.

Run:

```bash
./scripts/livestack-schema-install.sh
./scripts/livestack-schema-status.sh
./scripts/livestack-schema-smoke-test.sh
```

The installer refuses to overwrite an existing schema, limits its quota to
1,024 MB by default, stages SQL temporarily inside the database container, and
installs only the selected core and demonstration-data components.

It does not load an ONNX model or grant access to `DATA_PUMP_DIR`. Cloud AI,
database-agent, unrestricted network ACL, auditing-administration, global
demo-role, unlimited-tablespace, and VPD components are also excluded.

The compatibility package ignores the caller-provided demo username and
returns a fixed administrative demonstration context. This preserves private
application compatibility without treating `X-Demo-User` as authentication.

If installation fails after Oracle DDL has committed, inspect its output and
status. Removal is deliberately explicit:

```bash
./scripts/livestack-schema-uninstall.sh \
  --confirm-schema-drop \
  --confirm-data-loss
```

That operation drops only the `LIVESTACK` schema and its objects.

## Private application lifecycle

The verified initial deployment remains loopback-only. Use an SSH local-forward
for browser access; do not publish port 8505 to the LAN.

```bash
docker compose --profile livestack build livestack
./scripts/livestack-start.sh
./scripts/livestack-status.sh
./scripts/livestack-smoke-test.sh
./scripts/livestack-logs.sh
./scripts/livestack-stop.sh
```

From an authorized client:

```bash
ssh -N -L 127.0.0.1:8505:127.0.0.1:8505 oracle-ai
```

Browse to `http://127.0.0.1:8505/`. Closing the SSH tunnel does not stop the
application.

## Verification

The controlled deployment was verified with:

- a 1,024 MB maximum schema quota and approximately 19 MB initially allocated;
- zero invalid database objects;
- no unlimited-tablespace, role-creation, job-creation, system-alter,
  `DATA_PUMP_DIR`, or network-ACL grants;
- 18 operators, 18 field sites, 63 services/assets, 2,000 customers, 3,000
  service requests, 5,000 community signals, and 78 graph entities;
- a reproducible application image build;
- a healthy database-backed API and HTTP 200 frontend;
- publication only on `127.0.0.1:8505`;
- successful browser access through an SSH local-forward;
- successful removal of temporary credential-bearing installer material.

The original `00_setup.sql` is not approved because it contains broad
privileges, unrestricted database network access, and a default password.
