# 09 — Research, design decisions and remaining uncertainty

Primary sources reviewed on 4 October 2026. Vendor documentation explains public behavior; it does not reveal proprietary implementation internals. The proposed Cyrus design is our engineering synthesis, not a claim that Houdini, Forest Pack or FStorm uses this exact architecture.

The subsequent [readiness review](10_READINESS_REVIEW.md) adds direct code and executable evidence. It does not assert a new vendor-documentation search or change the sources below.

## Primary-source register

| ID | Source | Supported observation | Application and limit |
| --- | --- | --- | --- |
| S1 | [SideFX HDK: Dependencies](https://www.sidefx.com/docs/hdk/_h_d_k__op_basics__overview__dependencies.html) | Cooking follows data dependencies and dirtiness; non-wire dependencies also need registration | Model actual consumers. Visual top-to-bottom order alone is not a complete dependency graph. |
| S2 | [SideFX: Cache If](https://www.sidefx.com/docs/houdini/nodes/sop/cacheif.html) | Conditional reuse can inspect changed inputs/attributes/parameters; this cache is in RAM | Separate validity from storage. Do not infer every node keeps a permanent disk cache. |
| S3 | [SideFX: File Cache](https://www.sidefx.com/docs/houdini/nodes/sop/filecache.html) | Disk-cached geometry is a separate explicit workflow | Defer portable evaluated snapshots until in-memory semantics are stable. |
| S4 | [SideFX: Scatter](https://www.sidefx.com/docs/houdini/nodes/sop/scatter.html) | Density, count, relaxation radii, stable output IDs and surface primitive coordinates are distinct concepts | Keep population, spacing, identities and anchors explicit. Houdini's radius/density conventions are not automatically Cyrus defaults. |
| S5 | [SideFX: Scatter and Align](https://www.sidefx.com/docs/houdini/nodes/sop/scatteralign.html) | Instance-size attributes, relaxation, overlap removal, constraint points and generation limits are separate controls | Useful conceptual separation; no inference about Max SDK integration or our solver's complexity. |
| S6 | [iToo: Forest Pack Image Mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode) | Collision removes items using simplified spheres, adjustable per-geometry/global radius influence; excessive rejection can waste distribution work | Support artistic footprints and rejection statistics. Do not promise exact foliage contact. |
| S7 | [iToo: General rollout](https://docs.itoosoft.com/forestpack/forest-plugin/general) | Build statistics include created items/build time and diagnostic conditions; CPU options are documented | Make cost and output understandable. This does not prove Forest's private cache structure or a particular per-layer memory metric. |
| S8 | [iToo: Areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas) | Include/exclude areas, paint and object exclusion are distinct authoring tools; sphere/mesh exclusion trade precision for work | Keep spatial intent separate from plant-pair spacing. Do not copy a ground-projected approach and call it arbitrary surface distance. |
| S9 | [Autodesk 2026 SDK: IRenderingProcess](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_rendering_a_p_i_1_1_i_rendering_process.html) | The SDK is generally not thread-safe; many scene operations need the main thread | Snapshot on the host-safe boundary; run numeric work on owned data. Its render-session helper is not prescribed as our plugin scheduler. |

No claims in this package require reverse-engineering a vendor. The FStorm preview example is motivation to investigate efficient display representations; it does not establish unlimited geometry, an exact FPS target, or whether that product uses CUDA/OpenCL for scatter placement.

## Decisions and alternatives

| ID | Recommended decision | Reason | Revisit when |
| --- | --- | --- | --- |
| D1 | Fixed procedural stages and explicit dependencies | Small implementation with clear invalidation; no node-editor prerequisite | Artists need arbitrary user-authored processing graphs |
| D2 | One rule classification per point pair | Three independent scopes without repeated radius/gap application | A separately defined multi-constraint policy is requested |
| D3 | Manual/source radius plus sparse instance override | Builds on current controls and supports artistic spacing | Automatic bounds demonstrably reduce setup effort |
| D4 | Uniform-grid native baseline | Existing code and exhaustive oracle are reusable | Mixed-radius profiling shows excessive neighbor work |
| D5 | Layer cleanup barrier | Current cleanup legitimately consumes the sibling union | A separately authored per-set cleanup is required |
| D6 | Bounded deterministic repair with transaction-local suppression | Frees removed occupancy while guaranteeing a finite work schedule | Artist fixtures reveal unacceptable suppression bias or poor fill efficiency |
| D7 | Separate background fill from target replenishment | Artist intent and computational cost differ | Never silently merge their meaning |
| D8 | Preserve candidate-budget mode and old policy | Avoid changing existing scenes and count expectations | Explicit scene conversion selected |
| D9 | Immutable intermediate outputs with memory budgets | Enables reuse without stale or half-published generations | Measurements justify another storage strategy |
| D10 | Preserve retained Point/Mesh and cached Proxy paths | Existing performance work is valuable and independent of spacing | Controlled display profiling identifies a specific limitation |
| D11 | CPU correctness before further parallel/GPU work | Unnecessary work and wrong dependencies cannot be fixed by more processors | Measured numeric stages dominate after caching improvements |
| D12 | Versioned MCP extension after native qualification | One evaluator and honest capability boundaries | Native policy and ownership contract are stable |
| D13 | ML proposes recipes, engine evaluates them | Artist control and reproducible geometry remain inspectable | A measured learned-placement task merits a separate contract |
| D14 | Separate owner, sampling, allocation and final-instance identities | Reorder/copy/clone semantics must not be accidental RNG or row-order effects | A versioned correspondence change is intentionally introduced |
| D15 | Fixed logical refill schedule independent of cache capacity | Cleanup suppression makes batch history observable | A different refill algorithm proves a stronger schedule-independent contract |
| D16 | Support-anchor eligibility separate from mesh origin | Preserve source offsets and explain protected moves without double sampling coverage | An explicit mesh-footprint boundary policy is implemented |
| D17 | Explicit policy capabilities and pure keys | Policy 2 is assumed in multiple UI/display/Edit paths; presentation fields enter current keys | A tested adapter safely replaces each branch |

## Remaining engineering questions with concrete tests

1. **Cleanup repair bias:** compare no repair, bounded suppression/replay and a small exhaustive reference search on tiny layouts. Evaluate final count, style and work. Maximal filling is not assumed.
2. **Radius convention:** verify source pivot/offset/scale composition and tilted/sheared assets against conservative geometry samples. Decide manual versus optional automatic footprint behavior explicitly.
3. **Identity stability:** prove which old candidate/edit namespaces survive count, source-row and set-allocation changes. New guarantees require versioning and tests, not comments alone.
4. **Cache event coverage:** mutate source geometry, transform, density maps, Brush and time independently. Compare incremental and forced-fresh results.
5. **Density area:** measure deterministic weighted-area integration error on curved painted receivers before introducing accepted-density targets.
6. **Work budgets:** profile rejected attempts and memory peaks on sparse and nearly saturated scenes before choosing release defaults.
7. **Cross-version runtime:** verify Max 2026 independently when shipping support. A successful SDK build is necessary but not sufficient.

These questions do not block writing P0–P2. They define the evidence required before the more complex modes are enabled.

## Evidence boundaries

Verified here: current source structure, final generated evaluation flow, native spacing/cleanup implementation, existing test intent, current public capability documentation and primary vendor sources.

Proposed here: new rule/data contracts, bounded cleanup/refill semantics, fine-grained revision domains, UI additions and MCP extensions.

Not established here: current artist-scene FPS, a new build's correctness, shipping refill limits, GPU speedups, arbitrary topology/animation support, maximal packing, ML quality or vendor-internal algorithms.

Refer to [source snapshot](evidence/source_snapshot.json) and [documentation validation](evidence/verification.json) for the initial pass, and [readiness evidence](evidence/readiness/README.md) for the fresh pure-native/MCP and counterexample checks. Preserve historical reports as dated evidence rather than silently treating them as tests of this proposal.
