# Oracle AI Database Private Agent Factory 26.4

## Scope

Version 0.8.0 prepares a production-mode Agent Factory deployment without
committing Oracle's licensed kit, generated images, credentials, or VM disks.

## Verified architecture

| Item | Value |
| --- | --- |
| Guest | Oracle Linux Server 8.10, UEK |
| Virtualization | KVM/libvirt on the Ubuntu platform host |
| VM resources | 8 vCPU, 12 GiB RAM, 6 GiB swap |
| VM address | `192.168.122.202` |
| Runtime | Podman 4.9.4, rootless, overlay |
| System disk | 120 GiB sparse qcow2 |
| Build disk | 120 GiB sparse qcow2, XFS at `/u01` |
| Database | `192.168.122.1:1521/FREEPDB1` |
| Ollama | `http://192.168.122.1:11434` |
| Agent Factory | 26.4.0 production mode, port 8080 |

The local `.env` changes `OLLAMA_HOST_BIND` from the repository's secure
loopback default to `192.168.122.1`. This is a host-specific override and
must not be copied blindly to systems without the matching private bridge.

## Database prerequisite

Agent Factory production mode requires `MAX_STRING_SIZE=EXTENDED`. This change
is one-way. Before conversion, the platform created and verified:

```text
/srv/oracle-ai-data/backups/oracle/
pre-agent-factory-extended-20260724-191546.tar.gz
SHA-256 560d27f6986d029ee75b3054ee38f73d5a650031cbb55108fbc38ca2f71e77d3
```

Oracle's multitenant procedure was used: set the SPFILE value, restart in
upgrade mode, run `utl32k.sql` through `catcon.pl` in the root and PDBs,
restart normally, and run `utlrp.sql` through `catcon.pl`. Validation confirmed
`EXTENDED`, a 32,767-byte SQL `VARCHAR2`, valid APEX, and healthy ORDS and MCP.

Restoring `STANDARD` requires stopping the database and restoring the cold
backup. Do not attempt to alter the parameter back.

## Prepare configuration

```bash
./scripts/agent-factory-configure-env.sh
./scripts/agent-factory-configure-private-ollama.sh
./scripts/ollama-stop.sh
./scripts/ollama-start.sh
./scripts/ollama-smoke-test.sh
./scripts/agent-factory-create-secret.sh
./scripts/agent-factory-vm-status.sh
./scripts/agent-factory-preflight.sh
```

Create the database accounts only after reviewing the grants:

```bash
./scripts/agent-factory-create-database-users.sh
./scripts/agent-factory-database-status.sh
```

Oracle 26.4 requires a primary repository owner and an
`AAI_RO_` companion. The upstream non-Autonomous grant list includes
`CREATE USER`, `DROP USER`, `CREATE ANY INDEX`, `INSERT ANY TABLE`, and
`CREATE SESSION WITH ADMIN OPTION`. These are powerful privileges. They are
granted only to the dedicated `AGENT_FACTORY` identity in `FREEPDB1`.

## Stage the licensed kit

Download `oracle_agent_factory_X64_26.4.0.tar.gz` from Oracle after accepting
its license. Copy it to the guest:

```bash
scp -o ProxyJump=oracle-ai \
  oracle_agent_factory_X64_26.4.0.tar.gz \
  <vm-user>@192.168.122.202:/u01/agent-factory/downloads/
```

Create a new staging directory for every installation or upgrade:

```bash
mkdir -m 0700 /u01/agent-factory/staging/26.4.0
cd /u01/agent-factory/staging/26.4.0
tar -xzf /u01/agent-factory/downloads/oracle_agent_factory_X64_26.4.0.tar.gz
```

Review the extracted top-level files and installer before execution. Never
commit the archive or extracted application artifacts.

## Installer choices

Run `interactive_install.sh` as `jon`, never root. Select:

