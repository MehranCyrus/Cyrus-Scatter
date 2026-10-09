# Cyrus Scatter: 0.59, 0.64 and 0.74 compared

9 October 2026. Read-only product review requested by the artist. The artist confirmed **0.59 is the original baseline**, and 0.64 is the performance milestone. Current source is `cedaf78e3c4bd9fe5be39f7e070bac841b6b626d`, branch `codex/ui-0.74`.

## Verdict

**We made real engineering improvements, but the artist workflow did not improve consistently.** Returning everything to 0.59 would discard substantial measured viewport/calculation improvements and useful new painting/failure-handling capabilities. Keeping every later abstraction would also be a mistake: the mandatory paint-set model made ordinary scattering harder to understand, and some recent UI work restored controls that the original already had.

**0.64 is the strongest historical reference for the original workflow with the major performance improvements.** That does not certify it as the most reliable release or prove it is faster than current 0.74. Today’s 0.74 is a better foundation for the requested layer/surface/painting workflow, but it remains unfinished. Preserve the engine gains; use the original’s direct workflow as the usability reference.

## What was actually compared

| Baseline | Verified identity and use |
| --- | --- |
| Original 0.59 | `_local/archives/Cyrus Scatter.zip`; its generated script exactly matches `dist/CyrusScatter-0.59-Max2027.mzp`. Inspected native source, generated UI, ownership, redraw, update and failure paths. |
| Instrumented 0.59 | `dist/CyrusScatter-0.59-PrePerformance-Max2027.mzp`. Its script differs by performance-tracing wrappers. This is the reference identified by the historical CPU benchmark, not the byte-identical uninstrumented ZIP script. |
| Performance 0.64 | First Git checkpoint `b757b0f`, plus `dist/retained-mesh-0.64/CyrusScatter-0.64-Max2027.mzp` and its dated measurements. The checkpoint includes subsequent UI work; do not assume its script equals the earlier 0.64 installer. |
| Current 0.74 | HEAD above and the October 9 layer/Paint Areas package. Inspected authoritative `unified-core.ms`, generated script and relevant native sources. |

Exact hashes, script sizes, package identities and independently recalculated historical medians are in [EVIDENCE.json](EVIDENCE.json). [audit.py](audit.py) reproduces that receipt from the local archives and tracked evidence. No new Max run, installation, computer use, product edit or Git push was performed. Pre-existing research/website changes were left alone.

## The changes that clearly helped

### Calculation and viewport performance

The strongest evidence comes from the performance work leading to 0.64. These are different, carefully scoped experiments, **not one end-to-end 0.59-versus-0.74 benchmark**.

| Historical measured operation | Before | After | What it establishes |
| --- | ---: | ---: | --- |
| Heavy-scene full refresh, base state, 0.59 reference → 0.60 | 4,053.01 ms | 1,060.39 ms | About 74% less synchronous calculation/preparation time in that scene; recorded ordered output parity. |
| Point Cloud camera/redraw step, old drawing → retained path in 0.63 | 77.462 ms | 21.836 ms | Less CPU-side redraw work using the same candidate’s point data; 270 samples per arm. |
| Mesh camera/redraw step, 842,324 accepted triangles, old → retained path in 0.64 | 278.071 ms | 15.344 ms | Substantial improvement with equivalent accepted geometry; 60 samples per arm. |
| Mesh camera/redraw step, 9,955,989 accepted triangles | 3,163.390 ms | 16.941 ms | Same mechanism at a larger tested workload; 45 samples per arm. |

I verified the three viewport CSV hashes against their frozen manifests and recalculated their medians. The saved CPU result also matches its recorded hash. Sources: [CPU implementation evidence](../Performance_Evidence_2026-10-01.json), [CPU decisions](../Performance_Roadmap_2026-09-28/09_Results_and_Decisions.md), [Point Cloud results](../Retained_Point_Preview_2026-10-02/RESULTS.md), [Mesh results](../Retained_Mesh_Preview_2026-10-02/RESULTS.md).

These are CPU refresh or synchronous redraw timings, not presented FPS. The viewport experiments switch old/new backends within their measured candidates; they do not compare entire old/new installations. Current source retains the native retained-publication path (`src/preview.cpp`, `cyrusRetainedPublish`) and corresponding script bindings. We should keep this work. These historical numbers do not prove that every current 0.74 operation is faster.

### Useful capabilities added after 0.64

- **Surface painting:** 0.59’s script has spline/Line strokes but no native surface Brush document workflow. Current 0.74 supports optional named areas on individual receivers, including plane and sphere within one layer. Multiple strokes edit the selected area.
- **Layer-owned surfaces:** 0.59 explicitly copies the controller’s receiver list into every layer. Current new layers own their receiver lists, allowing grass and rocks to use different targets in one setup.
- **More explicit collision and population calculation:** current procedural evaluation separates collision relationships, bounded retries and accepted output, with diagnostics. This is more capable, though its artist presentation still needs simplification.
- **Failure retention:** original `refreshPreview()` clears the cache before work and leaves it empty on an exception. Current evaluation stages results and retains the previous complete publication when the successor fails. This is a substantive reliability improvement, within the tested contracts.
- **Source containers and shared editing views:** useful for larger model palettes; current label/color editing identifies sources without renaming the scene object. Containers also add lifecycle/Undo complexity, so their existence alone is not a quality metric.

