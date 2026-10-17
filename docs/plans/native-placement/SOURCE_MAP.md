# Source findings and comparison

Source inspected on 17 October 2026 against the dirty 0.85.4 workspace identified in [EVIDENCE.json](EVIDENCE.json). Anchors below are symbols; recorded line numbers are navigation aids and can move. This is source evidence, not newly executed Max behavior.

## Current placement route

| Stage / owner | Current source | Finding and migration boundary |
| --- | --- | --- |
| Root admission and requests | `unified-core.ms`: `evaluateProcedural`, `procPlanReceivers` | Plans receiver quotas/schedules, caps root work, reserves script workspace and brackets Edit mutation/publication. Keep current ordering and admission semantics |
| Native generation | `src/max_bridge.cpp`: `scatterAdvanced`, `cyrusScatterCanonical`; `include/scatter.h`: `Instance` | Uses native `std::vector<amin::Instance>` then creates an Array, Matrix3 and identity/anchor fields for every returned placement. This is the first major native-to-script boundary |
| Receiver cache | `unified-core.ms`: `cspImpl_placements`; `src/receiver_bridge.inc`: `cyrusReceiverOffsetRows` | Per-receiver script row caches are joined into a layer base. Zero face offset now shares rows; other offsets must retain exact face correspondence |
| Grid | `src/grid_bridge.inc`; `procGridCache` | Already retains native grid snapshots and native schedule values. Reuse projected anchors/identity domains; do not replace the grid algorithm |
| Eligibility and scale | `src/mesh_density_bridge.inc`, `src/boundary_falloff_bridge.inc`; `applyAnalyzerArea`, `applyFalloff` | Existing numerical paths are wrapped in row conversion; masks and transform order need parity witnesses |
| Paint | `src/brush_host.cpp`: `cyrusBrushRegionFilter`, `cyrusClonePlacementRows`; `procApplyPaint` | Paint returns copied rows/matrices with receiver-bound coverage. Even disabled Paint clones matrices before later mutable transforms. Deleting that copy without changing ownership would be unsafe |
| Orientation / source transforms | `src/direction_orientation_bridge.inc`: `cyrusOrientSurfaceRows`; `max_bridge.cpp`: `cyrusApplySourceTransforms` | Orientation converts through native instances and new script rows. Source transforms already mutate their validated transient matrices in place; they are not another whole-array copy to claim as a new saving |
| Preparation and Edit | `procPrepare`, `CyrusEditApplyLayer`; `src/cyrus_edit_stack.inc` | No-modifier path creates edited ID strings/row shells while sharing matrices. Active path converts through `EditInput`, changes Edit maps and emits rows |
| Surface eligibility | `src/surface_filter_bridge.inc`: `cyrusSurfaceFilter` | Post-Edit filter preserves protected edits and returns kept row references. Keep formulas/validation unchanged; adapt transport only |
| Container source filtering | `containerFilter`, `cyrusFilterSourceRows` | Removal-only source filter returns row references; native index selection can replace script pointer lists |
| Radius / collision | `src/procedural_bridge.inc`, `include/procedural.h`, `src/procedural.cpp` | Radii already use compact native Float32 pairs. Spacing bridge creates string-keyed schedule maps and copied `Sample` data; solver returns accepted indices, bridge builds script kept-row arrays |
| Publication | `evaluateProcedural`, `procStagePublication`, `procResultState`, `procRestoreResult` | Script retains root/leaf prior state, stages all displays, installs one coherent epoch, commits native Edit last; failures restore the previous complete state |
| Display | `procStagePreview`; `src/preview.cpp`, `src/geometry_preview.inc`, `src/point_publication.inc` | Script scans used sources; native display builders read row Arrays. Existing immutable Point/Mesh generations and buffer reuse are reusable infrastructure, not work to replace wholesale |
| Radius overlay | `cacheRadii`, `cyrusBuildInspectionPreview` | Radius-ring geometry still crosses a script-array boundary. Include this derived representation in the audit; placement radii being native does not make rings native |
| External inspection | `procPublicationInfo`, `procPublicationPage` | Cached epoch-bound pages already cap responses at 500 rows. Keep this public contract; materialize only the requested page |
| Exact output | `groupPlacements`, `bakeInstances`, `CyrusPFBuild` | Bake iterates script rows; PFlow groups every accepted transform in `CyrusPFData`. Moving the main generator alone does not remove this later allocation |

All controller symbols above are in [the authoritative template](../../../AminScatter/tools/ui/templates/unified-core.ms), not an invitation to edit only the generated script. Native sources are under [AminScatter/src](../../../AminScatter/src). The exact eight-field representation is [placement_transport.h](../../../AminScatter/include/placement_transport.h).

### Numerical and identity traps

1. The pure solver's `amin::Instance` stores doubles. Existing bridges round through Max Matrix3/Point3 floats at multiple stages. Removing those boundaries while keeping all intermediate doubles can change threshold decisions and transforms. Preserve old rounding points deliberately until parity is established.
2. Raw identity is a numeric receiver/candidate key; edited output identity is a string, including authored copies. Neither source-row position nor accepted index is an identity. Native numeric tagging must round-trip existing output strings exactly.
3. An anchor face plus barycentric coordinates is a locator, not persistent identity across remeshing. Receiver slots, variation domains, Band owner, source correspondence and publication epoch remain distinct.
4. Current removed-row stages often share existing rows. A memory forecast must count unique storage, pointer arrays and native copies separately; multiplying the number of function calls by a full-row size is wrong.
5. `cyrusPreviewPlacementsEqual` compares render-relevant transforms/source/Band owner, not every identity field. Preserve the distinction between display reuse equivalence and full publication parity.

