# Implementation plan — four independent painting experiments

Status: original design contract, now partially implemented in four 0.1.0 trials. See [measured results](../results/0.1.0-2026-10-10/README.md) and the [feature/gate status](../results/0.1.0-2026-10-10/FEATURE_STATUS.md) for actual completion. Requirements below remain targets where explicitly pending; they must not be read as implemented behavior. Product integration is a later decision.

## 1. The question to answer

For landscaping in Max, which representation gives predictable paint/erase, editable planting boundaries and responsive feedback as the drawing grows? Separately, which handles spheres, walls and folds acceptably? We must measure input, editing, coverage queries and display independently. Optimizing one does not establish a usable brush.

The user's expanding drawing is the first regression scenario. Current source can return a limited preview and publish it as the new tint. That is a verified code path and a plausible explanation of disappearing display; it does not prove the user's saved coverage was deleted. The exact scene and loaded module identity still need qualification.

## 2. Isolation and delivery

Build four independently loadable experimental Max 2027 plugins, each with a small MAXScript launcher. Native C++ kernels make algorithm performance comparable; script-only mouse loops would confound the result. First establish the Painter/input bridge with a tiny spike, then reuse only that bridge. Each prototype has its own registered identity, storage schema and experimental version, initially `0.1.0`; Cyrus stays at 0.77.

Each package must work without loading Cyrus Scatter, Analyzer, Licensing or MCP. It contains its plugin, launcher, instructions and a matching hash manifest. No auto-start installation into the normal Max profile. Use owned disposable profiles and scenes; no computer-use automation. Existing `private_host.py` assumes Cyrus modules, so plan a minimal lab-specific profile launcher rather than silently loading production dependencies.

Do not port Cyrus's `Field`, `CoverageCache` or triangle-budget preview into the experiments. Existing SDK display/input examples may inform the bridge after review. No new framework, renderer, licensing, AI integration or full scatter implementation is needed.

## 3. What every trial exposes

One compact window: receiver picker/list, active region, Paint/Erase, radius in scene units, Start/Stop, Undo/Redo, Clear, boundary/fill/point preview toggles, Save/Load and visible performance/status counters. Advanced controls only when the method needs them: precision/resolution and boundary fade or soft strength. Unsupported controls are labelled unavailable. Repeated gestures edit the same region; they do not create a new artist-facing paint set each time. A gesture can remain an internal undo operation.

Start with one receiver/region, then add multiple receivers and named regions. Each region has one explicit receiver identity. Painting another receiver selects/creates its region deliberately; no implicit redirection of existing paint. Removed receivers leave inactive data, restored when the same identity returns. Duplicate nodes receive new identities. No model ownership is hidden inside a region.

Use a frozen candidate cloud with stable IDs and deterministic random values to show the effect on possible plants. Coverage filters candidates without relocating surviving ones. Allow separate Include/Exclude region composition, with exclusion winning; overlapping includes must not double the candidates. This is a coverage test, not a new population/collision system. A small optional instanced model view comes after the point view passes.

## 4. Common semantics

### Hard region track — all four methods

Start empty. Paint adds the swept brush footprint; Erase subtracts it. Repeated paint over painted space is idempotent. Paint followed by Erase then Paint respects order. A complete drag has one Undo entry, including all its intermediate feedback. Cancel restores the pre-gesture state. Radius changes affect subsequent input, not earlier paint.

Replay a common trace: time, receiver identity/revision, hit/miss, triangle and barycentric coordinates, world hit/ray, radius, operation, projection frame where applicable, and transform. Resample by physical distance and interpolate footprint sizes, not mouse event frequency. Break paths on missed hits, receiver changes or discontinuous surface jumps; never bridge a gap blindly. Define MAX Painter size-to-radius units in a calibration fixture before comparisons.

### Soft behavior — separate tracks

- **Boundary fade:** density from distance to the final border, with independently specified inner/outer width. This is the initial soft extension for A; it is not arbitrary interior opacity painting.
- **Interior opacity:** B and D store grayscale. For a gesture use maximum dab influence at each location, then apply it once to the pre-gesture field: paint `v + (1-v)*a`, erase `v*(1-a)`. Separate gestures accumulate. C may evaluate the same ordered rule analytically, but the history cost must be included.
- Never score one track against another as though their output semantics matched. Radius and strength meanings must be displayed and saved.

Terrain footprint uses a fixed declared projection frame; surface trials must identify whether the footprint is a Euclidean volume or distance along the mesh. A normal-angle or connectivity gate is not proof of geodesic distance. Test the distinction explicitly.

## 5. Common engineering boundaries

**Input and geometry:** use the Max Painter SDK where feasible. Snapshot evaluated triangle geometry and transforms on the host thread; workers receive copied data. Geometry preparation updates on relevant changes, not every pointer sample. Record preparation and hit-testing cost. Do not assume matching face count means unchanged topology.

