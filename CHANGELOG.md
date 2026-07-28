# Changelog

All notable changes to this project will be documented in this file.

The project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned

- Build additional Agent Factory solutions.

### Added

- Stable `https://oracle-ai.local/agentFactory/` browser endpoint on port 443.
- Local mDNS hostname discovery through the host Avahi service.
- Staged Agent Factory edge certificate renewal and explicit application.
- Unified health monitoring for the Agent Factory edge certificate lifetime.
- Removal of the stale unreleased v0.17.0 notice from the project overview.
- ADR 0019 defining the stable local edge and certificate lifecycle.

## [0.18.0] - 2026-07-27

### Added

- Private HTTPS browser edge for Agent Factory with verified upstream TLS.
- LAN allowlisting, hardened proxy execution, and Socket.IO forwarding.
- Durable VM bridge binding and host-only firewall guidance.
- Edge lifecycle, validation, status, and smoke-test tooling.
- SSH tunnel retained as an explicit rollback path.
- ADR 0018 defining the Agent Factory browser-edge trust boundary.
- Verified trusted macOS browser access, Socket.IO transport, and read-only agent responses.

## [0.17.0] - 2026-07-27

### Added

- Completed LiteLLM HTTPS cutover with host HTTP port 4000 retired.
- Explicit rollback override for temporary restoration of the HTTP endpoint.
- Cutover validation, application, status, and negative-reachability tests.
- ADR 0017 defining HTTPS as the supported Agent Factory gateway path.

## [0.16.0] - 2026-07-27

### Added

- Private TLS proxy for the authenticated LiteLLM gateway.
- Dedicated LiteLLM CA and server-certificate generation.
- Agent Factory trust-chain installation preserving the existing MCP CA.
- Authenticated HTTPS, certificate, and Agent Factory trust smoke tests.
- Unified health monitoring for the LiteLLM TLS proxy and certificate lifetime.
- Dual HTTP/HTTPS migration with the v0.15 endpoint retained for rollback.
- ADR 0016 defining the staged model-gateway TLS migration.
- Verified authenticated Prompt Lab generation through the saved HTTPS connection.

## [0.15.0] - 2026-07-27

### Added

- Private LiteLLM gateway bound only to the libvirt host bridge.
- Protected master-key authentication without committing credentials.
- Stable OpenAI-compatible alias for the local Ollama instruction model.
- Model-gateway preparation, validation, lifecycle, status, and smoke-test tools.
- Agent Factory reachability verification with direct Ollama retained as rollback.
- ADR 0015 defining the private model-gateway boundary.
- Verified authenticated Prompt Lab generation through the saved LiteLLM connection.

## [0.14.0] - 2026-07-27

### Added

- Dry-run backup retention with explicit two-flag deletion confirmation.
- Minimum recovery-set, age, independent-verification, and path safeguards.
- Pre-backup capacity estimation with a configurable free-space reserve.
- Isolated restore-drill staging that never replaces active platform data.
- ADR 0014 defining the conservative backup-lifecycle policy.

## [0.13.0] - 2026-07-26

### Added

- Oracle-backed operational history for scheduled health and backup runs.
- Structured check results, recovery-set cataloging, and bounded log excerpts.
- Read-only latest-run and daily-summary views for Agent Factory analysis.
- Explicit installation, validation, status, smoke-test, retention, and removal workflows.
- ADR 0013 defining the operational repository trust and ownership boundary.
- Verified published read-only Platform Operations Agent queries and write refusal.

## [0.12.0] - 2026-07-26

### Added

- Systemd-based daily platform health checks with persistent scheduling.
- Opt-in weekly coordinated cold backups with randomized scheduling.
- Journald-native operational logging and status inspection.
- Optional failure notifications through a protected webhook URL file.
- Separation between unprivileged health checks and privileged backup execution.
- Non-destructive retention reporting and a documented restore-drill procedure.

## [0.11.0] - 2026-07-26

### Added

- Unified health checks for containers, Agent Factory, private MCP TLS, and storage.
- Permission-aware capacity, backup-inventory, and non-destructive retention reports.
- Coordinated cold-backup workflow for Oracle Database, SQLcl MCP state, and both Agent Factory VM disks.
- Backup manifests, checksums, offline image checks, and archive verification.
- Verified a 38 GiB coordinated recovery set and healthy service restoration.
- ADR 0011 requiring coordinated quiescence and explicit retention decisions.

## [0.10.0] - 2026-07-26

### Added

- Deterministic sales schema and reporting views for the first data agent.
- Explicit read-grant synchronization and least-privilege MCP verification.
- Data-agent installation, status, validation, smoke-test, and removal tools.
- ADR 0010 separating application data ownership from agent read access.
- Verified natural-language sales analysis by channel, product, and region.
- Verified agent-level DDL refusal and database-enforced write denial.

## [0.9.0] - 2026-07-24

### Added

- Private HTTPS bridge from Agent Factory to Oracle SQLcl MCP Server.
- Streamable HTTP transport using pinned Supergateway and Node.js versions.
- Private-CA TLS proxy bound only to the libvirt bridge.
- Agent Factory CA installation, lifecycle, validation, and smoke-test automation.
- Verified read-only MCP tool execution as `ORACLE_AI_MCP` in `FREEPDB1`.

