# Open WebUI stack

Open WebUI provides the authenticated browser interface for the platform's local models. It connects to Ollama at `http://ollama:11434` on the private backend network and publishes only the web interface on host port `3000`.

Persistent application state is bind-mounted from `/srv/oracle-ai-data/open-webui`. The stable signing and encryption key is mounted read-only from `/srv/oracle-ai-secrets/open-webui-secret-key`; it must be backed up with the data because changing it invalidates sessions and can make encrypted MCP credentials unreadable.

The first registered account becomes the administrator. Complete first-run registration from the trusted LAN and then disable further registration in **Admin Panel → Settings → General**.
