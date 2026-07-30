# ADR 0022: Separate Private AI Services offload

## Status

Accepted

## Context

Oracle Private AI Services Container provides vector embedding generation and
GPU-assisted vector index creation outside Oracle AI Database. The stable
reference host already runs Oracle AI Database, Private Agent Factory, local
generative models, model routing, MCP, and operational services on Ubuntu.

Oracle documents Oracle Linux 8.6+, 9, or 10 as supported host operating
systems, at least 16 GB of free memory for embedding generation, and a
separate machine close to the database. The vector index service additionally
requires a supported NVIDIA GPU. The reference host uses an AMD Radeon 890M.

## Decision

Private AI Services is a complementary Oracle Database offload tier. It does
not replace Ollama, LiteLLM, Open WebUI, Private Agent Factory, or SQLcl MCP.

The Vector Embedding Service will be integrated only on a separate supported
Oracle Linux x86-64 target that passes the repository's host assessment. The
current Ubuntu database host and the existing Agent Factory VM are excluded as
deployment targets.

The Vector Index Service is deferred until supported NVIDIA infrastructure is
available. No Compose definition will imitate Oracle's deployment process;
the project will use the pinned Oracle Container Registry image and the
installation scripts supplied by Oracle.

## Consequences

- The stable v1.0 runtime remains unchanged during the alignment milestone.
- Additional supported compute is required before runtime deployment.
- Current generative-model and MCP paths remain operational and supported by
  this project.
- Oracle registry credentials, license acceptance, images, keys, and
  generated installation state remain outside Git.
- AMD ROCm acceleration remains useful for Ollama but does not satisfy the
  Private AI Vector Index Service requirement.
- Integration acceptance will require TLS, API-key, REST, and
  `DBMS_VECTOR` verification.
