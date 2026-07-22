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

## Lessons carried forward

- Preserve a strict separation between code, state, and secrets.
- Make installation and operational steps repeatable before calling a component complete.
- Pin deployable component versions once stacks are introduced.
- Validate each milestone before adding dependent services.
- Avoid undocumented firmware changes on a stable host unless there is a demonstrated need and a verified vendor procedure.
