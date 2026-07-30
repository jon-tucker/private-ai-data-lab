# Oracle Private AI Services Container

This directory records the integration contract for Oracle Private AI
Services Container. Runtime Compose files are intentionally absent.

Oracle distributes the licensed container through Oracle Container Registry
and supplies installation scripts within the image. Follow
`docs/private-ai-services.md` and Oracle's current documentation rather than
constructing an unsupported replacement deployment.

Run the read-only assessment on the proposed Oracle Linux target:

```bash
./scripts/private-ai-services-assess-host.sh
```

Do not run the service on the existing Ubuntu database host.
