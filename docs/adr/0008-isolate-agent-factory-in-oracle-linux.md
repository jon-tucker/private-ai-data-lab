# ADR 0008: Isolate Agent Factory in Oracle Linux

- Status: Accepted
- Date: 2026-07-24

## Context

Private Agent Factory 26.4 supports Oracle Linux 8 and requires rootless Podman.
The platform host runs Ubuntu 26.04 with Docker and owns the Radeon 890M GPU.
Replacing the stable host operating system would disrupt verified Database,
ORDS, APEX, Ollama, Open WebUI, and MCP services.

## Decision

Run Agent Factory in an Oracle Linux 8.10 KVM guest attached to libvirt's
private NAT network. Keep Oracle Database and GPU-accelerated Ollama on the
Ubuntu host. Publish Ollama only on the private bridge address.

Use a separate sparse build disk mounted at `/u01`; keep the licensed kit,
temporary build files, Podman artifacts, and backups outside Git. Run all
Agent Factory installation and lifecycle commands as the non-root `jon` user.

## Consequences

- The supported Oracle Linux and rootless-Podman boundary is reproducible.
- Existing Docker and GPU workloads remain unchanged.
- Database and Ollama traffic crosses only the private bridge.
- The VM and its two disks require independent backup and lifecycle handling.
- Browser access initially requires SSH tunneling.
- Oracle's documented repository grants include powerful account-management
  and cross-schema privileges. They are isolated to a dedicated PDB account,
  created explicitly, reviewed, and documented.
