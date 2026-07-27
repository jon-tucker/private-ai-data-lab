# Build Journal

This journal records implementation milestones, operational discoveries, and lessons that may inform future documentation.

## 2026-07-21 — Platform foundation

- Installed and updated Ubuntu Server 26.04 LTS on the Minisforum AI X1 Pro.
- Confirmed AMD virtualization and IOMMU support.
- Installed Docker Engine, Docker Compose, and Portainer.
- Reserved `192.168.0.209` for host `oracle-ai` on the local network.
- Fixed a boot delay by marking the unused second Ethernet interface optional in Netplan.
- Established the runtime layout:
  - `/srv/oracle-ai` for version-controlled source.
  - `/srv/oracle-ai-data` for persistent state.
  - `/srv/oracle-ai-secrets` for credentials and private configuration.
- Configured Git author information and GitHub SSH authentication.
- Created the v0.1.0 project foundation without deploying application containers.

## 2026-07-21 — Oracle AI Database stack

- Added Oracle AI Database 26ai Free using the `23.26.2.0` image tag.
- Bound the listener to host port `1521` and retained Oracle's fixed `FREE` and `FREEPDB1` services.
- Mapped `/srv/oracle-ai-data/oracle` to `/opt/oracle/oradata`.
- Added host preparation for Oracle container UID `54321`.
- Kept the administrator password out of Compose environment metadata by allowing initial random-password creation and immediately applying the local secret after the container becomes healthy.
- Added repeatable lifecycle and validation scripts.

## 2026-07-22 — Oracle AI Database deployment verification

- Pulled and initialized Oracle AI Database Free `23.26.2.0.0`.
- Recorded image digest `sha256:696eee2ee8985af25ef0dc4cbcac14cdaadfd4545150a87d82d9724ce43c7a77`.
- Confirmed `FREEPDB1` opens read/write with archive logging and force logging enabled.
- Confirmed all 14 installed database components are valid or intentionally `OPTION OFF`, with zero invalid objects.
- Verified native `VECTOR` construction and Euclidean distance calculation in `FREEPDB1`.
- Discovered that `internal: true` on the backend network prevented Docker from activating the published listener port.
- Changed the backend to a private bridge network, recreated the container, and confirmed persistent database reuse.
- Verified listener access locally and from the LAN at `192.168.0.209:1521`.

## 2026-07-22 — Ollama stack foundation

- Confirmed the Radeon 890M is bound to the Linux `amdgpu` driver.
- Confirmed `/dev/kfd` and `/dev/dri/renderD128` are available for container passthrough.
- Confirmed the Ryzen AI NPU is independently bound to `amdxdna`; Ollama targets the Radeon GPU rather than the NPU.
- Added selectable ROCm and CPU profiles instead of assuming GPU acceleration will work on every host.
- Bound the unauthenticated Ollama API to host loopback by default while retaining backend-container access.
- Reserved persistent model storage under `/srv/oracle-ai-data/ollama`.

## 2026-07-22 — Ollama deployment verification

- Pulled `ollama/ollama:0.32.0-rocm` and recorded image digest `sha256:ed3ff2d663fba3b089807a8dca022af9fc1870bbcb7ed4bba9ce5f3939821269`.
- Confirmed Ollama and ROCm detect the Radeon 890M as `gfx1150` through `/dev/kfd` and `/dev/dri`.
- Found that Ollama deliberately drops integrated GPUs unless `OLLAMA_IGPU_ENABLE=1` is set.
- Added integrated-GPU enablement to the environment template, configuration helper, and Compose stack.
- Pulled `qwen3:4b` model ID `359d7dd4bcda` with a 2.5 GB persisted model footprint.
- Completed a successful inference smoke test.
- Confirmed `100% GPU` allocation and offload of all 37 model layers to ROCm.

## 2026-07-22 — Open WebUI stack foundation

- Selected the pinned Open WebUI `v0.9.5` image instead of the floating `main` tag.
- Connected Open WebUI to Ollama through the private backend Docker network.
- Reserved persistent state under `/srv/oracle-ai-data/open-webui`.
- Added a stable signing and encryption key outside Git for session and future MCP credential continuity.
- Published only the authenticated web interface on LAN port `3000`; the Ollama API remains on host loopback.
- Added repeatable preparation, validation, lifecycle, logging, status, and smoke-test scripts.
- Documented first-administrator registration and the requirement to disable subsequent sign-up.

