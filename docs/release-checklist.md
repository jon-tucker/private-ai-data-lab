# v1.0 release checklist

## Source

- [ ] Working tree contains only reviewed release changes.
- [ ] Shell syntax and Compose configuration pass.
- [ ] No local environment, credential, key, wallet, backup, or VM image is
      tracked.
- [ ] Container images use reviewed pinned versions.
- [ ] README, changelog, security policy, contribution guide, and operator
      runbook are current.

## Runtime

- [ ] `platform-readiness-validate.sh` ends with
      `PLATFORM_READINESS=PASS`.
- [ ] Agent Factory works through `https://oracle-ai.local/agentFactory/`.
- [ ] Read-only agent behavior and prohibited-write refusal remain verified.
- [ ] Health and backup timers are enabled and active.
- [ ] The newest retained recovery set has an independent verification marker.

## Release

- [ ] `release-validate.sh` ends with `RELEASE_VALIDATION=PASS`.
- [ ] Release metadata is committed on the release branch.
- [ ] The release branch is fast-forwarded to `main`.
- [ ] An annotated `v1.0.0` tag is pushed.
- [ ] A source archive is created without `.git`, `.env`, generated outputs,
      or AppleDouble metadata.
- [ ] The transferred archive checksum matches the server checksum.
