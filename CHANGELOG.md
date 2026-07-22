# Changelog

All notable changes to this project will be documented in this file.

The project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned

- Add Ollama and Open WebUI stacks.
- Add ORDS, APEX, MCP Server, and Private Agent Factory stacks.

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