## 2026-07-22 — Open WebUI deployment verification

- Deployed Open WebUI `v0.9.5`, then detected and verified the newer `v0.10.2` image before release.
- Created a cold backup of Open WebUI state and its external secret key before upgrading.
- Recorded `v0.10.2` image digest `sha256:9fcea9c6e32ab60b0498f3986c6cdf651ddbe61db48d2213a3d28048ddd673d4`.
- Confirmed account, session, configuration, and chat persistence after container replacement.
- Confirmed that first-administrator creation automatically disabled new sign-ups.
- Verified Open WebUI health and private backend connectivity to Ollama.
- Diagnosed the `qwen3:4b` alias as a thinking-only model that generated thousands of reasoning tokens for a trivial request.
- Selected `qwen3:4b-instruct` model ID `0edcdef34593` as the everyday non-thinking default.
- Diagnosed a 5,545-token Open WebUI request exceeding the 4,096-token Ollama context.
- Increased the default context to 8,192 tokens and completed authenticated browser inference with 100% GPU allocation.

## Lessons carried forward

- Preserve a strict separation between code, state, and secrets.
- Make installation and operational steps repeatable before calling a component complete.
- Pin deployable component versions once stacks are introduced.
- Validate each milestone before adding dependent services.
- Avoid undocumented firmware changes on a stable host unless there is a demonstrated need and a verified vendor procedure.


## 2026-07-23

- Began v0.5.0 ORDS deployment.
- Authenticated to Oracle Container Registry using an OCR authentication token.
- Selected ORDS 26.2.0 and recorded image digest `sha256:6c510faf38965e2901b6bbd5ecf179f15af6909481de3e65446505d6d4d1eba0`.
- Inspected the official entrypoint and adopted separate installation and runtime services.

## 2026-07-23 — Verified ORDS 26.2.0 deployment

- Installed ORDS metadata version `26.2.0.r1732140` in `FREEPDB1`.
- Verified 354 valid `ORDS_METADATA` objects.
- Started the runtime-only ORDS container without SYS credentials.
- Verified container health and HTTP access over the LAN on port 8080.
- Hardened persistent ORDS configuration and wallet files to mode `0600`.
- Enhanced the SQL*Plus helper to support interactive and redirected input.
## 2026-07-23 — Began Oracle APEX 26.1 milestone

- Verified Oracle AI Database 23.26.2 and ORDS 26.2 satisfy APEX 26.1 requirements.
- Verified XML DB, automatic work-area sizing, 512 MB PGA, and approximately 1,529 MB SGA.
- Confirmed `SYSTEM`, `SYSAUX`, and `USERS` datafiles have automatic extension enabled.
- Downloaded the May 25 English-only APEX 26.1 archive and verified Oracle's SHA-256 checksum.
- Selected dedicated `APEX` and `APEX_FILES` tablespaces.
- Added explicit installation, ORDS gateway, static-resource, validation, and verification automation.

## 2026-07-23 — Verified Oracle APEX 26.1 deployment

- Created and verified a 686 MB cold database backup before installation.
- Installed the full APEX 26.1.0 development environment in `FREEPDB1`.
- Created dedicated `APEX` and `APEX_FILES` tablespaces.
- Confirmed all installer phases completed with zero failed actions.
- Confirmed APEX 26.1 automatically performed its ORDS database integration.
- Created the `ADMIN` instance administrator and verified browser authentication.
- Configured ORDS proxied PL/SQL gateway mode and local `/i/` resources.
- Verified 4,492 valid APEX schema objects, 13 valid `FLOWS_FILES` objects,
  healthy ORDS runtime, and successful HTTP smoke tests.

## 2026-07-23 — Created initial ORACLE_AI workspace

- Created the `ORACLE_AI` workspace and matching `ORACLE_AI` database schema.
- Created the `JON` workspace administrator and developer account.
- Verified successful development-environment authentication.
- Verified the generated 50 MB tablespace datafile autoextends to 500 MB.
- Confirmed the container datafile persists beneath
  `/srv/oracle-ai-data/oracle/FREE/FREEPDB1` on the host.

## 2026-07-23 — Began Oracle SQLcl MCP Server 26.2

