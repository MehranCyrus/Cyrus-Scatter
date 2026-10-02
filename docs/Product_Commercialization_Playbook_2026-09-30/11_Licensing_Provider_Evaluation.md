# Stage 11 — Owned licensing service validation

**Updated 2026-10-02.** This filename is retained to preserve existing links. The former commercial-provider comparison/selection stage is retired. We are building our own service.

## Goal

Collect evidence that the system follows the approved operation, seat and recovery rules. Use [roadmap experiments E01–E17](../licensing/ROADMAP.md), not a vendor scorecard. Official company documentation supports design patterns; it does not qualify Cyrus code.

## Work to perform

1. Finish the L0/L1 boundary and policy/verifier experiments.
2. Build L2 with maintained authentication, protected signing, manual grants, individual accounts and assigned studio seats.
3. Prove tenant isolation, assignment/device separation, idempotent issuance, refresh/recovery and stale-backup behavior.
4. Integrate the isolated Max candidate in L3 and verify scene/render continuity plus no licensing work in viewport loops.
5. If floating is included, run L4 contention, partition, multiple-process and offline-reservation experiments before offering it.
6. Qualify commerce and operations under L5/L6 for the intended release.

Match the test scope to the offer. Mark optional modes DEFERRED with a reason; a required but unavailable configuration is NOT TESTED, not a pass.

## Evidence record

For every experiment record test ID, date, source/build, environment, policy, expected/actual behavior, raw evidence path, failure/reproduction and follow-up. Keep customer identifiers and credentials out of repository evidence.

Include hosting/auth/signing/backup/monitoring costs and expected support effort. We still depend on infrastructure and libraries; owning licensing does not remove operating responsibility.

## Completion and present status

All licensing implementation experiments remain NOT RUN after this documentation cleanup. Stage completion means the required experiments pass or have a documented scoped decision; it does not mean a vendor was chosen or that a design document looks complete.

Customer trials and beta claims must use the tested build and fixed policy. A feature beta without licensing and a licensing beta are different scopes.

Next: [Stage 12 — Beta readiness](12_Beta_Readiness.md).
