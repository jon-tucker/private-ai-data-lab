# LiveStack private HTTPS edge

The LiveStack edge provides trusted-LAN browser access without changing the
application's required loopback-only host publication.

## Boundary

- LiveStack remains on `127.0.0.1:8505`.
- Nginx reaches `livestack:3001` on the private Docker backend network.
- HTTPS is bound to one configured LAN address on port 8506.
- Nginx permits only loopback and `LIVESTACK_EDGE_ALLOWED_CIDR`.
- The edge uses a dedicated CA and does not share Agent Factory keys.

## Configure and start

Set the actual LAN values in `.env`; never commit them to the repository:

```text
LIVESTACK_EDGE_HOST_BIND=<platform-lan-ip>
LIVESTACK_EDGE_ALLOWED_CIDR=<trusted-lan-cidr>
LIVESTACK_EDGE_SERVER_NAME=oracle-ai.local
LIVESTACK_EDGE_PORT=8506
```

Then run:

```bash
./scripts/livestack-edge-configure-env.sh
./scripts/livestack-edge-create-tls.sh
./scripts/livestack-edge-prepare-host.sh
./scripts/livestack-edge-validate.sh
./scripts/livestack-edge-start.sh
./scripts/livestack-edge-status.sh
./scripts/livestack-edge-smoke-test.sh
```

Permit port 8506 only from the trusted LAN in the host firewall. Do not create
an internet-router port forward. Copy `ca.crt` to each authorized client and
add it to that client's trust store. Browse to:

```text
https://oracle-ai.local:8506/
```

The IP URL is also valid when the certificate was created with that IP:

```text
https://<platform-lan-ip>:8506/
```

## Certificate renewal

Stage and inspect a replacement without changing the active service:

```bash
./scripts/livestack-edge-renew-tls.sh
```

Apply the staged replacement, archive the previous certificate, recreate the
edge, and run its smoke test:

```bash
./scripts/livestack-edge-renew-tls.sh --apply
```

## Stop and rollback

Stop only the edge with `./scripts/livestack-edge-stop.sh`. LiveStack remains
healthy on loopback and authorized operators may continue to use the SSH local
forward documented in `docs/livestack-integration.md`.
