# ADR 0004: Open WebUI identity and secret persistence

- Status: Accepted
- Date: 2026-07-22

## Context

Open WebUI stores user identities, chats, configuration, and future tool credentials. Its secret key signs authentication tokens and encrypts sensitive values. Allowing a container recreation to generate a different key would invalidate sessions and could make encrypted OAuth or MCP data unreadable.

Passing the key directly through Compose environment metadata would make it visible through container inspection. Keeping only an automatically generated key inside an ephemeral container would make recovery dependent on container lifecycle behavior.

## Decision

Generate a random 256-bit key once under `/srv/oracle-ai-secrets/open-webui-secret-key`, restrict it to mode `0600`, and mount it read-only at `/app/backend/.webui_secret_key`.

Persist all Open WebUI application state separately under `/srv/oracle-ai-data/open-webui`. Back up the state directory and secret key as one recovery set.

Permit registration only for initial administrator creation on the trusted LAN. The administrator must disable additional registration immediately after first-run setup.

## Consequences

- Container recreation preserves sessions and encrypted values when both state and secret are retained.
- The secret does not appear in Git, `.env`, or normal container environment inspection.
- Losing the key can invalidate sessions and encrypted integrations even when the application database survives.
- A fresh deployment requires an explicit secret-creation step before startup.
