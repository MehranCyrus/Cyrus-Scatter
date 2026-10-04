# Cyrus licensing

**Current plan: 2026-10-04. Post-expiry rendering selected; full-term offline use and one-device activation requested. Licensing implementation and security qualification remain pending.**

Build and operate Cyrus's own licensing service. Keep Scatter computation and viewport work local, authorize meaningful native operations, and separate product rights from purchases and seat allocation. This is the selected direction. Exact commercial terms are still decisions to make.

The user confirmed the subscription behavior: preserve and allow rendering of existing work after expiry, stop new authoring/editing, and restore editing after verified renewal. The foundation must allow supported policies to change without scattered checks or unnecessary redesign. [Decisions D09–D13](DECISIONS.md) record this intent, the request for offline editing through the subscription end, and one authorized device per seat with portal transfers. Exact evaluation/dependency behavior still needs L0 testing. Full-term offline use requires accepting clock/revocation limits; the transfer/overlap policy remains open. A website deactivation cannot instantly revoke a disconnected copy.

This folder is the current authority for licensing. It replaces the provider-first implementation sequence in the September package and the older commercialization stages. Dated research remains available; it is not a second backlog.

## Read in this order

| Document | Purpose |
| --- | --- |
| [Roadmap](ROADMAP.md) | Ordered implementation milestones, deliverables, tests and the next coding packet |
| [Decisions](DECISIONS.md) | Selected direction, proposed launch scope, unresolved business terms and scene-continuity matrix |
| [Architecture](ARCHITECTURE.md) | Native/service boundaries, individual/studio accounting, signed permissions, security and operations |
| [Codebase audit](CODEBASE_AUDIT.md) | Ten source-grounded integration findings, operation inventory and concrete improvements for L0/L1/L3 |
| [Document audit](DOCUMENT_AUDIT.md) | What was kept, corrected, retired or preserved from each earlier document |
| [Sources](SOURCES.md) | Official vendor/standards evidence and its limits |

## What we will build first

The first coding loop is **L0: prove the authorization boundary and record the contract**, followed by **L1: an isolated policy and signature harness**. Use fake grants and disposable fixtures. Trace authoring, parameter changes, saved-state evaluation and rendering through the actual plugin before assuming that a generic native check can distinguish them safely.

The [static source audit](CODEBASE_AUDIT.md) now provides the starting map. It identifies shared authoring/evaluation calls, preview and PFlow cleanup before calculation, CS Edit mutation and identity-recovery paths, and runtime/package preparation. Its 37-file snapshot and 38 native declarations are evidence for planning; the boundary prototype and licensing tests remain pending.

After those pass, build a small owned service with audited manual grants, individual accounts and assigned studio seats. Integrate an isolated Max candidate and recovery UI. Floating pools, automated commerce and public release each have separate acceptance gates. The roadmap is final as the current sequence, not a claim that future experiment results cannot change the design.

## Keep the scope practical

- One complete initial authoring feature set. New algorithms and same-product workflows reuse rights; new mutation entry points still require registration and coverage tests.
- One service codebase, one authoritative database and maintained authentication/cryptographic components. No licensing-provider adapters or custom cryptographic algorithms in the first implementation.
- Assigned users, registered devices and concurrent reservations are separate rules. More purchased seats or different discounts are server data, not plugin rebuilds.
- Preserve scene data and keep recovery reachable. Expiry must never erase scatter state, silently empty output or strand an in-progress edit.
- No license network calls, signature verification, storage access or seat checkout in placement loops or viewport callbacks.

## What this cleanup established

The review covered all 33 numbered chapters and nine diagrams of the old licensing package, its manifest, the active strategy and commercialization licensing pages, the dated codebase licensing/security chapters, the October 2 industry design, and representative current source anchors. The useful foundations survived. Vendor procurement steps, unapproved durations, simplistic state/seat models and overconfident worker detection were corrected or retired.

No licensing code was added and no licensing runtime or penetration test was run. Existing performance improvements do not establish licensing correctness. Implementation results must be recorded against the roadmap with the exact build and evidence.

The [decisions register](DECISIONS.md) identifies what can remain configurable during the prototype and what must be settled before enforcement, a customer pilot or sale. No new permission is needed merely to maintain these documents; the gates are requirements for the eventual product commitments.
