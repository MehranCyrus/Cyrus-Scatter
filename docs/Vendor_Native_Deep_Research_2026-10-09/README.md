# Deeper Forest / Chaos native research — 9 October 2026

**Yes: we reached deeper implementation logic. We did not recover either vendor's original source repository.** The existing Ghidra / Ghidra MCP tools exposed useful data layouts and executable paths in the installed native modules. The strongest new findings are Chaos's triangle-attached stroke representation and final distance test, receiver remapping, and Forest's source-sample lookup and eviction policy.

This builds on the [measured vendor surface/painting report](../Vendor_Surface_Paint_Research_2026-10-09/README.md) and [Forest contour research](../ForestPack_Research_2026-10-08/brush/NATIVE_FINDINGS.md). Those earlier results are not new tests in this pass. See the [native code map](CODE_MAP.md), [reproduction instructions](reproduce/README.md) and [identity/coverage receipts](EVIDENCE.json).

## What “deeper codebase” means here

Installed Forest Lite 9.4.3 and Chaos Scatter contain optimized native binaries. The two installation folders contain some scripts but no `.c/.cc/.cpp/.h/.hpp` source or `.pdb` files in the scoped inventory. Compiler type names, exported symbols, parameter-registration names, profiling labels and some original build-path strings survive. For example, a Chaos core string names `MeshScatter.cpp`; it does not make that source file available.

Disassembly lets us follow executed instructions. Decompilation produces approximate C-like output with inferred types and unreliable signatures. We validated important interpretations against assembly, Max SDK compile witnesses and a read-only scene probe. This yields a partial implementation map, not a rebuildable vendor project. No defensible percentage of the whole product understood can be calculated from function counts.

This pass inspected **42 distinct selected function bodies across three modules**, totaling **64,216 decoded bytes and 11,139 instructions** within the analysis-defined bounds. All 42 completed decompilation; the initial missing Forest comparator became a bounded leaf function in a later selection. These counts describe inspected bodies, not 42 fully understood algorithms or source-code coverage. Private listings and manifests remain under `build/vendor-native-deep-20261009-01`.

