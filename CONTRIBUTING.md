# Contributing

## Scope

Changes should preserve the platform's documented boundaries:

- Source-controlled configuration under `/srv/oracle-ai`.
- Mutable state under `/srv/oracle-ai-data`.
- Credentials and private key material under `/srv/oracle-ai-secrets`.
- Private service publication unless a reviewed edge explicitly exposes it.

## Workflow

1. Start from current `main` on a focused branch.
2. Keep unrelated changes out of the branch.
3. Update operational documentation with behavior changes.
4. Add or update validation and recovery procedures where appropriate.
5. Run the relevant component checks and the unified readiness validator.
6. Review the staged diff for credentials and generated state before commit.

## Required validation

Run:

```bash
./scripts/release-validate.sh
```

For changes that intentionally affect running services, also verify the
documented rollback path before release.

## Safety

Never commit `.env`, passwords, tokens, wallets, private keys, generated
certificates, database files, VM images, or backup sets. Do not make
destructive cleanup, retention, or restore behavior automatic without
explicit confirmation and path safeguards.