## Undo is several mechanisms

| Mechanism | Verified source behavior | Design implication |
| --- | --- | --- |
| Ordinary Count/parameter edit | `countSpin changed` uses an authored Undo hold; `AminScatterLayerUndo` requests refresh under existing Manual/Live rules | Do not invent mandatory before/after placement snapshots for every scalar edit |
| Calculation rollback | `ProceduralEditTransaction` copies each modifier's entire `std::map<int,EditLayer>` before preparation | Native immutable derived state could replace expensive rollback copies |
| Artist CS Edit history | `EditRestore` copies the full map into `before`, and into `after` on Undo. `EditLayer` includes row strings/deltas, input matrices, source arrays and published IDs | Already native but potentially expensive; cost must be measured independently from script transport |
| Preset Load publication | `PresetPublicationRestore` retains before/after `ValueHolderMember` references across a list of transient fields | Keep exact ready-preset restoration without file access/re-solving; migrate ownership without losing history |
| Abandoned imported setup | `ImportedCacheLifetime` drops transient locals only when the undone creation is discarded and not live | Preserve this release boundary; being invisible/deleted does not prove no owner remains |
| Paint | Native authored document and its own history | Preserve Paint's established document/history contract; do not turn every stroke into an entire placement snapshot |

`EditRestore` and `PresetPublicationRestore` do not currently override `RestoreObj::Size()` in the inspected definitions. Thus their payload is not explicitly accounted there. This source observation does not prove a leak or explain all host trimming. N07 requires actual retained-byte and Max history observations.

Saved Edit data in `cyrus_edit_storage.inc` includes identity rows, deltas, deleted/selected flags, source ordinal and binding signature. Derived input matrices/source arrays are not serialized there. This permits a transient ownership change without automatically requiring a saved scene format change; sparse omission of historical identity rows needs separate semantic and format analysis.

## Module ownership

`AminScatter` compiles `script_buffers.cpp`, Edit implementation and the display code. `CyrusScatterEdit` is a class-registration shim linked to AminScatter. `CyrusBrush` is a separate module, with `CyrusBrushStorage` its registration shim. The shared static numerical library is linked into multiple modules.

A process-wide placement store must not accidentally be instantiated once in each statically linked module. Proposed owner: AminScatter, using explicit versioned exported retain/release/read operations for the Brush adapter. Do not pass ownership of STL containers across module boundaries casually or introduce a new DLL without need. Test full module loading, destruction and exact-pair rejection. Current licensing links are not a substitute for an unconditional placement API dependency.

## Forest evidence: useful but bounded

Read the existing [memory summary](<../../../../Forest Reverse/research/forest/73_MEMORY_UNDO_SUMMARY.md>), [script boundary audit](<../../../../Forest Reverse/research/forest/75_MAXSCRIPT_NATIVE_BOUNDARY.md>), [Undo ownership](<../../../../Forest Reverse/research/forest/76_UNDO_SNAPSHOTS_AND_LIFETIMES.md>) and [cache/memory costs](<../../../../Forest Reverse/research/forest/77_MEMORY_LIMITS_AND_CACHE_COSTS.md>).

Those reports inspect Forest **Lite 9.4.3**, file version `9,4,3,766`, SHA-256 `23b25adf28954a4cd6c3d7fe5f7ea90b6a6e9be480f8a422fa7ef8b99c9a325d`. They contain selected static binary evidence; this planning task did not independently repeat decompilation or run Forest. Pro equivalence and full low-memory behavior remain unverified.

The selected generation paths use native item containers; indexed queries do not assemble the entire population. This supports the direction of native bulk storage with bounded queries. It does **not** establish a particular pipeline graph, thread scheduler or immutable snapshot implementation.

The measured native item stride is 1,184 bytes, with selected 1,000-item chunks. Custom-item Undo owns two copied lists, and its reported Size is 24 bytes. Source sample eviction is a separate soft KiB budget and cannot be treated as placement/Undo/process memory admission. Some selected failures clear results; universal previous-result retention is not established. We should preserve Cyrus's stronger explicit failure-retention contract, not copy that failure behavior.

## Primary SDK references checked

- [Max 2027 RestoreObj](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_restore_obj.html): Restore/Redo may be called repeatedly; Size should approximate owned memory. The reference prose and inline default differ, so derive no exact default byte count from it.
- [Max 2027 Hold](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_hold.html): restore records join the host hold; Put reports failure when no hold is active. This does not prove Cyrus's particular delayed callback ordering.

These sources inform the proposed integration, not a claim that its tests have passed. Historical 2012 Undo-size warnings found during search are not current Max 2027 limits and are not used to set our budget.

## Retrieval and preservation

Full-source knowledge status checked 38 enrolled parents: 15 matched, 21 changed and 2 missing. Selected generation `44bb57523e1286764c655754ce79ed3e4299bce12c0c71b7c49b212258dfa0d3` is structurally compatible but stale. Identifier search `procEvaluateRoot` returned no entries (the actual root method is `evaluateProcedural`); no conclusion was inferred from that miss. Source/contract reads above are the fallback evidence. No index refresh or enrollment change occurred.

The pre-edit file inventory is under ignored `build/native-placement-plan-20261017-01/before.json`. Documentation validation and product-source preservation results are recorded in the inspection manifest after writing the plan.
