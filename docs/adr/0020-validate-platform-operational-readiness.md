# ADR 0020: Validate platform operational readiness

## Status

Accepted

## Decision

Treat operational readiness as a repeatable, automated acceptance state rather
than a collection of manually remembered checks.

The readiness validator composes existing component checks and additionally
requires:

- Healthy core services and private Agent Factory access.
- Persistent Docker, container, VM, and Agent Factory application startup.
- Active scheduled health and coordinated-backup timers.
- At least the configured minimum number of recovery sets.
- Independent verification of the newest recovery set.
- Valid shell and Compose source configuration.

## Consequences

- Operators receive one definitive post-change and post-reboot check.
- Existing detailed scripts remain the source of component-specific checks.
- A failed readiness check blocks release claims but does not automatically
  mutate services or recovery data.
- Recovery-set verification and startup persistence become release acceptance
  requirements.