- Verified the official SQLcl image tag `26.2.0`.
- Recorded image digest `sha256:e0bddbcdfda9b2d83ce91af74c3f5ed71768ad29bbcd5523da837c4051056a54`.
- Verified SQLcl build `26.2.0.181.2110`.
- Confirmed the standard-input/standard-output MCP server starts successfully.
- Confirmed the upstream image defaults to root.
- Verified SQLcl and MCP run as numeric UID:GID `54321:54321`.
- Verified the persistent connection store is created beneath `~/.dbtools`.
- Selected SQLcl restriction level 4 and a dedicated read-only database user
  as the v0.7.0 defaults.

## 2026-07-23 — Verified Oracle SQLcl MCP Server 26.2 deployment

- Deployed SQLcl build `26.2.0.181.2110` using the pinned `26.2.0` image.
- Ran SQLcl and its MCP server as non-root UID:GID `54321:54321`.
- Created the dedicated `ORACLE_AI_MCP` database account with only
  `CREATE SESSION` and `ORACLE_AI_MCP_READ_ROLE`.
- Saved and verified the protected `oracle_ai_readonly` SQLcl connection.
- Completed an MCP protocol handshake using protocol version `2024-11-05`.
- Verified connection discovery, selection, read-only SQL execution, and
  disconnection through MCP.
- Confirmed the MCP session connected as `ORACLE_AI_MCP` to `FREEPDB1`.
- Confirmed restriction level 4 and no published network port.
- Confirmed the database account has no object-creation privilege or
  tablespace quota.
- Observed that SQLcl 26.2 did not create its documented
  `DBTOOLS$MCP_LOG` table, including during a controlled temporary-privilege
  test; all temporary privileges and quota were removed.

## 2026-07-24 — Began Private Agent Factory 26.4 milestone

- Selected production mode with the existing Oracle AI Database and Ollama.
- Installed KVM/libvirt without disrupting the verified Docker platform.
- Installed and updated an Oracle Linux 8.10 VM with 8 vCPU and 12 GiB RAM.
- Verified rootless Podman 4.9.4 with overlay storage and subordinate IDs.
- Added a dedicated 120 GiB sparse XFS build disk mounted at `/u01`.
- Reserved VM address `192.168.122.202` on the private libvirt network.
- Moved Ollama's published API from loopback to private bridge address
  `192.168.122.1`; Open WebUI remained healthy on its Docker network.
- Verified VM access to Database port 1521 and Ollama port 11434.
- Created and verified a 1.2 GiB cold database rollback backup.
- Converted the CDB and PDBs to `MAX_STRING_SIZE=EXTENDED` with `catcon.pl`.
- Recompiled database objects, revalidated APEX 26.1, and verified ORDS,
  APEX, SQLcl MCP, and 32,767-byte SQL string behavior.

## 2026-07-24 — Verified Private Agent Factory 26.4 deployment

- Installed Private Agent Factory 26.4 in the isolated Oracle Linux 8.10 VM.
- Verified the rootless Podman application container and loopback-only HTTPS
  endpoint.
- Verified 1,272 valid repository objects with no invalid objects.
- Configured local Ollama generation using `qwen3:4b-instruct`.
- Retained the bundled `multilingual-e5-base` embedding model.
- Verified Prompt Lab inference with the exact response `AGENT_FACTORY_OK`.
- Confirmed 100% GPU model allocation and 37 of 37 layers offloaded through
  ROCm to the Radeon 890M.
- Verified automatic startup and application availability after a VM reboot.
- Created and validated coordinated post-installation database and VM backups.

## 2026-07-24 — Verified Agent Factory and SQLcl MCP integration

- Adapted SQLcl MCP standard input/output to stateful Streamable HTTP with
  pinned Supergateway 3.4.3 and Node.js 22.
- Terminated TLS with pinned Nginx and a private CA.
- Published only `192.168.122.1:8182` to the isolated Agent Factory VM.
- Kept the unencrypted HTTP adapter on the private Docker backend network.
- Registered `oracle_sqlcl_readonly` in Agent Factory using Direct
  authentication.
- Allowed only six reviewed read-oriented MCP tools in the test flow.
- Verified an Agent Factory tool call connected through
  `oracle_ai_readonly` and returned `ORACLE_AI_MCP` in `FREEPDB1`.
- Observed a harmless Agent Factory 26.4 Direct-auth wallet lookup warning;
  tokenless MCP initialization and tool execution succeeded.