- no corporate proxy, unless the environment changes;
- Standard Oracle Linux machine;
- Linux user `jon`;
- alternate temporary directory `/u01/agent-factory/tmp`;
- manual database setup;
- production mode;
- database host `192.168.122.1`, port `1521`, service `FREEPDB1`;
- repository user `AGENT_FACTORY`;
- Ollama endpoint `http://192.168.122.1:11434`.

Do not paste credentials into shell command arguments or store them in the
repository. The database password remains in
`/srv/oracle-ai-secrets/agent-factory-db-password` on the Ubuntu host.

## Browser access

Until a TLS reverse proxy is implemented, tunnel the VM endpoint:

```bash
ssh -J oracle-ai \
  -L 8443:127.0.0.1:8080 \
  <vm-user>@192.168.122.202
```

Open `https://127.0.0.1:8443/agentFactory/`. The initial certificate is
self-signed; verify its fingerprint before accepting it.

## Lifecycle

VM lifecycle from the repository host:

```bash
./scripts/agent-factory-vm-start.sh
./scripts/agent-factory-vm-status.sh
./scripts/agent-factory-vm-stop.sh
```

Application lifecycle commands such as `make start`, `make diagnose`, and
`make uninstall` must run inside the version-specific staging directory.

## Verified deployment

The v0.8.0 production deployment was verified with:

- Oracle AI Database Private Agent Factory version `26.4.0`.
- Licensed archive `oracle_agent_factory_X64_26.4.0.tar.gz` with SHA-256
  `68efe89bd77946e4d9020415514a8e9efbbf878e50091d5b2e12ae7b6e881ef0`.
- An Oracle Linux 8.10 KVM guest with 8 virtual CPUs and 12 GiB of memory.
- Rootless Podman and a dedicated 120 GiB XFS build filesystem mounted at
  `/u01`.
- Application image `localhost/applied-ai-label:26.4.0.0.0`.
- Application container `oracle-applied-ai-label` bound only to
  `127.0.0.1:8080` inside the VM.
- Database users `AGENT_FACTORY` and `AAI_RO_AGENT_FACTORY` open in
  `FREEPDB1`.
- 1,272 valid `AGENT_FACTORY` objects, no invalid objects, and approximately
  82.88 MiB of repository segments.
- One saved generative-model configuration using Ollama model
  `qwen3:4b-instruct`.
- One saved embedding configuration using the bundled
  `multilingual-e5-base` model.
- A successful Prompt Lab response of exactly `AGENT_FACTORY_OK`.
- Ollama reporting 100% GPU allocation and all 37 model layers offloaded
  through ROCm to the Radeon 890M.
- Successful VM reboot persistence, automatic application-container startup,
  and an HTTPS status of 200 after reboot.

The verified Ollama endpoint is `http://192.168.122.1` on port `11434`.
The installer can visually display the default port without submitting a
value, so the port must be explicitly entered before testing the connection.

The post-installation backup set was created with stamp
`20260725-012421`:

- Database archive:
  `/srv/oracle-ai-data/backups/oracle/post-agent-factory-26.4-20260725-012421.tar.gz`
- VM backup directory:
  `/srv/oracle-ai-data/backups/vms/post-agent-factory-26.4-20260725-012421`

Both VM disk images passed `qemu-img check`.

## References

- [Agent Factory 26.4 deployment prerequisites](https://docs.oracle.com/en/database/oracle/agent-factory/26.4/paias/prerequisites.html)
- [Installation on Linux](https://docs.oracle.com/en/database/oracle/agent-factory/26.4/paias/setup-linux.html)
- [Database preparation and grants](https://docs.oracle.com/en/database/oracle/agent-factory/26.4/paias/database-setup.html)
- [Download the installation kit](https://docs.oracle.com/en/database/oracle/agent-factory/26.4/paias/download-kit.html)
- [Oracle Database `MAX_STRING_SIZE`](https://docs.oracle.com/en/database/oracle/oracle-database/26/refrn/MAX_STRING_SIZE.html)
