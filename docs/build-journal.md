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


## Lessons carried forward

- Preserve a strict separation between code, state, and secrets.
- Make installation and operational steps repeatable before calling a component complete.
- Pin deployable component versions once stacks are introduced.
- Validate each milestone before adding dependent services.
- Avoid undocumented firmware changes on a stable host unless there is a demonstrated need and a verified vendor procedure.