## 2026-07-26 — Began read-only sales data-agent milestone

- Confirmed the `ORACLE_AI` application schema contained no objects.
- Confirmed `ORACLE_AI_MCP` retained only `CREATE SESSION` and no quota.
- Added a deterministic sales dataset with four tables and two reporting
  views.
- Kept object ownership with `ORACLE_AI` and delegated only `SELECT` through
  `ORACLE_AI_MCP_READ_ROLE`.
- Added repeatable row-count, revenue, grant, and write-denial verification.

## 2026-07-26 — Verified read-only sales analysis agent

- Installed four deterministic `ORACLE_AI` sales tables and two reporting
  views with 8 customers, 8 products, 12 orders, and 22 order items.
- Synchronized six object-level `SELECT` grants through
  `ORACLE_AI_MCP_READ_ROLE`.
- Verified the MCP session remained `ORACLE_AI_MCP` in `FREEPDB1`.
- Verified recognized revenue of `12027` from only `COMPLETED` and `SHIPPED`
  orders.
- Verified natural-language analysis by sales channel, product, and customer
  region through the Agent Factory flow.
- Added explicit reporting-view schemas to prevent the local
  `qwen3:4b-instruct` model from inventing or mixing revenue columns.
- Verified the agent refused a DDL request without calling a tool.
- Independently verified database-enforced write denial for the MCP identity.
- Observed that Agent Factory 26.4 may retain the visible conversation when
  **New chat** is selected; reopening the flow provides the practical
  workaround.

## 2026-07-26 — Began agent operations and recovery milestone

- Verified Database, Ollama, SQLcl MCP HTTPS, the Agent Factory VM, and the
  Agent Factory application were healthy.
- Confirmed the private MCP certificate is valid through October 27, 2028.
- Measured 37 GiB of allocated active VM storage and 53 GiB of existing
  backups with 719 GiB free on the host filesystem.
- Confirmed the Agent Factory persistent application volume currently uses
  53 MiB and `/u01` has 105 GiB free.
- Chose permission-aware status reporting, coordinated cold backups,
  checksummed manifests, and report-only retention as the v0.11 foundation.

## 2026-07-26 — Verified coordinated agent-platform recovery set

- Corrected the Agent Factory application probe to use its VM-local HTTPS
  port `8080`.
- Quiesced Agent Factory, the SQLcl MCP bridge, ORDS, and Oracle Database in
  dependency order.
- Created a 38 GiB recovery set containing both offline VM disks, the libvirt
  definition, the cold Oracle data archive, and SQLcl MCP state.
- Verified every SHA-256 checksum, both QCOW2 structures, and both compressed
  archives.
- Restored all previously running services and confirmed Database, Ollama,
  SQLcl MCP HTTPS, the Agent Factory VM, and the Agent Factory application
  were healthy.
- Retained 681 GiB of free host storage after the backup.
## 2026-07-26 — Added scheduled observability foundation

- Added persistent systemd scheduling for daily health checks.
- Added an explicitly enabled weekly coordinated-backup timer.
- Separated unprivileged health execution from privileged backup execution.
- Added journald status inspection and optional webhook failure notifications.
- Kept retention reporting non-destructive pending an explicit policy.
- Documented the isolated restore-drill procedure required before release.

### 2026-07-26 — Observability and scheduled recovery verified

- Installed and exercised the daily systemd health service successfully.
- Completed a privileged coordinated recovery-set backup in 5 minutes 52 seconds.
- Independently verified every checksum and both QCOW2 images.
- Verified the 38 GB recovery set has restricted ownership and permissions.
- Confirmed that Oracle Database, ORDS, Ollama, SQLcl MCP, and Private Agent Factory recovered healthy after the backup.
- Enabled the persistent daily health and weekly coordinated-backup timers.
- First scheduled health run: 2026-07-27 06:16:24 UTC.
- First scheduled backup run: 2026-08-02 04:19:10 UTC.
## 2026-07-26 — Added operations-agent repository foundation

- Added the v0.13.0 operations-agent repository for health, check, and backup
  history.
- Integrated best-effort database recording into the existing observability
  wrapper without changing monitored command exit status.
- Added latest-run and daily-summary views, explicit retention, validation,
  status, smoke-test, installation, and removal workflows.
