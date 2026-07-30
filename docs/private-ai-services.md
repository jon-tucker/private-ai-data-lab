# Oracle Private AI Services alignment

Oracle Private AI Services Container complements the platform by offloading
Oracle AI Database vector work to a private, OpenAI-compatible service. It does
not replace Private Agent Factory, Ollama, LiteLLM, SQLcl MCP, or Open WebUI.

This milestone defines the supported deployment boundary before any licensed
container image is downloaded or started.

## Services

Oracle currently documents two services:

- Vector Embedding Service for stateless embedding generation outside the
  database.
- Vector Index Service for GPU-assisted HNSW index creation.

The initial platform integration targets only the Vector Embedding Service.
The Vector Index Service is deferred because Oracle currently requires an
NVIDIA GPU with compute capability 7.5 or later, while the reference platform
uses an AMD Radeon 890M.

## Deployment boundary

The Private AI Services target must be separate from the existing
`oracle-ai` database host and meet Oracle's documented prerequisites:

- Oracle Linux 8.6 or later, Oracle Linux 9, or Oracle Linux 10
- x86-64 architecture
- Podman 3.4.4 or later
- at least 16 GB of free memory for the embedding service
- at least 22 GB of free storage
- OpenSSL with TLS 1.3 support

The existing Ubuntu host is intentionally not a deployment target. It runs
Oracle AI Database and the rest of the stable v1.0 platform, and it does not
match Oracle's documented host operating systems.

## Component decisions

| Component | Decision | Role |
| --- | --- | --- |
| Oracle AI Database Free 26ai | Keep | Database, vector store, and similarity search |
| Private Agent Factory 26.4 | Keep | Governed agent and workflow platform |
| SQLcl MCP 26.2 | Keep | Least-privilege database tool integration |
| Ollama | Keep | Private generative-model runtime |
| LiteLLM HTTPS gateway | Keep | Authenticated model abstraction for Agent Factory |
| Open WebUI | Keep | Independent local model interface |
| Private AI Vector Embedding Service | Add on a separate target | Oracle-native embedding offload |
| Private AI Vector Index Service | Defer | Requires supported NVIDIA hardware |

## Staged implementation

1. Provision a separate supported Oracle Linux x86-64 target.
2. Run `scripts/private-ai-services-assess-host.sh` on that target.
3. Sign in to Oracle Container Registry, accept the applicable license, and
   create an authentication token outside this repository.
4. Pull the Oracle-documented pinned embedding-service image with Podman.
5. Use the installation scripts supplied in the image to configure TLS 1.3,
   API-key authentication, and the encrypted keystore.
6. Restrict network access to the Oracle AI Database host.
7. Validate the health and model-list endpoints.
8. Configure an Oracle Database web credential and ACL for the private
   endpoint.
9. Verify `DBMS_VECTOR.UTL_TO_EMBEDDING` and
   `DBMS_VECTOR.UTL_TO_EMBEDDINGS`.
10. Add the service to platform health, backup documentation, and release
    validation.

## Security and source-control rules

- Oracle Container Registry credentials and authentication tokens remain
  outside Git.
- TLS private keys, API keys, keystores, and generated configuration remain
  under the platform secrets boundary.
- Oracle-licensed images and extracted installation media are not included in
  source archives.
- The service is not exposed directly to the LAN or internet.
- Deployment must retain a documented removal and database fallback path.

## Official references

- Oracle Private AI Services Container User's Guide:
  <https://docs.oracle.com/en/database/oracle/oracle-database/26/prvai/>
- Installation prerequisites:
  <https://docs.oracle.com/en/database/oracle/oracle-database/26/prvai/install-private-ai-services-container.html>
- Product overview:
  <https://www.oracle.com/database/private_ai_services_container/>
