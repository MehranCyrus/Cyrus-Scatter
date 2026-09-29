# 01 — Licensing Requirements and Principles

## Functional requirements

1. Activate/deactivate Solo license.
2. Support machine transfer with reasonable limits.
3. Support full-feature trial.
4. Support Studio concurrent/floating seats.
5. Support true offline node-locked activation.
6. Support air-gapped Studio floating as an enterprise option.
7. Allow existing scenes to render on render workers without paid authoring seats.
8. Preserve perpetual access to eligible builds after maintenance expiry.
9. Gate feature entitlements without scene corruption.
10. Expose status/diagnostics to MAXScript UI without trusting MAXScript for enforcement.
11. Continue operating through short provider/network outages.
12. Support Max 2026 and 2027 release packages.
13. Allow provider replacement without rewriting product code.

## Non-functional requirements

- license validation must not enter scatter/preview hot loops;
- no WAN calls during every viewport redraw;
- thread-safe process-wide state;
- deterministic policy decisions;
- auditable reason codes;
- privacy-minimized diagnostics;
- signed/tamper-evident cached state;
- safe failure: deny mutation, preserve scene fidelity;
- provider secrets never embedded in client.

## Customer-experience principles

- an activated perpetual license should feel owned;
- offline customers get an explicit supported workflow;
- hardware changes should be recoverable;
- studio users should not manually deactivate seats every day;
- render farms should not require hundreds of paid authoring seats;
- errors should explain what action is blocked and how to resolve it;
- license outages should not destroy work.

## Security principle

The goal is to increase the cost of casual and moderate cracking while keeping legitimate workflows reliable. A determined local attacker can patch client code; design defense in depth rather than promising impossibility.
