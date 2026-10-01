# ADR 0026: Demonstrate hybrid vector retrieval without another service

- Status: Accepted
- Date: 2026-10-01

## Context

The lab identifies vector search and retrieval-augmented generation (RAG) as
goals but has not had a small, reproducible end-to-end example. The database
already provides vector search, and the lab has a local chat model. A useful
demonstration should show retrieval and source grounding without adding a
second application stack or placing real user data in the sample.

## Decision

Add an opt-in walkthrough using synthetic utility-handbook passages, an
operator-supplied ONNX embedding model, an Oracle hybrid vector index, and
three inspectable search prompts. Keep sample objects in the existing
`ORACLE_AI` schema. Return source identifiers and matching passages so the
operator can paste those sources into the existing local chat UI. Do not
connect the sample to the production-style read-only MCP account or create a
new service.

The model binary is not redistributed or committed. The sample's load step
stages the user-supplied model temporarily in the running database container,
uses a temporary Oracle directory and only the privileges needed for model
loading, then removes the directory and staged file. Loading, schema creation,
queries, and removal are explicit actions; none are part of platform startup.

## Consequences

- The example is small, auditable, and does not need an additional container.
- Search quality depends on the chosen model and Oracle AI Database release;
  expected source IDs are verification targets, not a promise about ranking.
- The sample requires an Oracle AI Database release that supports hybrid
  vector indexes and a compatible in-database ONNX model.
- Removing the demo table also removes its hybrid index; the loaded model is
  left in place unless an operator explicitly removes it after checking for
  other users.
