# Cyrus licensing

**Current plan: 2026-10-05. A native-owned recipe/Edit/Brush slice and real installation-key activation, expiry and renewal now pass private Max tests. Whole-product enforcement, host recovery/lifecycle, customer service and production qualification remain incomplete. Post-expiry rendering is selected; full-term offline use and one-device activation are requested.**

Build and operate Cyrus's own licensing service. Keep Scatter computation and viewport work local, authorize meaningful native operations, and separate product rights from purchases and seat allocation. This is the selected direction. Exact commercial terms are still decisions to make.

The user confirmed the subscription behavior: preserve and allow rendering of existing work after expiry, stop new authoring/editing, and restore editing after verified renewal. The foundation must allow supported policies to change without scattered checks or unnecessary redesign. [Decisions D09–D13](DECISIONS.md) record this intent, the request for offline editing through the subscription end, and one authorized device per seat with portal transfers. Exact evaluation/dependency behavior still needs L0 testing. Full-term offline use requires accepting clock/revocation limits; the transfer/overlap policy remains open. A website deactivation cannot instantly revoke a disconnected copy.

This folder is the current authority for licensing. It replaces the provider-first implementation sequence in the September package and the older commercialization stages. Dated research remains available; it is not a second backlog.

## Read in this order

| Document | Purpose |
| --- | --- |
| [Roadmap](ROADMAP.md) | Ordered implementation milestones, deliverables, tests and the next coding packet |
| [Decisions](DECISIONS.md) | Selected direction, proposed launch scope, unresolved business terms and scene-continuity matrix |
| [Architecture](ARCHITECTURE.md) | Native/service boundaries, individual/studio accounting, signed permissions, security and operations |
| [Native and local foundation — current result](NATIVE_FOUNDATION_2026-10-05.md) | Real CNG/DPAPI, immutable grants/permits, shared Edit/Brush gates, two-Max lifecycle, measured limits and remaining scope |
| [First coding-loop result](L0_EXPERIMENT_2026-10-04.md) | Actual policy/SDK/Max tests, reproduction, render comparison and observed wrapper bypasses |
| [Signed-license experiment](SIGNED_LICENSE_EXPERIMENT_2026-10-04.md) | Independent issuer/CNG verification, parser tests, signed renewal and disposable Max results |
| [Implementation components](IMPLEMENTATION_COMPONENTS.md) | What Cyrus owns, what we reuse, pinned open-source dependencies and alternatives |
| [Candidate signed profile](SIGNED_TOKEN_PROFILE.md) | Exact lab protocol, admission rules and remaining trust/device/time limits |
| [Operation contract](OPERATION_CONTRACT.md) | Provisional current entry-family map and the next native ownership experiment |
| [Codebase audit](CODEBASE_AUDIT.md) | Ten source-grounded integration findings, operation inventory and concrete improvements for L0/L1/L3 |
| [Document audit](DOCUMENT_AUDIT.md) | What was kept, corrected, retired or preserved from each earlier document |
| [Sources](SOURCES.md) | Official vendor/standards evidence and its limits |

## What we will build first

The blocking milestone remains **complete native ownership and a settled continuity contract**. The [October 5 implementation](NATIVE_FOUNDATION_2026-10-05.md) moved beyond wrappers and a signed-message prototype: it owns a bounded recipe, gates actual CS Edit and Brush mutation, uses real installation identity/protected state, and verifies cold rendering and renewal across two Max processes. Full procedural layer settings, source/container transactions, Analyzer dependencies, PFlow/bake continuity and migration still require coverage. B07/B08 were presented with reproduced counterexamples and remain open.

The [October 2 static source audit](CODEBASE_AUDIT.md) remains the dated starting map. It identifies shared authoring/evaluation calls, preview and PFlow cleanup before calculation, CS Edit mutation and identity-recovery paths, and runtime/package preparation. Its 37-file snapshot and 38 native declarations are historical scope; the October 4 experiment records 163 source files and 69 declarations after Brush/group/MCP development. An inventory is not complete authorization coverage.

After those pass, build a small owned service with audited manual grants, individual accounts and assigned studio seats. Integrate an isolated Max candidate and recovery UI. Floating pools, automated commerce and public release each have separate acceptance gates. The roadmap is final as the current sequence, not a claim that future experiment results cannot change the design.

## Keep the scope practical

- One complete initial authoring feature set. New algorithms and same-product workflows reuse rights; new mutation entry points still require registration and coverage tests.
- One service codebase, one authoritative database and maintained authentication/cryptographic components. No licensing-provider adapters or custom cryptographic algorithms in the first implementation.
- Assigned users, registered devices and concurrent reservations are separate rules. More purchased seats or different discounts are server data, not plugin rebuilds.
- Preserve scene data and keep recovery reachable. Expiry must never erase scatter state, silently empty output or strand an in-progress edit.
- No license network calls, signature verification, storage access or seat checkout in placement loops or viewport callbacks.

## What this cleanup established

The review covered all 33 numbered chapters and nine diagrams of the old licensing package, its manifest, the active strategy and commercialization licensing pages, the dated codebase licensing/security chapters, the October 2 industry design, and representative current source anchors. The useful foundations survived. Vendor procurement steps, unapproved durations, simplistic state/seat models and overconfident worker detection were corrected or retired.

The original document cleanup added no licensing code. The subsequent [policy loop](L0_EXPERIMENT_2026-10-04.md), [signed-license loop](SIGNED_LICENSE_EXPERIMENT_2026-10-04.md) and [native/local implementation](NATIVE_FOUNDATION_2026-10-05.md) record distinct exact source/build/runtime evidence. The latest establishes software installation binding and bounded clock observations, not physical hardware attestation, tamper-proof offline time, production enforcement or penetration-test results. Existing viewport improvements do not establish licensing correctness.

The [decisions register](DECISIONS.md) identifies what can remain configurable during the prototype and what must be settled before enforcement, a customer pilot or sale. No new permission is needed merely to maintain these documents; the gates are requirements for the eventual product commitments.
