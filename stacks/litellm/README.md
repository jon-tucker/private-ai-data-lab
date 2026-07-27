# LiteLLM model gateway

This stack exposes a private OpenAI-compatible endpoint on the libvirt bridge.
It maps the stable `local-qwen3-4b-instruct` alias to Ollama and requires a
locally stored master key for all model requests.

Run the `model-gateway-*` scripts from the repository root. Direct Ollama
access remains available as a rollback path during the v0.15.0 transition.
