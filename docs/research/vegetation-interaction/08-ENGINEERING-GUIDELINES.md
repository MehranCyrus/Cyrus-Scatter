# 08 Engineering guidelines

**Status: proposed feature guidelines, subordinate to existing repository contracts.** These identifiers are local research review aids, not additions to the foundation's F01-F12 contract IDs. A later implementation should resolve them in its scoped plan and acceptance receipt.

## Reviewable requirements

| ID | Guideline | Evidence needed later |
| --- | --- | --- |
| VG01 | Preserve accepted placement identity, count and planted root transforms during rooted fitting | Before/after placement comparison; explicit upstream-change cases |
| VG02 | Keep source/rest geometry immutable and preparation reusable per compatible source revision | Source mutation checks and revision-driven invalidation |
| VG03 | Keep root position, tangent and cross-section orientation distinct | Hinge/clamp/soft-base fixtures with measured errors |
| VG04 | Define explicit obstacle membership independent of placement collision scopes | Scope isolation and ground/receiver tests |
| VG05 | Include every relevant local obstacle, whole-segment contact and final decoded mesh validation | One/two-obstacle, missed-segment and width fixtures |
| VG06 | Declare rest state, initialization, history and repeatability policy | Fixed-intersection, clear-initial and conditioning comparisons |
| VG07 | Reconsider old/new influence and previous dependencies after obstacle edits | Move-away/deletion tests and fresh-setup comparisons |
| VG08 | Reuse only when full inputs remain compatible | Transform/source/preparation/settings/revision tests |
| VG09 | Keep host API access at the host boundary and workers on owned numeric snapshots | Lifetime, cancellation, owner deletion and stale-result tests |
| VG10 | Stage and publish a complete coherent successor; retain prior complete output on failure | Failure before/after commit, stale completion and reader lifetime checks |
| VG11 | Preserve existing Manual/Live and passive browsing behavior | Pending edits, relevant animation, idle/selection/upload counters |
| VG12 | Use one qualified shape evaluation policy across viewport, render and Bake | Actual output comparison in a selected Max 2027 renderer |
| VG13 | Bound computation, geometry, memory and history independently | Peak/retained allocation records and budget-exhaustion cases |
| VG14 | Expose unresolved contact, stale state and limitations honestly | Selectable diagnostics, partial-acceptance and user recovery tests |
| VG15 | Preserve geometry appearance channels deliberately | UV/material/smoothing/explicit-normal fixtures |
| VG16 | Keep static fitting, rigid settling and deformable drape separate in data and behavior | Mode-specific inputs, time/reset and output acceptance |
| VG17 | Preserve render-corner, logical-position and semantic-part identities independently | UV/normal splits, opposite winding and coincident-independent fixtures |
| VG18 | Require rest reconstruction, frame/twist and shared-base compatibility before accepting preparation | Full-turn twist, opposing blends, junction stress and rig-conversion pose comparisons |
| VG19 | Qualify owned mesh adapters and renderer profiles independently from source readiness | Shared-channel/cache lifetimes, explicit normals, transformed sources and exact-variant inspection |
| VG20 | Reuse solver/query capabilities only within inspected and measured boundaries | Exact source/build identity, whole-segment/multi-contact fixtures and same-input contact-backend comparison |
| VG21 | Declare engine scale, origin, capacity and cancellation behavior before adoption | Unit/translation invariance, error-bit admission, bounded updates, job/barrier and shutdown checks |
| VG22 | Qualify the geometry/query adapter with independent truth and final acceptance | Tiny-scale/parity/sign/COM controls; sleep-residual counterexample; shared false-negative detection |
| VG23 | Preserve complete rod preparation, state and step ownership | Rest frames/remaps, root velocities, complete reset, contact-refresh cadence and world/manual-step isolation |
| VG24 | Own coherent query generations and shared runtime services explicitly | Mid-solve obstacle edits, compatible shape/pose leases, actual module/allocator boundaries and overlapping-world shutdown checks |
| VG25 | Qualify local contact witnesses and their response model before composing a solver | Capsule/rod axes, semantic fraction, endpoint/rotation gradients, pinned mobility, immovable conflicts and refreshed final validation |

## Before implementation

Define the owner and lifetime of every new setting, source preparation record, obstacle snapshot, worker job, result, renderer mesh and Undo reference. Identify units/coordinate frames, invalidation triggers, unsupported transforms and persistence. Estimate peak storage including old/new overlap and prove the failure path before raising population limits.

Read the current [foundation](../../ENGINEERING_FOUNDATION.md), [workflow](../../AGENT_WORKFLOW.md) and relevant source. Research reports and this library do not substitute for a new source/status check. Use C++ for placement-sized numerical work and storage; keep bounded UI coordination in the established scripted/managed boundary unless measurements justify a different choice.

## During experiments

Change one meaningful variable at a time, preserve exact fixtures and distinguish setup errors from solve errors and output errors. Store numeric measurements with their full tolerances and units. A selected attractive image is insufficient to establish reliability. A documented operator can support a proposed recipe while that complete recipe remains untested.

Compare the simplest sufficient method with the chosen comparator. Do not add a generic framework, GPU backend, universal DQ skinning system or compatibility layer merely because future research mentions one. A measured limitation should drive each extension.

## At handoff

Explain actual behavior, changed ownership, exact evidence and remaining acceptance. Keep independently versioned products separate. Record new qualification in the appropriate existing implementation/ledger location only when authorized work produces it. Preserve historical reports, failed cases and original source hashes.

For external research, request runnable minimal scenes and measurements for specific unresolved questions. Another broad literature survey is lower priority than a reproducible fixed-obstacle/initial-overlap case, a real asset audit or an output-parity experiment.

## Documentation updates

Preserve new originals byte-for-byte and extend the source manifest with new IDs. Reconcile contradictions in Chapter 09 before adopting claims elsewhere. Cite primary sources for vendor facts and local source for Cyrus behavior. Label copied experimental settings as proposed; do not silently promote task counts to timings or stored example records to executed tests.

Edit the numbered Markdown, update the checklists, regenerate HTML/PDF and rerun package integrity/layout checks. A documentation pass does not refresh the knowledge corpus, build the website, qualify the plugin or authorize publication.
