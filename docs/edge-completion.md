# Edge completion

Version 0.19.0 completes the private Agent Factory browser edge with a stable
local hostname, standard HTTPS publication, and a managed certificate
lifecycle.

## Supported endpoint

`https://oracle-ai.local/agentFactory/`

The Ubuntu host advertises `oracle-ai.local` through mDNS. The edge remains
bound to the host LAN address, while its upstream Agent Factory endpoint
remains restricted to the private libvirt bridge.

## Validation

Run:

```bash
./scripts/edge-completion-validate.sh
```

The validation checks the standard port, local hostname resolution,
certificate identity, retired legacy port, edge configuration, and a trusted
HTTP response.

## Certificate renewal

Stage and inspect a replacement:

```bash
./scripts/agent-factory-edge-renew-tls.sh
```

Apply the reviewed replacement:

```bash
./scripts/agent-factory-edge-renew-tls.sh --apply
```

Application archives the current edge certificate material before replacing
it and verifies the recreated endpoint.
