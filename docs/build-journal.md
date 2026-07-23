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
