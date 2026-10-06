# Current code and evidence audit

This is a focused audit of the foundation for design learning, not a new full correctness qualification of every plugin feature. Paths are relative to the repository; line numbers refer to the [captured source hashes](evidence/source_snapshot.json).

## Checkout and evidence boundary

- HEAD: `addccb492a88292529594de81c287cc26e5ffe98`.
- Branch: `codex/floating-layer-editor-0.7.1`.
- Generated MAXScript SHA-256: `07d0bca2efe330b8b632c1a483cea23c65629b0f7ef5c0cbecd2c6984f1f9924`.
- Product UI: 0.7.1; current serialization baseline: 53. MCP package: 1.1.0. These are different version domains.
- [Initial Git status](evidence/git_status_before.txt) includes local generated UI changes, new Layer Editor templates, UI/real-scene documentation and private test helpers. Reviewing HEAD alone would omit them.
- 488 source/tool files were fingerprinted. The inventory excludes compiled DLLs, SDKs, artist scenes and private asset files. It does not establish what any running Max process has loaded.
- A fresh run of the existing offline MCP suite passed 66 tests in 8.15 seconds; [receipt](evidence/mcp_offline_tests.txt). Host and scene behaviours in those tests are partly fake/test implementations. No new Max or renderer qualification occurred here.

## Integration map

| Source fact and location | Consequence for future ML/MCP |
| --- | --- |
| [server.py](../../CyrusMCP/cyrus_mcp/server.py), lines 35–78: nine public tools; lines 80–96: schema/workflow/capability resources | An agent already has structured discovery, validation, apply, status, diagnostics, configuration, export and capture. More buttons do not automatically mean more public tools. |
| [settings.py](../../CyrusMCP/cyrus_mcp/settings.py), lines 75–91: explicit supported/unavailable manifest | Use this as a contract source, then test agreement with schemas, UI and runtime. |
| [models.py](../../CyrusMCP/cyrus_mcp/models.py): strict closed plans 1.0/2.0 | Add versioned semantics for the new engine; do not silently reinterpret an old plan as policy 3. |
| [procedural.py](../../CyrusMCP/cyrus_mcp/procedural.py), lines 36–40; [max_host.py](../../CyrusMCP/cyrus_mcp/max_host.py), lines 339–340 | Old mutation is explicitly rejected on policy-3 controllers before generation. Read-only policy 3 is intentional. |
| [procedural.py](../../CyrusMCP/cyrus_mcp/procedural.py), lines 43–89 | Inspection exports ordered layer/set recipes, source entry IDs, overrides and last-publication statistics. It does not evaluate or certify a fresh layout. |
| [service.py](../../CyrusMCP/cyrus_mcp/service.py), lines 168–259 | Enrollment, fresh context, normalized-plan digest, local exact approval, revision, idempotency and application budget precede mutation. |
| [service.py](../../CyrusMCP/cyrus_mcp/service.py), lines 271–305 | Queued work records running/success/failure/unknown states. An unexpected outcome makes the scope stale. |
| [records.py](../../CyrusMCP/cyrus_mcp/records.py), lines 6–15 | Export verifies actual transform digest and emitted count; IDs/correspondence have explicit lineage semantics. Training eligibility is false. |
| [records.py](../../CyrusMCP/cyrus_mcp/records.py), lines 18–34 | A correction-record constructor exists. It does not automatically observe artists, infer preferences or grant consent. |
| [service.py](../../CyrusMCP/cyrus_mcp/service.py), lines 332–355 | Export is for a recorded, owned, current generation; capture has revision, sharing and budget checks. Capture can trigger a redraw and is not a proof of fresh exact geometry. |
| [procedural.h](../../AminScatter/include/procedural.h), lines 8–50 | Native evaluation consumes pure data; stable sample IDs, radii, protected edits, limits and outcomes are explicit. This is a useful boundary for deterministic tests. |
| [procedural.cpp](../../AminScatter/src/procedural.cpp), lines 23–57 | Validates identities, radii, rules and bounded work. Limits include ten total populations, up to 100,000 budget/attempts per set, one million admitted samples, 16 rounds and 50 million neighbor visits. These are ceilings, not speed guarantees. |
| [procedural.cpp](../../AminScatter/src/procedural.cpp), lines 68–143 | Ordered collision resolution, protected blockers, union cleanup and bounded prefix extension determine survivors and shortfall. Learning should consume these reasons. |
| [procedural-evaluation.ms](../../AminScatter/tools/ui/templates/procedural-evaluation.ms), lines 24–38, 111–178 | Prepared rows and published groups have separate cache keys; work is admitted, staged and transactionally published, with a rollback path. Failure injection remains necessary before batch qualification. |
| [source-containers.ms](../../AminScatter/tools/ui/templates/source-containers.ms), especially lines 125–158 | Container events and procedural invalidation interact. Container movement must be frozen or revision-bound during candidate generation. |
| [point_display.cpp](../../AminScatter/src/point_display.cpp), lines 261–268 | Retained publication avoids replacing an unchanged generation; a changed generation sends geometry/display notifications. Observe this boundary when diagnosing IR restarts. |