**Publication:** each region revision has a complete committed state and a tentative gesture state. Publish an internally consistent state/query/display revision. Dirty chunks may replace their previous versions atomically while unrelated chunks remain intact. A budget limit must never silently remove previously visible regions. Under pressure retain the last complete display, show pending work and an active cursor, or reject/cancel the edit with a clear reason. A pending display that never catches up fails responsiveness.

**Display:** thin shared retained rendering transport for lines, colored samples and method-produced fill chunks. Each method pays for extracting its resolved border and fill. A centerline or the outlines of every dab are not the final boundary. Start with lines and fixed samples; add representative fill before declaring a winner. Editing changes only affected chunks where possible; orbiting must not re-evaluate paint or upload unchanged buffers.

**Work control:** bound per-event work and queues. Coalesce redundant pointer events while preserving the swept footprint, endpoints and miss boundaries. One region's obsolete jobs cannot overwrite a later revision. Escape/Stop/close/selection change must release the Painter and callbacks. Manual mode keeps plant-preview evaluation pending until Update; the brush boundary itself still responds. Live mode updates affected samples, with mouse-up completion timed separately. Shared Max Painter preferences must be restored on all exit paths.

**Geometry changes:** rigid transforms preserve receiver-local paint. World-radius input must account for nonuniform scale. For C/D, same-topology deformation updates anchors/field geometry; topology changes mark data inactive until an explicit reset or tested rebind. A/B preserve their declared projection contract; folds that make it ambiguous are reported unsupported. No silent reinterpretation or deletion. Deformation performance is measured separately from static painting.

**Storage and Undo:** save authoritative state, settings, receiver links and schema version; rebuild derived caches on load. Undo cost and memory are part of each method's result. Never preserve unbounded history only for compatibility. C necessarily stores analytic operations; its ability to compact or checkpoint without changing results is an open experiment, not an assumed solution. B/D keep changed-block deltas; A begins with before/after contour snapshots and optimizes only if profiling demands it.

## 6. Minimal conceptual interface

Keep this a small test seam, not a production abstraction: prepare receiver; begin gesture; append hit; preview current revision; commit/cancel; query weights for anchored candidates; export boundary/fill; save/load; return counters. Native data types may differ between kernels. The fixture runner supplies the same traces and samples, and records capabilities and unavailable cases.

Dependency decisions precede kernel implementation. A can use a pinned public Clipper2 Boolean library after license/robustness checks; its currently warned-about triangulation must not be adopted without independent qualification. Outline-first work avoids blocking on triangulation. B starts with CPU sparse tiles and explicit sampling; D with a small triangular face-tile implementation, not a full Ptex dependency. C uses independently written standard distance/BVH algorithms. No vendor pseudocode is copied.

## 7. Small implementation stages

| Stage | Deliverable | Exit gate |
| --- | --- | --- |
| 0 — planning (this step) | Four briefs, source ledger, test contract, tool receipt | No implementation claimed |
| 1 — input/display spike | Owned profile; one plane; Painter calibration; trace replay; fixed sample display; timing counters | Correct world radius, cancel/close cleanup, no Cyrus dependency |
| 2A — vector slice | Paint/erase contour region, holes, Undo and outline | Expanding scribble never loses earlier regions; independent query oracle passes |
| 2B — tiled slice | Same fixture with sparse grayscale tiles | Comparable hard output at declared tolerance; dirty-tile counters work |
| 2C — volume slice | Anchored segments, spatial query and resolved contour preview | Correct operation order; history/overlap cost and leakage recorded |
| 2D — surface-field slice | Face tiles and seam-aware painting/query | Tiny brush on a two-triangle plane and sphere seams pass |
| 3 — comparison | All four same traces; common fill/points; growing area/history; memory | Publish failures as well as passes; reject obviously unsuitable methods early |
| 4 — lifecycle and artist trials | Save/load, Undo, multiple receivers, deformation; four matched packages | Programmatic gates plus actual artist feedback, not just synthetic timing |
| 5 — decision | Terrain/freeform recommendation, costs, unresolved tradeoffs | User reviews evidence before separate integration proposal |

Implement A first because it directly tests the user's border workflow, not because it has already won. Keep every first slice small; do not polish A into a product before B/C/D exist. If a method fails a gate, record the smallest explanatory test and either make one focused revision or reject it. Do not expand into unrelated Cyrus improvements.

## 8. What is deliberately deferred

Full scene reconstruction, production scatter collision/count scheduling, render qualification, source-model UI, migration of old paint scenes, exhaustive tablet support, arbitrary remeshing recovery and GPU compute. These do not decide the initial representation. Any candidate that needs them just to hide basic painting latency must expose that cost in the decision report.

No performance promise follows from this plan. See the [test plan](TEST_PLAN.md) for provisional targets and the distinction between measured CPU timings and presented interaction latency.
