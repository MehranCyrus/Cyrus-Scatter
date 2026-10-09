# Receiving surfaces, placement stability and painting

8 October 2026. Research and recommendations only. Cyrus product code and installed plugins were not changed. No implementation, installation, release certification or vendor performance ranking is claimed.

## Decision for the artist with 20 surfaces

**Adding a distant surface should preserve established placements on unchanged surfaces in Density mode.** Generate the new surface's population, then revisit only dependencies that can actually affect it. A global fixed total has different semantics: giving surface 21 a share must reduce the shares on the old surfaces, unless the total grows. Preserve the positions of surviving instances rather than remapping the entire population.

This is a proposed Cyrus contract, not a recovered Forest or Chaos guarantee. The strongest new evidence is a controlled Cyrus experiment: adding a distant receiver moved **7,466 of 10,000** existing candidate positions in both Fixed Count and Density. Reordering moved all 10,000. Restoring the original receiver list restored every original transform. The current combined-area sampler explains this behavior.

We learned useful vendor mechanisms and workflow distinctions, but **did not obtain valid vendor before/after placement captures**. Their isolated host requests stayed RUNNING. Neither a vendor stability advantage nor incremental vendor placement processing has been demonstrated.

## Evidence and identities

Labels used below:

- **Documented:** official vendor intended behavior; not necessarily qualified in this installed build.
- **Observed in Max:** successful controlled experiment in the isolated host.
- **Supported by binary inspection:** bounded reconstruction of a hash-pinned compiled module; not original source code.
- **Source inspection:** current Cyrus implementation, checked directly.
- **Hypothesis/recommendation:** proposed behavior or an untested explanation.

Cyrus source: branch `codex/ui-0.74`, HEAD `65cf22e9f4ae38f0e20a8e30dff3189d796b3c3a`. The matching existing 0.74 package was extracted into an owned profile; no installer ran. Max was **29.1.0.11426 / 2027.1**. The source hashes and loaded Cyrus module paths were checked. The artist's separate Max process was not reset or edited.

| Input | Exact installed identity | SHA-256 |
|---|---|---|
| Forest core | `ForestPackLite2027/Contents/plugins/2027/ForestPackLite.dlo`; manifest 9.4.3, PE version 9,4,3,766; public API returns 900 | `23b25adf28954a4cd6c3d7fe5f7ea90b6a6e9be480f8a422fa7ef8b99c9a325d` |
| Chaos loader | `ChaosScatter3dsMax2027/ChaosScatterMax2027.dlt`; manifest 9.0.671707, PE version 15.0.671707 | See full receipt below |
| Chaos Max adapter | `ScatterMax_Release-2027.dll`; PE version 15.0.671707 | `f7fdd25428e8374174501e6bb4ebd3b83e21c5ba2c33fcdc94280c022695b887` |
| Chaos calculation core | `ScatterCore.ForScatter_Release.dll`; PE version 15.0.671707 | `069ababd0dbc09218928f24d5bdc860509b237f34af703581e3fd78ed5d3cf86` |
| Cyrus package | `dist/UI_Grip_Fix_0.74_2026-10-08/Max2027/CyrusScatter-0.74.0-Max2027.mzp` | `332968fadc294cbe22e78e167cc04ee139b4341da5cd2edf83a4fe18dc05290e` |

Vendor paths are beneath `C:/ProgramData/Autodesk/ApplicationPlugins/`. Chaos's public API reports **9, build timestamp May 25 2026 14:02:33**. Its API/manifest and PE version resources differ; both are retained rather than treating either as the sole identity. [EVIDENCE.json](EVIDENCE.json) contains absolute paths, all seven input hashes, package payload hashes, source hashes, exact comparisons and reproduction-script hashes.

Ghidra 12.1.4, ghidra-mcp 6.0.0 and Java 21 were already available. No additional GitHub tool installation was needed. A new loopback backend and `ReceivingSurfaceCore` project analyzed copied Chaos core bytes; existing tyFlow projects were preserved. Eleven question-selected functions completed decompilation with decoded bytes covering their analysis-defined bounds. Private listings remain under ignored `build/receiving-surface-research-20261008-02`; no vendor implementation was copied into Cyrus.

## What happened in Max

**Observed in Max.** Fixture: twenty separate 100 × 100 cm planes, two equally weighted identifiable models (box and sphere), seed 42, 10,000 candidates. The added plane was identical and distant. Density was 500 candidates/m². Near placement moved the added plane to overlap the first. The unequal-area fixture used three 100 × 100/200/300 cm planes, count 600 or density 100/m². Explicit `evaluateGroups()` calls constitute requested evaluations; these tests do not qualify automatic Live scheduling.

