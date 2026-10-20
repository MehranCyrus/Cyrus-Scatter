# Automatic compound colliders — implementation contract

Status: focused implementation qualified in the native and actual Max cases
below; not a release. Current frozen build is `build/native-032-collider-host03`.
The preceding 154-file checkpoint is preserved in `build/collider-032-baseline01`.
The full geometry/Modify objective remains active.

## Ownership, lifetime and failure

Keep visual meshes, materials, scene schema7, asset library2 and saved placement
identities unchanged. A solve owns at most 256 native source-collider objects,
borrowing its already validated immutable Asset snapshot. Source proxies build
lazily only when a full bounds collision needs refinement. Numeric probe/accepted
descriptors borrow those sources only during synchronous queries. They never
enter saved results, Document state, host references or retained geometry caches.
Regional Fill reconstructs outside descriptors from its own still-live catalog.

Build work and every refined query charge the caller's remaining native budget.
A source has at most 16 horizontal bands with eight connected pieces each, at
most128 local boxes. Source geometry limits bound temporary vertex/topology and
clipped-triangle arrays. On the current x64 toolchain, topology element storage
is bounded by `40*V + 72*T` bytes (keys, welded IDs and edge records), at most
28,000,000 bytes under per-source 250k vertex/triangle admission. The subsequent
band phase uses at most `24*V + 56*T + 6144` bytes of element storage. These
phases reuse/retire their temporaries; the limits exclude allocator/control/stack
overhead and the already-owned source snapshot. Lazy proxy element capacity is
at most 6,144 bytes per source, about 1.5 MiB for 256 built sources. Regional Fill
can have parent and one child catalog live concurrently. This is a bounded
native element-storage account, not measured process RAM.
Insufficient refinement allowance coarsens representation conservatively, never
discards triangles or accepts an unproved collision. Invalid input or exhausted
overall query/publication work retains the previous complete output and settings.
Source edits naturally invalidate proxies because the next solve owns a fresh
catalog. No retained proxy cache or Max API call is introduced in numeric work.

## Conservative representation

Clip every triangle to each selected Z band. Weld coincident numeric vertices
for connectivity and certify closed oriented manifold topology from paired
edges. For closed geometry, connected sliced boundary patches supply enclosing
XY boxes over that complete band. For uncertified topology, retain the complete
root envelope. This includes disconnected caps with missing walls, whose empty
intermediate bands do not prove an empty interior. Exceeding a band's eight-piece
budget merges its complete bounds.
Coarser bands and the full root bounds are valid conservative quality levels.
Merge vertically adjacent boxes with identical XY extents. Outward numerical
padding is clamped to the known complete source bounds. At query time, internal
Z cuts overlap by twice the world contact tolerance, clamped to full source Z
bounds. Otherwise per-piece erosion could open a false hole through a thin solid.

For a closed solid, a horizontal interior point lies inside a boundary loop at
that height. The loop belongs to a connected sliced boundary patch, whose XY
box encloses its interior. Thus these boxes enclose solid interiors as well as
triangle surfaces. This matters: triangle bounding boxes alone could leave the
inside of a solid cube incorrectly empty. Unknown/open topology uses the full
root envelope instead of relying on this closed-boundary argument.

The full OBB remains broad phase, and full contact footprint support, edge margin
and complete path lane containment remain mandatory. Only an overlapping broad
collision is refined against compound pieces. The same pieces apply to static
obstacles, prop/prop overlap, horizontal gap and an explicitly requested access
sweep. This may still reject valid shapes within a coarse piece; it must never
underestimate occupied source volume. Support-patch refinement is separate work.

Once a broad pair needs refinement, the gap check includes vertical separation
between its pieces. Artificial bands cannot bypass a requested gap by being
vertically disjoint by less than that gap. Whole-object height filtering and
explicit support-parent exemptions retain existing stack behavior.

## Required evidence

Native cases must prove solid interior occupancy, all clipped triangle vertices,
closed arches/leg gaps, open/nonmanifold coarsening, static overhead/obstacle
avoidance, pair collision/spacing, yaw/scale/anchor transforms, low budgets and
source lifetime across regional Fill. Test original-size acceptance where a root
box fails, actual collisions inside each remaining piece, protected placement,
repeatability and unchanged source geometry. Preserve older goldens; review any
legitimate geometry behavior change independently.

Build the Max2027 native pair and use owned Max scenes to measure actual source
mesh geometry, accepted open-space fit and true-overlap rejection. Re-run current
Modify/path/geometry and shelf/stair cases as appropriate to changed acceptance.
No artist installation or computer use. A numeric prototype is not host proof.

## Current implementation and evidence — 18 October 2026

`collision_proxy.h/.cpp` owns the solve-local representation, complete-box/pose
consistency checks, exact coincident-vertex topology admission, clipped band
components and bounded piece overlap. `arrangement.cpp` and `path.cpp` supply
source descriptors for protected, ordinary, staged row and regional output.
`placement_queries.cpp` keeps full support/edge validation, refines static
intersections/solid containment and access sweeps, and applies the same source
pieces to prop/prop collision and spacing. No source proxy enters a saved state
or retained receiver-query cache. No new UI control or popup was added.

