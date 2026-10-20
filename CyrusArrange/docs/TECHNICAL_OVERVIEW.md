# Cyrus Arrange: technical overview

For the 0.3.2 development architecture, use the [geometry placement core](GEOMETRY_PLACEMENT_CORE_0.3.2.md), [base support](BASE_SUPPORT_0.3.2.md), [compound collision](COMPOUND_COLLIDERS_0.3.2.md) and [path core](PATH_CORE_0.3.2.md). The sections below retain the earlier category-based pipeline and its historical acceptance.

Cyrus Arrange runs in 3ds Max 2027 on Windows x64 and dresses explicitly chosen
furniture with registered accessories. Its C++20 core owns geometry analysis,
placement, validation, saved state and
resource lifetimes. MAXScript provides artist controls and bounded commands.
Furniture categories and accessory eligibility are authored rules; naming can
suggest a category, but the system does not infer object meaning from an image.

This explains the architecture. The 0.3.1 [native presentation](NATIVE_PRESENTATION.md)
adds a modifier and icon over the same document. Its status belongs in the
[current acceptance record](REAL_WORLD_0.3.1.md); the prior
[0.3.0 qualification ledger](RELEASE_VALIDATION_0.3.0.md) retains its original
evidence. Start with the [artist quickstart](ARRANGE_QUICKSTART.md) for use.

## From Max scene to numerical inputs

The Max adapter expands selected groups, deduplicates members and rejects
unsupported, generated or conflicting input scopes. Evaluation, reference access,
material capture and scene publication run synchronously on Max's main thread.
The portable numerical modules receive owned C++ data and call no Max APIs.
MAXScript never receives placement-sized mesh or sampled-cell buffers.

The adapter copies evaluated triangles using explicit `GetObjTMAfterWSM` before
fresh `EvalWorldState`. This order avoids borrowing pipeline data across a
transform evaluation. A world-space modifier may already produce world-space
geometry, making the final transform identity. Applying an unrelated node/object
transform again would place that mesh incorrectly. Mirrored winding and specified
normal corner identities are handled consistently with evaluated topology.

All numerical distances are physical millimetres, Z up, independent of display
units. Geometry is translated near a saved origin for computation; output/export
adds that origin back. Asset capture bakes evaluated rotation and scale into its
world-oriented axes and removes the base-bounds-centre translation. Authored
contact patches and Book spine faces use that captured frame, not a rotated
source pivot or camera frame. See [geometry](GEOMETRY.md) and
[asset metadata](ASSET_LIBRARY.md).

## Discovery, policy and physical fit are different stages

Furniture supplies sampled support layers, usable cells and overhead-clearance
estimates. A persistent region registry reconciles these observations with saved
IDs and authored labels, category masks, density, stacking, exclusion and front
direction. The registry is not an automatic cabinet/cavity classifier.

Usable cells suggest candidate anchors; they never certify that an entire prop
fits. The placement query checks the full transformed contact polygon against
captured support polygons and edge inset. The shared numerical contact default
is 0.002 mm: true source height extrema must fit the candidate's height band.
Eligible height bins unite before inset, preserving genuine holes and edges
without treating a numerical bin seam as a board edge. Sources are not flattened.
The inspector's separate sampling tolerance is not an accessory contact allowance.
See [numerical support](NUMERICAL_SUPPORT.md).

An excluded region prevents anchors on that region; it does not create a
keep-clear volume extending into neighboring support. Explicit obstacle geometry
participates in collision, recognized closed-solid containment and the optional
straight front-access sweep. Its top never supplies support. Unselected scene
objects are outside this authored scope. Furniture/obstacle scopes cannot contain
the same expanded node. See [region identity](REGION_REGISTRY.md) and
[physical placement](PLACEMENT.md).

Accessory collision uses conservative full-bounds oriented boxes against captured
furniture/obstacle triangles and other props. This can reject a pose that detailed
concave mesh collision would permit. Fit does not establish gravitational
stability, manipulation order or renderer-displaced contact.