The working tools were already installed: Ghidra 12.1.4, [Ghidra MCP](https://github.com/bethington/ghidra-mcp) 6.0.0 and Java 21. We used copied analysis projects and localhost port 18091. No additional reverse-engineering tool was installed. IDA could provide another analysis view, but installing it would not restore absent source files or debug information.

## Observed behavior in this pass

An owned Max 2027 process, version `29.1.0.11426`, reopened the **previous disposable fixture**, through a separate profile. Its loaded-module receipt points to the hash-pinned installed vendor modules. The probe read public paint tables and took temporary mesh snapshots; it did not inject paint data or save over the fixture.

The saved Chaos object contained **5 points and 3 stroke records**, all referencing receiver ordinal 0. Their point counts were **1, 2, 2**, matching the full point table. Layer ordinals were **1, 2, 2**; operation values were **0, 0, 1**; all three radii were **20 scene units**. The receiver meshes had **32 and 528 faces**, but the retained records referenced only the flat receiver. The earlier curved stroke had already been discarded during the earlier remove/restore test.

The point table decoded to two unique anchors:

| Local face, zero-based | Barycentric u | Barycentric v | Independently resolved flat position, scene units |
|---|---:|---:|---|
| 19 | 0.0269197 | 0.0646967 | approximately `(-1.61742, 0.67299, 0)` |
| 12 | 0.0181109 | 0.00284912 | approximately `(0.071228, -0.452773, 0)` |

All five references addressed valid triangles and valid barycentric ranges. This corroborates the binary interpretation below. It is **not** a new curved-anchor, deformation, topology-change or timing experiment. Positions use ordinary MAXScript text precision. The flat receiver's transform was identity; this probe does not qualify reconstruction under arbitrary transforms.

The scene hash still matches the previous report. The Max probe completed successfully; it did not stall. Both owned Max and Ghidra processes were closed after analysis projects were saved.

## Binary evidence: Chaos's painting system

**Storage.** Parameter registration identifies `layerData` as a Point3 table and `layerRecords` as a Point4 table. The important distinction is that these are **packed transport containers**, not ordinary XYZ points and arbitrary four-float settings. Public point X/Y hold barycentric coordinates; public Z carries integer triangle-index bits reinterpreted as a float. Printing that field as an ordinary decimal previously made useful values appear as zero. `bit.floatAsInt` exposes the stored integer.

The adapter converts each point into a **12-byte internal record**: triangle index followed by two floats. It converts each stroke into a **20-byte record**: point count, receiver ordinal, layer ordinal, operation value and radius. In the public Point4, point count and receiver ordinal also use integer bits; the layer and operation share the packed Z field. These are reconstructed layouts, not recovered original C++ declarations.

**Anchoring.** The core adds the receiver's triangle-array base offset to the stored local triangle index. It reads three triangle vertices and resolves the point with the standard barycentric expression `A + u(B − A) + v(C − A)`. A stroke therefore carries mesh attachments. It is not merely a contour drawn in the global XY plane.

**Stroke queries.** The selected path builds bounds and a recursive spatial hierarchy around stroke segments. The membership path resolves their endpoints, constructs `STubularVolume` and invokes its exported `contains` method. Its fully decoded body tests ordinary three-dimensional squared distance to the endpoints and segment interior against radius squared. Endpoint spheres make a single-point stroke valid too.

This establishes a **capsule-style 3D brush footprint in the selected path**, rather than geodesic distance along mesh connectivity. It does not establish that every Chaos painting feature uses this path. In particular, whether this volume can affect an adjacent receiver, a folded mesh or the other side of a thin shell requires a controlled test. Attachment identity and membership scope are different questions.

**Ownership and model selection.** RTTI identifies `LayerDataImpl`, `StrokesEvaluator` and `ClusterLayersEvaluator`. The core resolves layer model handles against the available instance-model handles, builds model-index/frequency tables and uses stroke queries during model selection. This supplies a native explanation for the earlier observed behavior: painting changed assigned models while preserving all 400 base positions in that fixture. It does not prove independently generated populations per painted layer.

**Receiver changes.** The adapter keeps an ordered signature of receiving node references and evaluated face counts. SDK witnesses resolve the count field precisely: `TriObject.mesh` at `0xf8`, `Mesh.numFaces` wrapper at `0x168`, integer value at wrapper `+8`, totaling **`0x268`**. Native conversion code corroborates the TriObject interpretation.

The comparison searches for the same node reference in the new list and checks its face count. It produces old-to-new ordinal mappings, or a negative mapping for an affected entry. `onDistributionNodesChanged` passes that mapping to the stroke-remapping routine, which compacts surviving records/points and updates receiver ordinals. The same path can issue the topology warning seen in the previous host test. Deleting an affected receiver can therefore discard its paint attachments; restoring the receiver does not inherently restore discarded records.

This selected comparison is not a full topology signature. Same-face-count connectivity edits, different mesh ordering and deformation behavior remain unqualified. No persistent receiver UUID scheme was recovered.

## Binary evidence: Forest's projection and cache paths

The earlier Forest analysis established closed integer contours, circle union/subtraction, simplification and referenced `LinearShape` publication. The official [Areas reference](https://docs.itoosoft.com/forestpack/forest-plugin/areas) documents paint/spline conversion, ordered areas, model selection and separate density/scale falloff controls. These documented controls support keeping a boundary and an adjustable fade as separate concepts; their full native fade implementation was not recovered here.

**New projection detail.** Following the contour vertex-fill call reaches an XY triangle lookup. It bounds-checks XY, calculates/clamps a grid cell, walks linked candidate triangles, performs projected point-in-triangle tests, and returns the first successful candidate plus barycentric information. The caller accesses a prepared `TSurfXYArray`. This is evidence for a prepared spatial lookup, not a recovered universal receiver-assignment policy, highest-surface rule or geodesic painter. All native XY/UV placement and height/intersection cases remain outside the recovered subset. Official [Surfaces documentation](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces) describes XY projection and UV distribution; the installed Lite flat-surface restriction still prevents qualifying curved Forest painting.

**New sample-cache detail.** We recovered the previously missing eviction comparator. It sorts by a 64-bit per-sample timestamp in ascending order. The sample lookup returns an existing entry when its validity interval contains the requested time, updates that timestamp through `_time64`, and returns its shared owner. A miss takes a construction path instead. Eviction walks the oldest timestamps first and checks whether an entry can be released; entries still referenced can remain.

This is strong native evidence of **source-geometry sample reuse and oldest-last-use-first eviction among releasable samples**. Timestamps have one-second granularity, ties have no proven ordering, and this is not strict total-order LRU. It does not prove cached placement reuse, show the active memory allocation or measure hit rates. The official [Animation reference](https://docs.itoosoft.com/forestpack/forest-plugin/animation) describes geometry sampling and caching, consistent with that scope.

**Updates.** Forest's display-update gate compares stored/current fields and has a force path; its actual dirty-event ownership remains untraced. Chaos has a native `CoreDataCache` owner, but its stage reuse/invalidation policy remains unresolved. A Chaos profiling label saying “Targets cache reset” belongs to paint-target metadata refresh; it must not be reported as proof that all placements are regenerated or cached.

## Recommendations for Cyrus — independent design inference

1. **Keep receiver ownership explicit.** Let the scatter/population own its receiver registry and model distribution. Let each painted document have a stable identity and explicit receiver scope. A selected region should not silently change scope when the receiver list is reordered.
2. **Support two useful authoring representations.** Projected closed contours suit terrain borders and spline editing. Mesh-attached strokes suit curved receiving surfaces. We can share inclusion/exclusion and artist controls while giving each representation a clear projection/attachment contract. A universal contour representation would not automatically handle folded or vertical meshes.
3. **Make fading optional and independent.** Default to a hard region. Store fade side, distance and curve separately, then evaluate the boundary distance through that curve. Changing the curve should not re-author the border or resample brush input. This is a Cyrus proposal, not a recovered Forest implementation.
4. **Retain documents when a target is missing.** Mark their attachments unresolved and keep the last complete result until a valid update can publish. Explicit rebind/delete actions are preferable to silent loss. Validate topology with more than face count when attachment survival depends on connectivity.
5. **Preserve unaffected placements deliberately.** Use stable receiver identities and deterministic per-receiver candidate generation for Density. Treat Fixed Total as an allocation policy with a documented redistribution contract. The earlier Chaos tests show that deterministic restoration can coexist with extensive reshuffling on receiver addition; stability alone does not prove cache reuse.
6. **Bound editing and measure actual stages.** Maintain a stroke/edge spatial index, publish a completed successor atomically, and distinguish authored geometry, prepared receiver data, candidate placements, model assignment and display buffers. Instrument their build/reuse/upload counts before making performance claims. If an eviction policy is needed, a monotonic access sequence avoids wall-clock changes and ambiguous same-second ordering.

These are research recommendations. This pass neither implements a new Cyrus brush nor qualifies the ongoing Cyrus changes.

## Remaining acceptance questions and preservation

Highest-value next tests are: brush influence across two close receivers/thin shells; same-count topology edits versus vertex-only deformation; save/reopen/Undo identity survival; and measured cache-stage counters for selection, viewport movement, relevant receiver edits and explicit Update. Forest Pro curved authoring remains untested with the installed Lite edition. A complete vendor placement scheduler, renderer integration and original repository remain unavailable.

All seven captured installed inputs retained their hashes. The previous owned scene retained its hash. This pass edited only its research folder and documentation navigation. **Cyrus product files changed concurrently in the shared workspace**; [EVIDENCE.json](EVIDENCE.json) records before/after hashes rather than claiming all product source remained unchanged. Those changes were left untouched. No licensing bypass, vendor source integration, plugin installation, product build, commit or push was performed.