The current **160-file exact source map** passed both Max2027 modules and all
**18 native suites**, including **14,313 compound-collider checks**. Those cases
cover independently classified solid arch samples and triangle barycentric
samples, occupied cube interiors, open/nonmanifold/caps coarsening, thin-band
tolerance, actual legs/beam, offsets/yaws/scales/anchors, budgets, protected
rearrangement, regional source lifetime and path-only pairs. The six prior
regression scenarios retain bit-exact poses, requested/accepted/kept/candidate/
unfilled counts and rejections. Only charged work and the explanatory warning
changed; `geometry_collider_032.golden` is separate from the preserved prior
fixtures. Review evidence is in `build/collider-golden-review01`.

All five owned Max2027 runs on that same pair exited normally and passed all five
module, binary, private-INI and artist-profile guards:

| Run | Passed checks | Actual scope |
| --- | ---: | --- |
| `host-032-collider-compound02` | 17 | Connected concave arch; protected nested device; static gap versus real leg; path-only pair; Undo and reopen |
| `host-032-collider-shelves02` | 26 | 100 complete imported books, 48 mixed stair props, minima, appearance, support and source preservation |
| `host-032-collider-ui01` | 88 | Mounted Modify controls, dropdowns, Generate, draft preservation, Undo/Redo, path mode and no extra popup |
| `host-032-collider-path01` | 37 | Actual spline/lane/collision/reference lifecycle and global source minima |
| `host-032-collider-geometry01` | 19 | 100-copy geometry and original-first bounded cabinet fit |

That is **187 actual Max checks**. Source/receipt hashes, source changes, scene
hashes and remaining work are in `build/collider-032-progress01/progress.json`.

The modeled arch is a connected closed mesh with 20 vertices and 36 triangles,
1,000 mm wide, 400 mm deep and 1,000 mm high. An independent verifier proves its
authored boundary and empty region against the union of two 150×400×1,000 mm legs
and a 700×400×200 mm beam. The device remains at original size beneath it, with
overlapping complete bounding boxes. Static, protected and path cases pass;
placing an obstruction in actual occupied geometry rejects. Every actual output
vertex agrees with its complete source/pose to at most 0.0000216 mm. Invalid leg
penetration, floating, missing faces and visual shrinking were correctly rejected.

The shelf/stair verifier independently proves receiver solids, actual source
transforms/topology, full footprint support and pair gaps. It uses envelope
distance first; where those envelopes are too coarse, a separating projection
of **all actual mesh vertices** proves the requested distance. It does not import
the native band-box algorithm. A failed separation proof rejects the case.
The 100 books retain levels 24/23/26/27 and a minimum proved gap of 2.004974 mm.
The 48 stair props are 15 books, 16 bins and 17 fruit on all six treads
(7/7/6/7/12/9). One pair has an envelope distance of 5.728516 mm; mesh separation
still proves the required 10 mm, with the campaign's minimum proved gap 10.003906 mm.
Four deliberately invalid shelf exports were correctly rejected as well: eight
negative controls across the two independent verifiers.

Single prepared generation calls measured 2 ms for the nested pair, 100 ms for the
100 books and 51 ms for the 48 stair props. Qualification processes ran concurrently;
these are observations, not a cold-load, general latency, FPS or before/after
benchmark. Original sources, maps and saved material references stayed unchanged.
No artist installation or computer use occurred.

The initial core build had a test initializer compile error. The first full build
passed 17 of 18 suites, stopping at the expected work/warning golden difference;
it was reviewed before the new fixture was added. The first stair run stopped
after 16 passes at the old envelope-only separation assertion. The revised fixture
preserves complete appearance/support checks and exports actual meshes for strict
independent separation proof. A separate native case also caught and prevents
gap bypass across vertical collider bands. The initial arch verifier demanded
exact float axis-aligned corners after a quarter turn; rigid source-to-output
vertex proof and analytic gap containment now handle the observed 0.000022 mm
rounding correctly. Original failed receipts and diagnostic-only reviews remain
preserved; none are relabeled as a pass.

Open or unproved source topology and insufficient refinement allowance retain
full bounds. Connected band pieces can still overestimate in-band concavities;
contact support still uses the existing complete authored/default footprint.
Continue support/precision refinement, useful failure/proposed-fit feedback,
inline independent overrides, legacy book-row/minimum handling, detailed cars/
complex receivers, broader units/performance/lifecycle and final installer
qualification. The full objective remains active.

## Research references

SideFX documents [compound convex proxies](https://www.sidefx.com/docs/houdini/shelf/rbdconvexproxy)
as a way to represent concave objects using several convex shapes. Its
[VDB from Polygons](https://www.sidefx.com/docs/houdini/nodes/sop/vdbfrompolygons.html)
and [Collision Source](https://www.sidefx.com/docs/houdini/nodes/sop/collisionsource)
distinguish boundary representation from filled interiors. These inform our
collision/visual separation and solid-interior witnesses; the bounded band-box
algorithm here is our own design, not Houdini's implementation. Checked
18 October 2026. No third-party code or new runtime dependency is introduced.