## Assets, seeded placement and output appearance

Each asset owns a stable ID, evaluated geometry, category/masks, weight, allowed
yaws, uniform-scale limits, contact anchor/footprint and optional authored stack
top. A `.cyalib` saves geometry and metadata, including eligible Book row profiles;
it does not package scene materials or texture files. Bound sources provide
current appearance during generation. Missing required sources fail explicitly;
Rebind, Undo or the deliberate stored-geometry action resolves that condition.

The solver orders inputs deterministically and derives candidate streams from
the seed and stable identities. Furniture/category rules and regional policy
filter candidates before physical checks. Density, usable area, spacing, scale
and style estimate a population target. Rejections and category limits can leave
underfill; the returned requested/accepted/kept/underfilled counts and warnings
report that outcome. The solver stays within authored scale limits rather than
changing those limits to force the target.

Book rows are native relationships between separately placed, profiled Books.
Allowed yaws align authored spines to the region front; saved gaps, complete-row
protection and bounded optional height balancing preserve the relationship.
Each member still passes physical validation. Stacking requires the parent's
authored top patch. See [book rows](BOOK_ROWS.md) and
[composition](COMPOSITION_DESIGN.md).

Generate captures evaluated source meshes, UVs, face material assignments,
smoothing and normals, then creates ordinary Max output geometry/instances.
Material/map availability remains a source and renderer concern; geometry-library
portability does not promise original PBR reproduction. Record IDs and poses are
stable relationships; successful regeneration can replace output node handles.

## Authored ownership, transactions and lifecycle

An ordinary Point setup node owns a native custom attribute, which owns the C++
Document. Real Max references bind furniture, assets, outputs and obstacles;
a weak owner monitor avoids a strong ownership cycle. Immutable authored snapshots
and shared asset/region buffers support Undo without duplicating all geometry on
every settings edit. The bounded native codec saves state; Max saves the reference
graph. Current document/library/registry formats are 4/2/1, with explicit readers
for the supported delivered predecessor. Loading does not generate or arm Live.

Generation stages a complete successor before accepting its Undo transaction.
State identity, ownership, dependency tickets, units, time and geometry stamps are
checked around capture and publication. Capture/query/solve/publication failures
retain the previous complete result; cancellation preserves genuine pending
input changes. Response delivery or viewport redraw after successful publication
is a separate boundary, not a promise to reverse an accepted transaction.

Manual mode waits for explicit Generate. Live requires a first successful update
and responds to relevant inputs through native observation/service callbacks.
Editing a managed output pauses automatic replacement; valid pose edits can be
captured with **Lock selected outputs**, or explicitly regenerated. Locking a row
protects its complete relationship, not just one Book.

Preview solves current inputs but retains only diagnostic bounds, statistics and
provisional region identity, with no output nodes or authored revision change.
It disarms Live. Commit requires a current Preview and recomputes against current
inputs; stale Commit retains published outputs. Clearing Preview does not rearm
Live. Scene/history events clear transient preview state. Dependency observation
persists after Preview-only discovery of new group members, independently of
optional geometry reuse. See [scene ownership](SCENE_OWNERSHIP.md) and
[the arrangement interface](ARRANGEMENT_API.md).

## Reuse, bounds and measurement

The optional native cache retains immutable raw furniture observations and the
furniture/obstacle query, with no Max objects, asset appearance, placement result
or published region registry. Same-time exact keys include document/scene epochs,
units, scopes, settings, evaluated validity and final transforms. Each reused
command still reconciles regions, refreshes bound assets, solves and validates;
Analyze remains cold and furniture-only.

The service admits at most four entries and 256 MiB of accounted retained entry
allocations, also bounded by triangle/cell totals. Borrowed retired entries remain
charged. These limits exclude Max objects, output meshes, Undo, Preview and
temporary capture/union/inset buffers. An optional retention failure can fall back
to cold computation; ordinary numerical failures still fail atomically.