| Change | Population before → after | Same positions among matching IDs | Same basis / model assignment |
|---|---:|---:|---:|
| Repeat unchanged fixed recipe | 10,000 → 10,000 | 10,000 / 10,000 | 10,000 / 10,000 |
| Fixed Count: add distant surface 21 | 10,000 → 10,000 | 2,534 / 10,000 | 10,000 / 10,000 |
| Remove added surface; restore original list | 10,000 → 10,000 | All original positions restored | All restored |
| Reverse receiver order | 10,000 → 10,000 | 0 / 10,000 | 10,000 / 10,000 |
| Move receiver 1 upward by 100 cm | 10,000 → 10,000 | 9,509 / 10,000 | 10,000 / 10,000 |
| Density: add distant surface 21 | 10,000 → 10,500 | 2,534 / 10,000 | 10,000 / 10,000 |
| Move surface 21 from far to overlapping | 10,500 → 10,500 | 9,989 / 10,500 | 10,500 / 10,500 |
| Density: increase receiver 1 width by 50% | 10,000 → 10,250 | 4,989 / 10,000 | 10,000 / 10,000 |
| Density + 5 cm self-spacing: add far surface | 3,417 → 3,567 accepted | 670 / 2,627 shared surviving IDs | 2,627 / 2,627 |
| Same spacing: move surface 21 near | 3,567 → 3,452 accepted | 3,316 / 3,417 shared surviving IDs | 3,417 / 3,417 |

Comparisons were performed in Max against cloned full-precision rows, matching candidate IDs. Exported text matrices are supplementary, rounded human-readable records. Basis equality includes scale; it is not a separate normalized-rotation measurement. Both models were used: the density baseline contained 4,998 boxes and 5,002 spheres. Stable IDs here are candidate ordinals, **not proof of a persistent association with a particular receiver or location**. The plane fixtures do not establish the same basis/model result for normals, world-space clustering or projected random movement on complex terrain.

Two preservation checks also succeeded:

- Painted single receiver: 591 accepted instances. Adding a second receiver rejected evaluation with the receiver-mismatch error. The previous snapshot, document and target were retained; restoring the original receiver restored the identical fingerprint.
- Two receivers plus manual instance transforms: adding a third rejected the changed CS Edit binding. The previous edited snapshot survived, and restoring the receiver list restored it exactly. This is safe failure behavior, not seamless multi-surface editing.

**Performance is separate.** The final campaign measured a single synchronous `evaluateGroups()` call per capture: unchanged repeat 8 ms; fixed add 58 ms; reorder 60 ms; density add 203 ms; spacing cases 64–69 ms. These are coarse, single-run host-call observations including synchronous preparation/evaluation/publication work. They exclude TSV export and are not comparative benchmarks. OS/host activity and asynchronous work were not controlled. Preparation counters increased for changed recipes; the unchanged repeat retained its publication epoch. Geometry preparation, candidate generation, filtering, collision time, GPU upload and drawing were **not independently timed**. No presented FPS claim is made.

### Vendor experiment boundary

**Observed in Max, inconclusive for placement behavior.** A separate profile successfully created both vendor objects and exposed properties/interfaces. A Chaos fixture with three unequal receivers and two models remained RUNNING in explicit `FpInterface.update (interval 0 0) 0`. A fresh profile avoiding that update remained RUNNING at Forest's receiving-surface configuration checkpoint, covering `surflist` and area-activation setters. No before/after transforms were obtained. A UI capture failed to represent the owned host reliably; no guessed dialog interaction was attempted. The owned stalled hosts were stopped only after checking their executable and private-profile arguments.

