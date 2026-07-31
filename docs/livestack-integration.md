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
- provides no schema installer and does not start the application.

The vendor database, ORDS, and Ollama definitions are deliberately excluded.

## Source boundary

The supplied `livestack.zip` is input material and is not committed. Configure
`LIVESTACK_ARCHIVE`, then run:

```bash
./scripts/livestack-stage-source.sh
```

The sanitized result is stored beneath `/srv/oracle-ai-work/livestack`, outside
the repository, persistent data, and secrets roots.

## Deferred activation

Activation remains blocked until a later verified change provides:

1. a reviewed least-privilege `LIVESTACK` schema installer;
2. a mode-0600 database password file;
3. schema removal and rollback procedures;
4. a successful build and database smoke test;
5. application authorization or a protected HTTPS edge.

The original `00_setup.sql` is not approved because it contains broad
privileges, unrestricted database network access, and a default password.