Original/executed work counters establish whether construction was reused;
phase timings measure elapsed cost, not physical correctness. Process memory is
different from accounted retained bytes. Full Generate includes asset appearance
and publication, so faster query preparation alone is not a whole-command speedup
claim. Exact cold/reused records, independent geometry checks and controlled
opposite-order timings answer different questions. See
[cache contracts](CACHE_RUNTIME.md), [measurements](PERFORMANCE.md) and
[the measurement protocol](PERFORMANCE_PROTOCOL.md).

## Source and tool map

| Location | Responsibility |
| --- | --- |
| `include/cyrus_arrange/`, `src/geometry.cpp`, `src/placement_queries.cpp` | Owned numerical types, sampled inspection, support polygons, collision/access queries |
| `src/assets.cpp`, `src/arrangement.cpp`, `src/region_registry.cpp` | Asset validation/library codec, seeded solve/relationships, persistent support identity |
| `src/document_state.cpp`, `src/geometry_cache.cpp` | Portable saved-state codec and transient numeric cache/lease accounting |
| `src/max_bridge.cpp`, `src/arrange_bridge.cpp` | Max capture, visible primitives, staged validation, output/material publication and diagnostics |
| `src/arrange_document.*`, `src/storage_plugin.cpp`, `src/preview_service.*` | Native reference ownership, Undo/persistence, dependency/Live service and viewport bounds |
| `scripts/` | Main artist workflow, asset, surface, obstacle and inspector controls |
| `tests/*_tests.cpp`, `tests/max/`, `tests/data/` | Portable invariants/failure tests, actual Max workflows/lifecycle and original fixtures |
| `CMakeLists.txt`, `tools/build.py`, `tools/run_max_tests.py` | Native/core build and isolated host execution with source/module identity receipts |
| `tools/verify_exports.py`, `tools/verify_cache_performance.py`, `tools/package.py`, `tools/run_installer_tests.py` | Independent JSON/performance validation, exact payload packaging and private installation/startup qualification |

Max-native modules must be a matching `CyrusArrange.dlx`/`CyrusArrangeStorage.dlh`
pair with their corresponding scripts. Qualification records bind source,
fixture, loaded-module and package hashes; a version caption or isolated core
pass does not establish a working installation. Detailed command rows live in
[the arrangement API](ARRANGEMENT_API.md) and [inspector API](NATIVE_API.md).


## 0.2.0 artist workflow boundary

`caShowArrangeUI()` opens the compact artist window (`caHomeUI`).
`caShowAdvancedArrangeUI()` opens the detailed controls (`caArrangeUI`) for
that same native setup. The installed Styling macro keeps its registration ID.

`caSceneSetups selectedNodes` is passive native discovery. It returns owner,
match flag and bound furniture roots using real document references. Names and
ownership-looking user properties are not authority. It admits at most512
resident documents,4096 selected nodes and65536 returned furniture roots, with
4million charged hierarchy/reference steps. Selecting a normal linked child
is not equivalent to selecting a member of an actual furniture group.

`caGenerateVariation setup settings11 regions randomize` parses typed settings
and stages them on `PreparedGeneration.next` before geometry preparation.
Randomization uses bounded native entropy draws and excludes the supplied and
previous seed. Normal publication commits the complete settings, seed and output;
failed preparation does not precommit an authored setting. Existing `caGenerate`,
Live and Preview/Commit retain deterministic seed semantics.

The UI remembers the actual hydrated float-control values to detect edits.
Untouched native Double density/spacing values remain exact, even where the
spinner cannot display every bit. A current native state is read for each
Generate; only deliberately changed main fields override it. Main drafts survive
prop-list refresh, same-owner reuse and closing Advanced. Explicit Refresh
reloads saved values. Props is closed/guarded when its main owner changes.
Selection callbacks discover ownership only; they do not evaluate geometry.
Keep seed is session/window state; the successful seed is existing native scene
state. No scene or asset codec revision is introduced by this UI delivery.