## [0.8.0] - 2026-07-24

### Added

- Verified Private Agent Factory 26.4 installation, database repository, and reboot persistence.
- Configured the local Ollama `qwen3:4b-instruct` model and bundled `multilingual-e5-base` embeddings.
- Verified Prompt Lab inference with all model layers allocated to the Radeon 890M through ROCm.

- Oracle Linux 8.10 KVM boundary for Private Agent Factory 26.4.
- Rootless Podman, dedicated build storage, private database and Ollama connectivity.
- Agent Factory environment, VM lifecycle, preflight, secret, and database-user automation.
- Multitenant-safe `MAX_STRING_SIZE=EXTENDED` conversion and rollback documentation.
- ADR 0008 documenting Agent Factory host isolation and network boundaries.

## [0.7.0] - 2026-07-23

### Added

- Oracle SQLcl MCP Server 26.2 deployment foundation.
- Pinned SQLcl container image with non-root, capability-free execution.
- Persistent protected SQLcl connection store outside Git.
- Dedicated read-only Oracle database user and grant-synchronization workflow.
- Secret creation, preparation, validation, connection, launch, and smoke-test scripts.
- MCP protocol and read-only query verification.
- Documented the SQLcl 26.2 audit-log limitation observed during deployment.
- ADR 0007 documenting MCP identity, state, transport, and restriction boundaries.

## [0.6.0] - 2026-07-23

### Added

- Oracle APEX 26.1 full-development deployment foundation.
- Official archive checksum, source preparation, and prerequisite validation.
- Dedicated `APEX` and `APEX_FILES` tablespace workflow.
- Interactive APEX instance-administrator configuration without credential exposure.
- ORDS proxied PL/SQL gateway configuration and local `/i/` resources.
- APEX status, smoke-test, deployment, and upgrade documentation.
- ADR 0006 separating APEX software, persistent resources, and installation.
- Verified APEX 26.1.0 installation, object validity, ORDS proxy integration, local static resources, and browser administrator authentication.
- Created and verified the `ORACLE_AI` workspace, schema, generated tablespace, and `JON` developer login.

## [0.5.0] - 2026-07-23

### Added

- Verified ORDS 26.2.0 metadata, runtime health, LAN connectivity, and secret isolation.
- ORDS 26.2.0 deployment foundation with explicit install and runtime services.
- Secret-safe ORDS installation, lifecycle scripts, validation, smoke testing, and documentation.

## [0.4.0] - 2026-07-22

### Added

- Open WebUI Compose stack pinned to `v0.10.2`.
- Persistent Open WebUI application data under `/srv/oracle-ai-data/open-webui`.
- Stable signing and encryption key stored outside Git under `/srv/oracle-ai-secrets`.
- Open WebUI preparation, validation, lifecycle, status, logging, and smoke-test scripts.
- Private backend-network connection from Open WebUI to Ollama.
- Open WebUI deployment, first-run hardening, and recovery documentation.
- ADR 0004 documenting identity and encryption-key persistence.
- Verified Open WebUI `v0.10.2` deployment and recorded its immutable image digest.
- Verified administrator, configuration, and chat persistence across a cold backup and container-image upgrade.
- Selected `qwen3:4b-instruct` as the non-thinking everyday model while retaining `qwen3:4b` for reasoning.
- Increased the default Ollama context from 4,096 to 8,192 tokens for Open WebUI system and feature schemas.
- Verified authenticated browser chat through Open WebUI with 100% GPU model allocation.

## [0.3.0] - 2026-07-22

### Added

- Ollama Compose stack with selectable ROCm and CPU profiles.
- Persistent model storage under `/srv/oracle-ai-data/ollama`.
- Ollama preparation, validation, lifecycle, model, and accelerator-verification scripts.
- Pinned Ollama `0.32.0` images and a configurable initial model.
- Ollama deployment documentation and ADR 0003.
- Explicit integrated-GPU enablement for the Radeon 890M reference host.
- Verified `qwen3:4b` inference with all 37 model layers allocated to ROCm and `100% GPU` reported by Ollama.
- Recorded the deployed Ollama image digest and model identifier.

## [0.2.0] - 2026-07-22

### Added

- Oracle AI Database 26ai Free Compose stack pinned to release `23.26.2.0`.
- Persistent database storage under `/srv/oracle-ai-data/oracle`.
- Password creation and post-start password application workflow.
- Host preparation, validation, start, stop, status, logs, SQL*Plus, and password-rotation scripts.
- Oracle database deployment and operations documentation.
- ADR 0002 documenting Docker password-handling trade-offs.
- Verified Oracle AI Database Free `23.26.2.0.0`, `FREEPDB1`, archive logging, force logging, component validity, and AI Vector Search.
- Recorded the deployed image digest and tested container recreation with persistent database files.
- Corrected the backend network so explicitly published ports remain reachable from approved LAN clients.

## [0.1.0] - 2026-07-21

### Added

- Initial repository structure.
- Project overview, architecture, and build journal.
- Source, persistent-data, and secrets separation.
- Base Compose project with shared network definitions.
- Environment-variable template and repository safety rules.
- First architecture decision record.
