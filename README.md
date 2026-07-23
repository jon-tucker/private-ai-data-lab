# Oracle AI Data Platform

*Production-inspired Oracle AI for everyone.*

Oracle AI Data Platform is a reproducible, production-inspired environment for learning, testing, and demonstrating Oracle AI technologies alongside modern open-source AI tooling.

Created by Jon Tucker with ChatGPT.

> [!IMPORTANT]
> Version `0.6.0` adds the Oracle APEX 26.1 deployment foundation. APEX is
> installed only after its preflight and source package are reviewed.

## Project goals

- Recreate the platform from source-controlled configuration and automation.
- Separate source code, persistent data, and secrets.
- Favor pinned versions, health checks, and documented operational procedures.
- Provide practical examples for Oracle AI Database, vector search, MCP, RAG, and agents.
- Keep local credentials and generated data out of Git.

## Planned platform

| Area | Component | Status |
| --- | --- | --- |
| Foundation | Repository, documentation, configuration conventions | Complete in v0.1.0 |
| Database | Oracle AI Database 26ai Free | Available in v0.2.0 |
| Oracle services | ORDS | Available in v0.5.0 |
| Oracle services | Oracle APEX 26.1 | Foundation in v0.6.0 |
| Tool integration | Oracle Database MCP Server | Planned |
| Agents | Oracle AI Database Private Agent Factory | Planned |
| Local AI | Ollama with verified Radeon 890M ROCm acceleration | Available in v0.3.0 |
| Local AI UI | Open WebUI connected to Ollama | Available in v0.4.0 |
| Model gateway | LiteLLM | Planned |
| Edge and operations | Reverse proxy, logging, backups, monitoring | Planned |

## Host layout

The platform keeps code, state, and credentials separate:

```text
/srv/
├── oracle-ai/          # Git working tree
├── oracle-ai-data/     # Persistent databases, models, logs, and backups
└── oracle-ai-secrets/  # Local credentials and private configuration (mode 0700)
```

The repository name is `oracle-ai-data-platform`; its deployment path is `/srv/oracle-ai`.

## Repository layout

```text
.
├── compose.yaml
├── config/
├── docs/
│   ├── adr/
│   ├── architecture.md
│   └── build-journal.md
├── examples/
├── scripts/
└── stacks/
    ├── agent-factory/
    ├── apex/
    ├── dozzle/
    ├── litellm/
    ├── mcp/
    ├── nginx/
    ├── ollama/
    ├── open-webui/
    ├── oracle-db/
    ├── ords/
    ├── portainer/
    └── watchtower/
```

## Requirements

- Linux host with Docker Engine and Docker Compose
- x86-64 processor with virtualization support
- At least 32 GB RAM for the initial lab profile
- At least 250 GB free storage; more is recommended for models and database data
- Git and SSH access for repository operations

The initial reference host is a Minisforum AI X1 Pro with an AMD Ryzen AI 9 HX 370, 32 GB DDR5 memory, 1 TB NVMe storage, and Ubuntu Server 26.04 LTS.

## Quick start

Create the local environment file and database password:

```bash
cp .env.example .env
./scripts/oracle-create-secret.sh
./scripts/oracle-prepare-host.sh
```

Validate and start Oracle AI Database:

```bash
./scripts/validate.sh
./scripts/oracle-start.sh
```

Follow initialization with `./scripts/oracle-logs.sh`. First startup can take several minutes. The database is ready when the container becomes healthy.

Prepare and start Ollama with the accelerator selected in `.env`:

```bash
./scripts/ollama-configure-env.sh
./scripts/ollama-prepare-host.sh
./scripts/ollama-validate.sh
./scripts/ollama-start.sh
./scripts/ollama-pull-model.sh
```

Create the stable Open WebUI secret, prepare its persistent data directory, and start the UI:

```bash
./scripts/open-webui-configure-env.sh
./scripts/open-webui-create-secret.sh
./scripts/open-webui-prepare-host.sh
./scripts/open-webui-validate.sh
./scripts/open-webui-start.sh
```

Open `http://192.168.0.209:3000` from the trusted LAN. The first account becomes administrator; disable additional registration immediately afterward.

Prepare the verified APEX 26.1 software and review the preflight before
installation:

```bash
./scripts/apex-configure-env.sh
./scripts/apex-prepare-host.sh
./scripts/apex-validate.sh
./scripts/apex-preflight.sh
```

See `docs/apex.md` before running the state-changing APEX installation.

Connection defaults:

```text
Host:     oracle-ai or 192.168.0.209
Port:     1521
CDB:      FREE
PDB:      FREEPDB1
Users:    SYS, SYSTEM, PDBADMIN
```

The generated `.env` and password file are ignored by Git. Do not place real secrets in `.env.example`.

## Documentation

- [Architecture](docs/architecture.md)
- [Build journal](docs/build-journal.md)
- [Oracle AI Database stack](docs/oracle-database.md)
- [Ollama stack](docs/ollama.md)
- [Open WebUI stack](docs/open-webui.md)
- [Oracle REST Data Services](docs/ords.md)
- [Oracle APEX](docs/apex.md)
- [ADR 0001: Project structure](docs/adr/0001-project-structure.md)
- [ADR 0002: Database password handling](docs/adr/0002-database-password-handling.md)
- [ADR 0003: Ollama acceleration profiles](docs/adr/0003-ollama-acceleration-profiles.md)
- [ADR 0004: Open WebUI identity and secret persistence](docs/adr/0004-open-webui-identity-and-secret-persistence.md)
- [ADR 0005: Separate ORDS installation from runtime](docs/adr/0005-separate-ords-installation-from-runtime.md)
- [ADR 0006: Separate APEX software, state, and installation](docs/adr/0006-separate-apex-software-state-and-installation.md)
- [Changelog](CHANGELOG.md)

## Security

- Never commit passwords, API keys, Oracle wallets, private keys, or certificates.
- Keep runtime secrets under `/srv/oracle-ai-secrets` with restrictive permissions.
- Keep persistent state under `/srv/oracle-ai-data` and back it up independently.
- Review every example value before exposing a service outside the trusted LAN.

## License

Project-authored source and documentation are licensed under the [MIT License](LICENSE). Oracle software, images, and other third-party components remain subject to their respective licenses and terms.


## ORDS milestone

Oracle REST Data Services 26.2.0 is the v0.5.0 milestone. Its one-time installer changes
database metadata explicitly, while the long-running service starts without a SYS secret.
See `docs/ords.md` for deployment and operating instructions.
