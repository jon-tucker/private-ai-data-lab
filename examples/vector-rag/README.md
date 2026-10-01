# Hybrid vector search and RAG example

This opt-in example uses six synthetic utility-handbook passages to show
Oracle AI Database hybrid vector search and a simple, inspectable RAG loop.
Oracle retrieves relevant passages; you provide those passages to the
existing local chat model in Open WebUI. No additional service is installed.

## Boundaries

- Only synthetic example text is installed. Do not add customer or voter data.
- Demo objects belong to `MCP_SOURCE_SCHEMA` (normally `ORACLE_AI`). The
  read-only `ORACLE_AI_MCP` identity is not granted new access or privileges.
- The ONNX model is supplied and licensed separately by the operator. It is
  neither downloaded nor committed by this repository. `*.onnx` is ignored.
- Commands below never start, stop, or rebuild the database or other services.
- Installation creates a table and a hybrid vector index. Removal drops only
  the example table/index; by default it retains the reusable embedding model.

## Requirements

- The existing Oracle AI Database container must already be running and
  healthy. The scripts will refuse to start it.
- The database release must support `CREATE HYBRID VECTOR INDEX`,
  `DBMS_HYBRID_VECTOR.SEARCH`, and in-database ONNX embedding models.
- The Oracle-documented `all_MiniLM_L12_v2.onnx` model, obtained under its
  published terms from the [Oracle vector-search SQL quick start](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/sql-quick-start-using-vector-embedding-model-uploaded-database.html).
  The model file is not part of this repository.
- A configured `.env` with the usual `ORACLE_DATABASE_CONTAINER`,
  `ORACLE_PDB`, and `MCP_SOURCE_SCHEMA` values.

The model used to create the hybrid index must be the same model used for
query embedding. The example uses model name `VECTOR_RAG_MINILM` in the
configured source schema. It refuses to overwrite an existing model with
that name. The Oracle-provided archive used here contains a 133,322,334-byte
ONNX file (about 127 MiB); loading it stores a copy in the database, and the
hybrid index adds its own storage. The loader removes only its temporary
container copy.

## Steps

1. Place the compatible ONNX file in a local, non-repository location. Then
   load it explicitly (replace the example path):

   ```bash
   ./scripts/vector-rag-load-model.sh /srv/oracle-ai-work/models/all_MiniLM_L12_v2.onnx
   ```

   The loader stages the file in a unique temporary directory inside the
   already-running database container, creates a temporary Oracle directory,
   loads the model into the configured application schema, and removes the
   temporary database directory and staged file. It does not print model
   contents or credentials.

2. Install the synthetic documents and hybrid index:

   ```bash
   ./scripts/vector-rag.sh install
   ```

3. Check the model, sample row count, and index, then run the retrieval
   queries:

   ```bash
   ./scripts/vector-rag.sh verify
   ./scripts/vector-rag.sh queries
   ```

4. For a grounded answer, copy the returned `DOC_ID`, title, and
   `CHUNK_TEXT` passages into a new Open WebUI prompt, for example:

   > Answer only from the source passages below. If they do not contain the
   > answer, say so. Cite the `DOC_ID` for each factual claim.
   >
   > Question: What should I do if I smell gas near a stove?
   >
   > Source passages: [paste the returned passages here]

5. When finished, remove the sample table and its index:

   ```bash
   ./scripts/vector-rag.sh uninstall --confirm
   ```

   This intentionally leaves `VECTOR_RAG_MINILM` installed. Do not remove it
   if another object uses it. If it is unused and you want to remove it, run
   the separately guarded SQL file as SYSDBA:

   ```bash
   ./scripts/vector-rag.sh uninstall-model --confirm
   ```

   The model-removal script refuses while the demo table exists.

## Reproducible checks

The query set covers storm restoration, overnight EV charging rates, and a
gas-leak safety procedure. Each query asks Oracle to combine vector similarity
with text search and return up to three ranked passages. Verify that the
results include the corresponding synthetic source IDs:

| Query topic | Expected source ID |
| --- | --- |
| Storm restoration priorities | `RESTORE-001` |
| Lower-cost overnight EV charging | `EV-RATE-002` |
| Rotten-egg odor near a stove | `GAS-SAFETY-003` |

Hybrid retrieval is relevance-ranked, so the matching source need not be first.
If a source is absent, first verify the returned passages and model/index
status; rankings can vary with model and database release.

## Oracle references

- [Create hybrid vector indexes](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/create-hybrid-vector-index.html)
- [Search with a hybrid vector index](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/search.html)
- [Load an ONNX embedding model](https://docs.oracle.com/en/database/oracle/oracle-database/26/arpls/dbms_vector1.html)
- [Oracle AI Database vector-search SQL quick start](https://docs.oracle.com/en/database/oracle/oracle-database/26/vecse/sql-quick-start-using-vector-embedding-model-uploaded-database.html)