The cause is unresolved: automation context, a modal prompt, configuration or plugin behavior are possibilities. This is **not evidence that normal vendor workflows fail, that licensing caused the stall, or that either plugin is slower**. Forest Lite also cannot qualify every Pro feature. The official [Lite/Pro comparison](https://docs.itoosoft.com/forestpack/lite-and-pro) distinguishes those editions; the extracted text loses graphical checkmarks, so it is not used as a reliable machine-readable capability matrix.

## What the vendor evidence does establish

**Documented — Forest.** Its [Surfaces documentation](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces) describes a terrain-preparation table shared between Forest objects, manual refresh and optional Auto refresh. XY mode establishes positions in the Forest object's plane and projects them along Z; UV mode follows surface mapping. Shared terrain preparation does not establish shared placement caches or incremental population updates. A useful **hypothesis** is that an unchanged XY sampling field could keep its old points when its coverage expands, but changes to bounds, maps, seed or stacked surfaces may defeat that. It remains untested.

Forest [Image distribution](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode) uses a distribution field whose scale controls density. Its Max Density bounds potential positions, including empty pixels; it is not Cyrus's fixed total allocation. Do not equate its viewport/render limits with a requested population count.

**Documented — Chaos.** [The Max reference](https://documentation.chaos.com/space/CRMAX/124525180/Chaos%20Scatter) separates targets and models. Target Factor is a relative allocation weight for Count and a multiplier for density. Model Frequency is relative. Temporal consistency concerns a rest pose across animation, not adding targets. Disabling automatic updates still allows Scatter-parameter changes to recompute. None is a documented guarantee that adding target 21 preserves prior placements.

**Supported by binary inspection — Chaos core.** The selected target-index getter resolves a core instance and reads a target index. Exported APIs also expose target triangle/surface locations, placed-instance preservation data and overrides. The selected ID-generation function combines configuration and target-associated values with a **global ordinal in the low 32 bits**. Receiver metadata exists, but global ordinals are relevant to edit stability; no receiver-local stability guarantee follows. The random-generation path distinguishes configured quantity from measure-scaled quantity. Its selected receiver-preparation wrapper iterates supplied receiver records; internal reuse inside the helper remains untraced. Capacity reuse in an instance buffer is not proof that placement computation was skipped.

**Supported by prior binary inspection — Forest.** [The brush investigation](../ForestPack_Research_2026-10-08/brush/NATIVE_FINDINGS.md) found closed contour persistence, union/subtraction operations, spline interchange and host Painter callbacks. [Earlier native findings](../ForestPack_Research_2026-10-08/NATIVE_FINDINGS.md) support CPU preparation and retained instanced display. Neither pass traced per-receiver placement-cache invalidation or measured changed-surface GPU upload. Do not promote these findings into an incremental-update claim.

## Comparison and recommended ownership

The vendor cells combine the documented contracts above with labelled binary support; unknown runtime results remain unknown.

| Concern | Forest | Chaos | Current Cyrus | Recommended Cyrus |
|---|---|---|---|---|
| Density / receiver addition | Image field and XY/UV projection; stability untested | Count/density and target factors; stability untested | Combined-area count and sampling; old points remap | Receiver-local candidates and counts; unchanged domains retain placements |
| Fixed total | No equivalent established in inspected Image mode | One Count with relative target weights | One layer total allocated across combined area/sets | Allocate receiver quotas; retain surviving candidate positions |
| Receiver reorder | Unqualified; stacked-surface behavior matters | Unqualified | Changes positions and aggregate edit binding | Membership order must not change ordinary sampling; explicit order only where semantic |
| Preparation cache | Shared terrain table documented | Per-target metadata; cache scope unresolved | Leaf prepared rows and setup publication; combined input keys | Share immutable receiver preparation; cache population results separately |
| Models | Object Geometry list; optional area subset | Main models plus frequency; painted-layer selections | Sets own sources; parent owns shared population settings | Layer model pool with explicit regional subset/override |
| Region painting | Include/exclude area contours | Clustering paint layers as well as direct brush instances | Single-receiver document filters candidates; sets can also scatter without paint | Region belongs to a receiver/domain; inherit layer models by default |
| Direct editing | Separate Custom Edit workflow | Instance edits and added painted instances | CS Edit delta records with generation-binding guard | Persistent receiver + population + candidate identity; deliberate orphan policy |
| Changed placements and display | Retained instancing supported; changed-buffer reuse unknown | Changed-buffer/source reuse unknown | Unchanged generation reused; changed generation recreates render items | Reuse unchanged source geometry and unaffected placement buffers if measurements justify it |

Forest [Areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas) paint include/exclude coverage in XY mode, can select a subset of object models, and use ordered exclusion. Paint/spline conversion and boundary density/scale falloff are documented. That supports separating a **region** from the **population it controls**. It does not establish a complete mathematical rule for overlapping includes, item ownership or Undo under receiver replacement.

Chaos has two distinct painting workflows: clustering paint layers cover layers beneath; each has model selections. The direct instance brush adds/erases instance records, with rule-following options and a separate painted count. Erasing a layer reveals lower layers; deleting the base promotes another layer and discards its paint. These are documented workflows, not a complete recovered storage/Undo contract. The native adapter/core independently support stroke/layer records and placed-instance overrides. Our installed runtime behavior remains unqualified.

Current Cyrus sets are more than paint areas: they own models, eligibility and allocation weights and work without strokes. Renaming or relocating the existing controls alone would hide real responsibilities. [The ownership discussion](../Product_Discussion_2026-10-08/MODELS_AND_PAINTING.md) remains a design proposal.

## Architecture recommendation and tradeoffs

1. **Separate receiver preparation from population sampling.** Key copied geometry/projection data by persistent receiver identity, relevant geometry/transform/UV/time revisions and preparation options. Let layers share it. Keep bounded memory, host-thread extraction and worker-only copied data. A change notification should mark specific stages dirty rather than immediately rebuilding everything.
2. **Use stable candidate streams per population and receiver.** Receiver membership and list order should not change the random domain of unchanged receivers. Include persistent receiver identity in candidate identity; independent random channels keep placement, transform and model choices separate. Record anchors for movement/deformation, with a defined fallback when topology changes. Stable IDs are necessary but insufficient: today's unchanged IDs still move.
3. **Density:** calculate each receiver's contribution independently. Adding a distant receiver generates its candidates and leaves old ones intact, subject to relevant shared constraints. Removing one removes its contribution. Moving one updates its anchors and affected spatial dependencies. Editing area/topology may change that receiver's population; preserving arbitrary anchors through remeshing needs a deliberate policy.
4. **Fixed Total:** use deterministic weighted receiver quotas and stable prefixes within each receiver. A new receiver reduces old quotas; delete surplus candidates without moving survivors. Rounding can change a small number of quotas elsewhere. A separate artist lock could preserve established content, but must explicitly say whether the total grows or only unlocked content yields. Do not promise an unchanged total, new instances and preservation of every old instance simultaneously.
5. **Collisions:** keep the current explicit self/set/layer scopes and ordering. A far receiver may be independent only after accounting for source extents, movement and collision reach. For nearby receivers, revisit the affected collision component and dependent later populations. Ordered greedy acceptance can propagate along a chain; a naive fixed-radius refresh may be incorrect. Global relaxation, accepted-target refill, global clustering and shared masks can justify wider recomputation. Preserve deterministic results and atomic publication first.
6. **Paint:** default to optional region coverage, with optional boundary fade evaluated from the region and curve. Hard borders require no fade. Density thinning and scale taper are distinct controls. Choose restrict/replace/add behavior explicitly; union overlapping coverage without accidental double population, unless a separate additive population is requested. Keep direct instance edits as a separate tool. Multi-surface paint needs receiver-tagged regions or an explicit XY projection domain; a single untagged contour cannot distinguish stacked surfaces.
7. **Edits and Undo:** store immutable receiver/population/candidate identities and preserve authored records when a receiver is removed. Define whether they become inactive orphan records, move with the receiver, or require an explicit rebind. An atomic Undo should restore membership, associated regions/edits and the prior complete publication. This extends the current safe binding guard; it must not silently apply an old delta to a different location.
8. **Display:** retain today's no-work behavior for unchanged publications. Source inspection shows changed Cyrus generations create new MeshItems, each realizing source vertex streams and instance matrices. That establishes a concrete candidate for improvement, not a measured bottleneck. Measure geometry extraction, candidate/filter/collision phases, upload bytes and draw separately before building a shared model-buffer cache or receiver chunks. An unaffected receiver's placement cache and a model's geometry cache have different owners.

This needs focused engineering, not a promise of a cheap drop-in replacement. Per-receiver quota boundaries and RNG domains change the existing recipe's output once. More caches consume memory and require dependable revision keys. Preserving placements can conflict with globally optimal collision packing; the artist must know which contract takes priority. Start with ordinary random Density and Fixed Total behavior, then qualify painting, deformation and dependent collision populations.

## Remaining acceptance work

Vendor normal-UI fixtures are still required for add/remove/reorder/move/edit in both available modes, full transform/model exports, stacked receivers, animation, direct edits and painting. Diagnose the isolated API stalls without touching the artist session; do not reuse a RUNNING transport or assume timeout cancels it. Vendor native-ID stability, cache invalidation scope and changed-buffer reuse remain unresolved.

For a Cyrus implementation, accept only after distant 20→21 Density preserves every unchanged receiver's placements and edits; Fixed Total removes only quota surplus; reorder is invariant; nearby collision propagation remains correct; failed successors retain the prior result; Manual/Live scheduling, Undo/save/reload, source geometry reuse and separate stage measurements pass. Test larger and complex meshes after these correctness contracts, not as a substitute for them.

In plain language: **your established grass should not shuffle because you added another patch of ground.** Density can simply add that patch's grass. A fixed total must share the same budget across more ground, but surviving grass need not move. Forest and Chaos provide useful patterns for regions, targets and edits; our measured Cyrus issue can be addressed on its own evidence.

See [reproduction](reproduce/README.md) and [machine-readable evidence](EVIDENCE.json).
