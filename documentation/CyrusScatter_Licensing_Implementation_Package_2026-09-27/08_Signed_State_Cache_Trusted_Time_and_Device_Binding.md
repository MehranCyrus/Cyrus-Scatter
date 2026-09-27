# 08 — Signed State, Cache, Trusted Time, and Device Binding

## Signed state

Provider responses/offline files must be cryptographically authenticated before claims are trusted. Store only the minimum normalized snapshot needed by policy.

## Cache

Recommended cache content:
- provider/license IDs;
- license kind;
- feature entitlements;
- machine binding digest;
- maintenance date;
- offline/grace deadline;
- last trusted server time;
- last successful refresh;
- provider-specific opaque signed state.

Protect cache with provider signature plus OS-appropriate local protection where useful. Local encryption alone is not authenticity.

## Trusted time

Detect obvious rollback by comparing:
- last trusted server time;
- monotonic elapsed time while process runs;
- current wall clock;
- signed provider timestamps.

Do not brick a perpetual license because a laptop clock changed slightly. Use reasoned tolerances and an explicit `ClockSuspect` recovery flow.

## Device binding

Do not implement a brittle custom MAC+disk serial lock.

Preferred order:
1. provider SDK/device fingerprint;
2. provider-supported hardware tolerance;
3. if custom is required, multiple stable signals with weighted tolerance and privacy review.

## Hardware change UX

- minor change → continue;
- major fingerprint change → activation recovery/transfer;
- dead machine → support/admin seat reset;
- repeated suspicious churn → rate-limit/support review.

## Public key placement

Public verification keys may be embedded in native code. They are not secrets. Private signing/admin keys must never ship.