Current painting evidence and remaining scope are recorded in [the October 9 report](../Layer_Paint_Areas_0.74_2026-10-09/README.md). Stable Edit identities, count/density, model colors, layers, Manual/automatic update and multiple receivers **already existed in 0.59**; they should not all be counted as new inventions.

## Where the original was better, or later work introduced costs

| Area | Original 0.59 | Later/current state | Assessment |
| --- | --- | --- | --- |
| Receiver list | Visible multi-select list, viewport pick, Select From Scene and remove selected rows | Earlier 0.73/0.74 workflow made the list less direct; 0.74 restored it | This was partly recovery of lost usability, not a new capability. |
| Ordinary scatter ownership | Layer settings and sources, shared controller surfaces; no mandatory painting concept | Intermediate versions made paint sets own models and population shares, even without brushing | Original was easier to explain. Current optional Paint Areas move back toward a clearer model. |
| Advanced UI | Already many controls and nested dynamic rollouts | More views, terminology and interactions; resize/selection callback bugs were delivered and later corrected | Neither baseline is automatically a good UI. More features increased the regression surface. |
| Existing scenes | Original schema and settings | Unified 0.73 deliberately rejects old unpublished schemas; current 0.74 does not convert 0.59/0.64 setups | A real continuity cost. Current is not a drop-in replacement for original scenes. |
| Relax/spacing semantics | Original accepted-output and blocker behavior | Replaced by ordered procedural scopes; Relax acts on the candidate pool before final filtering | Useful redesign, but different results/semantics, not simply faster original behavior. |
| Reliability confidence | Smaller authoring model, but source already contains fragile nested layout and cache-clearing failure paths | Broader verification, yet known cold container Undo and UI qualification gaps remain | No evidence supports declaring either version universally more reliable. |

Direct original-source anchors: `AminScatterObject.ms:139` starts the receiver rollout, `:11151` starts preview rebuild, `:11213` starts shared-surface synchronization. These refer to the frozen ZIP script, extracted read-only for this review under `build/historical-comparison-20261009/AminScatter/scripts/`. Current ownership/failure paths are in [unified-core.ms](../../AminScatter/tools/ui/templates/unified-core.ms), especially `addPaintArea`, `setPaintAreaTarget`, `procAssertSchema` and `evaluateProcedural`.

The current generated script has **20,953 lines versus 11,734 in the original ZIP**. This indicates a larger maintenance surface; generated/repeated views account for part of it. Line count is neither a speed measurement nor proof of bad design. The current generator also contains old workflow-help wording about paint sets/background references; the simplified UI has not yet been reconciled everywhere.

## Problems the new version has not solved

1. **Adding receivers can move established plants.** The aggregate triangle-area sampler is present in both original and current native source. The October 8 test moved 7,466 of 10,000 positions when adding receiver 21. The latest ownership change did not replace this sampler. It is an inherited architectural limitation, not evidence that the original was stable. [Reproduction/report](../Receiving_Surface_Research_2026-10-08/README.md).
2. **Brush history remains in storage.** Removing the stroke editor simplified the UI, but did not implement final-region storage. Recent native acceleration is useful; field construction and full input-to-feedback latency still require work. Do not describe that feature as finished.
3. **High-count Proxy draw cost remains.** The historical 100k 0.73 fixture measured about 1,242 ms per synchronous step in Proxy while Mesh/Point Cloud were near 32–33 ms. Different display contents make this a bottleneck indicator, not a universal mode speed ranking. [Results](../Unified_System_0.73_2026-10-06/RESULTS.md).
4. **Cold container Undo, full UI/DPI/tablet acceptance and broader runtime qualification remain open.** Passing scripted callbacks does not prove that the artist’s physical interaction is smooth. [Qualification findings](../Full_Qualification_0.73_2026-10-07/RESULTS.md).
5. **Older multi-set 0.74 conversion remains unfinished.** Those records contain independent models/budgets; they are not merely paint regions that can be silently merged.

## Recommendation

Do not roll the whole project back. Preserve 0.59 and 0.64 as references and keep the current retained display, bounded calculation, last-complete-result behavior and receiver-bound painting. Make the basic workflow as direct as possible:

**Layer → Surfaces → Models → Amount → Generate. Painting is optional.**

Prioritize stable receiver sampling, a measured Brush storage/feedback design, reliable Undo and consistent UI wording before adding more feature families. Treat this as consolidation of the current foundation.

If we need to decide which complete version performs best today, the next acceptance is a fresh matched 0.59/0.64/0.74 campaign: equivalent fresh recipes and assets, accepted/shown geometry parity, cold/warm Update, relevant edit, unchanged navigation, Manual pending edits, save/reopen and failure recovery. Old-scene schema rejection makes simply opening one 0.59 setup in 0.74 an invalid performance comparison. Brush must be evaluated separately because 0.59 had no equivalent surface-brush feature.

**Evidence-backed answer:** 0.59 was clearer in several basic interactions; 0.64 made proven performance improvements; 0.74 adds valuable capabilities and stronger calculation contracts, but has not yet earned a claim of being the better finished product in every respect.
