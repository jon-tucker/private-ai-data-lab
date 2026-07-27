# ADR 0014: Enforce a conservative backup lifecycle

## Status

Accepted.

## Context

Coordinated recovery sets are large, but automatic deletion creates a direct
risk to recoverability. Age alone is not sufficient evidence that a backup is
safe to remove.

## Decision

Retention evaluation is dry-run by default. Deletion requires both `--apply`
and `--confirm-delete`. A recovery set is eligible only when it:

- has a timestamp-only directory name directly beneath the configured root;
- is older than the configured retention period;
- is not among the configured minimum number of newest sets; and
- contains an independently written `VERIFICATION.txt` marker with
  `status=VERIFIED`.

Capacity checks estimate the next backup from the newest coordinated recovery
set and protect a configurable free-space reserve. Restore drills extract only
into a dedicated staging root that cannot overlap active platform data or the
backup root.

Legacy pre-install and post-install recovery points remain outside automated
retention.

## Consequences

Operators must explicitly record verification before a set can become
eligible. Cleanup is intentionally two-step and auditable from command output.
Restore-drill staging consumes temporary capacity and must be removed through
a separately reviewed action.
