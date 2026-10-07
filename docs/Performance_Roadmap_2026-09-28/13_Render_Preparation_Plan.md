# 13 — Render preparation and large-scene plan

**Goal:** reduce the time and memory needed to prepare correct Cyrus instances for a renderer, including interactive updates. Renderer image-calculation speed is not controlled solely by this plugin and must be reported separately.

## Current path

[pflow.ms](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/pflow.ms) constructs transient Particle Flow objects from placement matrices grouped by source. It may copy a Corona proxy prototype, builds PF sources/events/operators, validates observed vs expected particle counts, and tracks disposable nodes. Generated production script receives this template through [generate.cjs](../../AminScatter/tools/ui/generate.cjs).

The current cache signature includes time, revisions, controller/layer settings and source transforms/materials. `CyrusPFBuild` clears previous transport before building. `postRender` restores baked renderability; other lifecycle/timer paths handle clearing. Treat that lifecycle as a behavior to preserve and verify.

## R00 — Measurement before redesign

Implement B01 spans for signature polling, placement computation, source grouping, proxy preparation, PFlow object creation, particle update/count validation, scene-node ownership discovery and cleanup. Record source-group/layer/node/particle counts and memory peaks.

Test first render, repeated unchanged render, one-layer edit, one-source change, many-source scene, and a scene with many unrelated Max nodes. The `findItem before n` scene-diff loop is a possible scaling cost; confirm its contribution before replacing it.

Separate four clocks: Cyrus preparation, renderer scene translation, render-to-first-visible-result, and complete image rendering. Record which clocks the chosen renderer actually exposes rather than estimating the missing ones.

## R01 — Lower preparation cost while preserving transport

1. Improve native placements through accepted CPU tasks. Preserve source-group and placement order passed to PFlow.
2. Measure grouping allocations and possible batched/native packing; account for conversion overhead at the script boundary. Do not add a second full transform copy without measuring peak memory.
3. Replace repeated scene-membership searches only with a proven ownership strategy. A pre-build handle set may speed diffing, but callbacks and PFlow-generated auxiliary objects mean directly tracking only explicitly created nodes can miss objects. Track all owned auxiliaries and never delete unrelated callback-created/user nodes.
4. Cache source/proxy preparation only with complete geometry/time/material/display dependencies and safe object lifetime. Preserve the original proxy's display/material settings.
5. Optimize signature construction only after mapping invalidation inputs. A shorter key that misses a source material, transform, time or layer change is a correctness regression.

Keep all scene, PFlow, renderer and undo API calls on the host thread. Serial host work may remain dominant after native threading; record that limitation accurately.

**Exit:** same particle counts, matrices, source/material assignment and renderability restoration; no leaked/extra nodes; R01 improves nominated preparation cases.

## R02 — Conditional incremental updates

Consider updating existing PFlow transport only if R01 shows object reconstruction dominates and the installed host/renderer APIs support a safe update path.

Define a source/layer transport identity, changed-data generations, row counts and ownership rules. Specify exactly when transforms alone can update, when materials/prototypes must refresh, and when a full rebuild is mandatory. Particle IDs, order, count, scale and expected renderer visibility must remain correct.

Build new state transactionally where feasible: retain a valid previous representation until the replacement is ready, within the memory budget. Otherwise keep the existing full-clear/rebuild path and define error recovery explicitly. Do not retain two complete huge scenes without measuring the cost.

**Exit:** first/unchanged/partial-change render fixtures match baseline; full rebuild remains a reliable fallback; incremental behavior survives abort, save, reset and errors. If the API cannot provide safe updates, close the experiment and keep optimized full builds.

## Interactive rendering

Existing timers/stability checks coalesce changes. Measure burst-change delay and redundant build counts before tuning timer intervals. Verify the last requested settings win after rapid edits, and that stopping/restarting IR cannot publish older placements.

Threaded CPU and optional GPU tests must run while rendering to expose shared-resource contention. Limit compute concurrency and GPU buffers where needed; higher utilization is not the success metric. Use time to the correct visible update and render stability.

The source has Corona-specific IR/proxy handling. Qualification requires compatible Corona versions for each claimed host. Generic PFlow preparation should also be tested with an available supported renderer. Until actual tests exist, do not claim all renderers or farm managers are supported.

## Lifecycle matrix

| Transition | Required result |
|---|---|
| Render start / repeated start | Correct current data; unchanged cache reuse where baseline allows |
| Render finish / abort | Renderability flags restored; transport follows defined cleanup lifecycle |
| Start/stop interactive rendering | No overlapping builds, stale data or lost restart state |
| Save / reopen | Disposable transport is not persisted as artist scene content |
| Reset / open / merge | No references to old scene nodes, arrays or background work |
| Delete/clone controller or source | Correct ownership and source invalidation; user nodes preserved |
| Undo/redo | User edits/scene state retained; caches invalidated as required |
| Headless/batch rendering | CPU path loads without optional GPU runtime; no UI or viewport dependency in preparation |
| Allocation/particle validation failure | Deterministic error, restored flags, no partial render state or orphaned owned nodes |

Farm/headless checks require actual installations and renderer licenses; source review does not establish them. Performance work should not silently implement the separate licensing roadmap.

## Memory and scalability

Record matrices in script/native arrays, PFlow data/operator overhead, copied prototypes, prepared surface data, undo state and renderer translation. Separate retained and transient memory; check repeated build/clear cycles for growth.

Apply the 32 GB envelope from [11](11_Platforms_and_Minimum_Requirements.md). More RAM permits larger scenes but does not fix repeated work or guarantee faster preparation. Report instance count together with source complexity, layer/source-group count and renderer configuration.

## Deliverable and gate

Each render test bundle includes a fixed low-resolution image comparison, particle/source/transform checks, preparation breakdown, node-ownership/cleanup report and memory peak. Renderer noise may require fixed seeds or image tolerance, but exact placement/transport checks remain separate. Accept R01/R02 only under the common gates in [02](02_Baseline_and_Benchmarks.md) and [03](03_Compatibility_and_Regression.md).
