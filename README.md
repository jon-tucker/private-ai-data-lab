# Oracle AI Data Platform

*Production-inspired Oracle AI for everyone.*

Oracle AI Data Platform is a reproducible, production-inspired environment for learning, testing, and demonstrating Oracle AI technologies alongside modern open-source AI tooling.

Created by Jon Tucker with ChatGPT.

> [!IMPORTANT]
> Version `0.1.0` establishes the repository foundation only. It does not deploy containers or install platform services.

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
| Database | Oracle AI Database 26ai Free | Planned |
| Oracle services | ORDS and APEX | Planned |
| Tool integration | Oracle Database MCP Server | Planned |
| Agents | Oracle AI Database Private Agent Factory | Planned |
| Local AI | Ollama and Open WebUI | Planned |
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

Deployment automation will be added in later releases. For v0.1.0, validate the foundation without starting services:

```bash
cp .env.example .env
docker compose config
```

The generated `.env` file is ignored by Git. Do not place real secrets in `.env.example`.

## Documentation

- [Architecture](docs/architecture.md)
- [Build journal](docs/build-journal.md)
- [ADR 0001: Project structure](docs/adr/0001-project-structure.md)
- [Changelog](CHANGELOG.md)

## Security

- Never commit passwords, API keys, Oracle wallets, private keys, or certificates.
- Keep runtime secrets under `/srv/oracle-ai-secrets` with restrictive permissions.
- Keep persistent state under `/srv/oracle-ai-data` and back it up independently.
- Review every example value before exposing a service outside the trusted LAN.

## License

Project-authored source and documentation are licensed under the [MIT License](LICENSE). Oracle software, images, and other third-party components remain subject to their respective licenses and terms.