## Generation-to-output path relevant to learning

The existing intended path is: surface sampling and source assignment → Area/density/Brush eligibility → transforms and CS Edit effects → effective radii → self/set/layer spacing → cleanup and bounded refill → staged preview and coherent publication → retained display and exact/render output. The pure native procedural solver operates on prepared rows; it does not itself sample surfaces or call Max.

In the UI evaluator, `procPrepare` caches prepared rows and applies Edit changes; `evaluateProcedural` filters container membership, computes effective radii, invokes `cyrusEvaluateProcedural`, stages preview objects, commits Edit state and publishes an epoch. `procRefreshPreview` preserves the previous viewport when a successor fails. This is source evidence for the design, not proof that every exception position is harmless. Batch tests must check failure during staging, Edit commit, output export and renderer preparation separately.

The engine distinguishes candidate attempts, eligible rows, accepted plants, protected conflicts, cleanup removal, unconsumed capacity and target shortfall. An ML dataset must preserve those distinctions. In particular, unconsumed refill capacity is not a rejected plant, and an artist-protected conflict is not an ordinary sampled success.

## Important current boundaries

| Area | Current state | Missing before the proposed loop |
| --- | --- | --- |
| Procedural layers/paint sets | Native local authoring and policy-3 inspection | Versioned complete procedural mutation and exact-result export |
| Three spacing scopes/radii | Engine supports them | Complete typed policy-3 API, units, overrides and stable-ID validation |
| Containers | Local source registration/activation retains parked settings; MCP describes configured references | Versioned membership snapshot, stale detection and explicit automation contract; a container is an asset palette, not a scatter receiver |
| Brush | Native editable local workflow | Enrolled surface-bound documents, bounded stroke/region import, coverage/export hashes, Undo and failure semantics |
| MCP design sites | Horizontal convex static design scope; at most three sources/layers and 2,000 aggregate requested candidates | Complex/curved sites need their own qualified enrollment and validation; native support does not imply API support |
| Batch generation | Two successful applications, two captures and bounded calls per enrollment | Explicit batch authorization, persistent candidate ledger, cancellation and quotas; repeated re-enrollment is not a batch design |
| Rendering | Local exact/PFlow/render paths and recorded production successes | Typed render job, reproducible camera/material settings, completion receipt and stalled-render handling |
| Inspection | Cached configuration/counters | Fine-grained cause tracing, reason summaries and freshness metadata suitable for a learning run |
| Learning | Planning documents and non-training operational records | Review UI, consent/provenance registry, dataset builder, models, evaluation and promotion |
| Public extensibility | Closed schema, owned scope | Capability-negotiated extensions rather than arbitrary property/code execution |

Inspect-only scopes may expose a broader existing scene than design enrollment supports. Do not copy a read-only inspected configuration into a write plan and assume it is executable.

## Logging and test evidence

The [performance monitor](../../tools/performance/CyrusPerformanceMonitor.ms) already records selected-controller observations and counters, manual operations/events and renderer statistics, with an external process sampler. [Edit tracing](../../tools/performance/CyrusEditTrace.ms) adds detailed developer instrumentation. The MCP operation journal retains at most 128 records and handles uncertain outcomes. These solve different diagnostic tasks; they are not a complete persistent user interaction history.

The new direct `procExternalChanged` path deserves explicit tracing coverage rather than assuming the older `externalChanged` wrapper covers it. Also, `procInputKey` calls `containerRefresh` and a density watcher. A future passive logger must not repeatedly call that function and accidentally change the behaviour it measures.

The offline tests cover closed schemas, malformed inputs, geometry bounds, unit/matrix conversion, local approval, exact retries/conflicts, stale context, queued cancellation, failed/unknown outcomes, transport checks, policy-3 read-only snapshots and refusal to downgrade policy 3. They do not establish current Corona IR stability, true presented FPS, multi-view render identity, persistent dataset recovery, or learned composition quality.

Historical qualification is recorded in [UI 0.7.1](../UI_0.7.1_2026-10-05/README.md), [the real scene](../Real_Scene_0.7.1_2026-10-05/README.md), [procedural runtime](../Procedural_Implementation_0.7_2026-10-04/RUNTIME_REPORT.md) and [the earlier implementation outcome](../Independent_Review_0.7_2026-10-05/CURRENT_OUTCOME.md). Preserve their environments and caveats. Developer fixture scripts can do more than the public MCP contract and must not be presented as proof that remote clients can do the same.

## Highest-priority gaps

1. Resolve and instrument the reported IR restart loop before any unattended renderer campaign.
2. Make a generation export verifiably correspond to policy-3 published transforms, settings, source membership and camera images.
3. Extend MCP with explicit procedural semantics and bounded disposable batch scope.
4. Collect explicit comparisons in a durable dataset independent of the operation journal.
5. Establish held-out artist evaluation before choosing a training architecture.

These priorities preserve the working engine and narrow the integration work. They do not call for a rewrite of the UI, evaluator or retained display system for style.
