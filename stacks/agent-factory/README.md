# Agent Factory deployment boundary

Oracle AI Database Private Agent Factory 26.4 is not managed by the host
Docker Compose project. Oracle's licensed kit manages rootless Podman
containers inside the dedicated Oracle Linux 8.10 KVM guest.

See `docs/agent-factory.md`. No proprietary archives, extracted artifacts,
credentials, generated images, or VM disks belong in this directory.
