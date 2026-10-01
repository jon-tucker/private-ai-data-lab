# Security policy

## Supported versions

| Version | Supported |
| --- | --- |
| 1.5.x | Yes |
| Earlier milestones | No |

The project is a production-inspired reference environment, not a managed
service. Operators remain responsible for host patching, network policy,
credential custody, backup protection, and compliance requirements.

## Reporting a vulnerability

Do not open a public issue containing credentials, exploit details, private
network information, or other sensitive evidence.

Use GitHub private vulnerability reporting for this repository when
available. If it is unavailable, contact the repository owner privately and
provide only enough initial detail to establish a secure follow-up channel.

Include:

- The affected release and component.
- Reproduction conditions and expected impact.
- Whether credentials or private data may be exposed.
- Any known mitigation that does not destroy evidence.

Do not test against systems you do not own or have explicit permission to
assess.

## Secret handling

Real credentials, private keys, generated certificates, wallets, database
files, backup data, and local `.env` files must remain outside Git. If a
secret is accidentally committed, revoke or rotate it immediately; removing
it from the latest commit is not sufficient.
