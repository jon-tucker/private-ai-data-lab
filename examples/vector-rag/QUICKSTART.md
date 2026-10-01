# Try the hybrid vector-search and RAG demo

This guided demo uses six synthetic utility-handbook passages. Oracle AI
Database retrieves relevant source passages with hybrid vector and text
search; you paste those passages into Open WebUI to ask a locally hosted chat
model for a grounded answer. It adds no services and does not use real customer
or voter data.

This quick start is for an already configured lab host with the project
repository checked out. For first-time host setup, start with the root
[README](../../README.md). The demo commands below do not start or stop
services; service-start commands are shown separately and only as needed.

## 1. Check the required services

Run these from the repository directory. The database must already be healthy
before running the model loader or database scripts:

```bash
./scripts/oracle-status.sh
```

If Oracle AI Database is stopped and you intend to start it, start only that
service and wait for it to report healthy:

```bash
./scripts/oracle-start.sh
./scripts/oracle-status.sh
```

Open WebUI is used for the final chat step. Check it with:

```bash
./scripts/open-webui-status.sh
```

If it is stopped, this command starts the configured Ollama and Open WebUI
services and waits for them to become healthy:

```bash
./scripts/open-webui-start.sh
```

The configured chat model should be available in Ollama. If this is a new
setup, follow the [Ollama guide](../../docs/ollama.md) to select and download
the model; that download can be large and is not performed by this demo.

## 2. Obtain and load the embedding model

Obtain Oracle's documented `all_MiniLM_L12_v2.onnx` model under its published
terms, following the [Oracle vector-search SQL quick start](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/sql-quick-start-using-vector-embedding-model-uploaded-database.html).
Keep the file outside the repository. The model archive used by the full
example contains a roughly 127 MiB model; loading it stores a copy in the
database. The hybrid index created in the next step also consumes database
storage.

Load it by supplying its actual local path:

```bash
./scripts/vector-rag-load-model.sh /path/to/all_MiniLM_L12_v2.onnx
```

The loader operates on the already-running database, creates the
`VECTOR_RAG_MINILM` model in the configured source schema, and cleans up its
temporary staged file and temporary Oracle directory. It refuses to overwrite
an existing model with that name.

## 3. Install and verify the synthetic demo

```bash
./scripts/vector-rag.sh install
./scripts/vector-rag.sh verify
```

Installation creates `VECTOR_RAG_DOCUMENTS` and its hybrid vector index in
`MCP_SOURCE_SCHEMA` (normally `ORACLE_AI`). It inserts exactly six synthetic
documents. It does not grant new access to the read-only `ORACLE_AI_MCP`
identity. The installer refuses to replace an existing demo table or index.

## 4. Run the reproducible retrieval queries

```bash
./scripts/vector-rag.sh queries
```

The results include ranked source passages. Confirm these IDs appear in the
results; hybrid ranking may put a matching source below the first result:

| Ask about | Expected source ID |
| --- | --- |
| Storm restoration priorities | `RESTORE-001` |
| Lower-cost overnight EV charging | `EV-RATE-002` |
| Rotten-egg odor near a stove | `GAS-SAFETY-003` |

## 5. Try a grounded answer in Open WebUI

Open the existing Open WebUI address shown by `./scripts/open-webui-start.sh`.
Copy one or more matching `DOC_ID`, title, and `CHUNK_TEXT` results from the
query output into a new chat with this prompt, replacing the bracketed text:

> Answer only from the source passages below. If they do not contain the
> answer, say so. Cite the `DOC_ID` for each factual claim.
>
> Question: What should I do if I smell gas near a stove?
>
> Source passages: [paste the returned passages here]

The retrieval step is performed by Oracle AI Database. Copying passages into
Open WebUI is intentionally manual and inspectable; the example does not
silently connect the database to a chat agent.

## 6. Remove the demo data when finished

This removes only the example table and its hybrid index. It leaves the
embedding model installed for reuse:

```bash
./scripts/vector-rag.sh uninstall --confirm
```

If you also want to remove the model, first make sure no other object uses it;
model removal is a separate, explicit action and is blocked while the demo
table exists:

```bash
./scripts/vector-rag.sh uninstall-model --confirm
```

See the full [example guide](README.md) for the object boundaries, query SQL,
reproducibility notes, and Oracle references.
