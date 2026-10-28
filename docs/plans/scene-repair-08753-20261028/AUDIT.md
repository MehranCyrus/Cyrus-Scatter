# Test22 source workflow, memory and navigation audit

This is the scoped 0.87.5.3 campaign for `New Plants test 22.max`, using owned
Max 2027 profiles and copied scenes. Historical 0.87.5.2 evidence is a comparison,
not qualification of the successor. Final package and host receipts belong in
`QUALIFICATION_08753.json` and `DELIVERY_08753.md`.

## Reproduced causes

| Observation | Source-level cause and correction |
| --- | --- |
| Interactions still names a removed sphere | Its list used a different source cohort from the authored Models rows. Both views now bind stable authored row IDs, including missing/Point/Empty rows. |
| Missing source cannot be removed | Removal depended on a valid node. X now resolves the selected row identity; a stale click refreshes rather than deleting a replacement row. |
| Adding the stone still fails | A deleted node in the preceding publication was read while constructing its successor's display key. Staging now uses the successor's own source arrays. |
| Small source scatters at imported size | The placement frame omitted the evaluated source node's scale. Positive unsheared axis scale now composes once with Models Scale and candidate scale. |
| Models Scale after an Edit move is rejected | Retained source binding treated Scale as an incompatible generation change. Typed binding now permits that setting while preserving Edit identities and deltas. Other incompatibility guards remain. |
| Large preview rejects a hypothetical 1 GiB render mesh | Viewport publication eagerly admitted one combined exact render allocation. Publication now retains immutable source/pose references; exact multi-mesh render/Bake construction is admitted per batch. |
| Navigation stays reduced after dragging | Native graphics-context matrix changes could enter reduced detail independently of the script's camera/mouse activity and idle timer. One activity authority now pairs reduced mode with the 400 ms restoration timer; idle return invalidates the retained helper rectangle without rebuilding geometry or solving contact. |

## Scale and source ownership

The input uses centimetres: one system unit is 0.01 metres. The three source
stones have node scale approximately 0.158293679. With Models Scale 0.5, the old
placed axis length was approximately 0.5; the corrected value is approximately
0.07914684. This is a dimensionless transform correction, not a scene-unit
conversion or a destructive mesh reset.

Source position and orientation retain their existing placement semantics. A
prepared mesh, guides and collider stay in the same pivot-local frame, and the
instance transform applies scale once. Positive nonuniform scale is usable for
ordinary display; the contact system still requires positive uniform similarity.
Mirrors, shear, singular transforms and incompatible edited source histories
remain explicit failures which retain the preceding complete result.

Source membership is authored once. Manual mode keeps the old complete
publication until **Update scatter**, even when both UI lists immediately show
pending rows. Replacing a source keeps its row ID/settings and removes only its
incompatible preparation/custom collider link. Empty layers retain their role.
The [bounded native Undo journal](SOURCE_COMMAND_UNDO.md) records these authored
commands; it does not duplicate placements or geometry.

## Exact render construction

An output packet holds immutable source/pose lifetimes and a sorted instance
index. Max's public multi-mesh render callbacks construct complete chunks with a
128 MiB target, a 1 GiB hard construction estimate and 20 million vertices/faces
per chunk. The renderer owns returned meshes. These bounds are not a cap on all
renderer-held meshes, total process memory or GPU memory. A single-mesh-only
caller retains the explicit combined-construction guard. A single source which
exceeds a hard batch bound can still be rejected when actually requested.

RenderBegin pins a complete snapshot through RenderEnd. Bake creates complete
bounded nodes, admits at most 4,096 nodes and tracks rollback before creation.
Public callback and Bake face-count checks are consistency checks, not a claim
that every external renderer has been qualified.

## Measured work and preview controls

The grass source has 27,501 triangles; 1,000 copies therefore draw about 27.5
million triangles before the stone and without preview limits. Sharing geometry
and uploading compact poses does not remove that rasterization cost. The new
**Fast navigation** button explicitly sets the existing moving-view limit to
500,000 triangles, retaining the idle limit. It selects complete instances; it
does not decimate each plant or change accepted placement counts or render output.
An authored zero still means unlimited until the artist changes it.

The native drawing path no longer guesses camera movement from per-pass graphics
matrices. Those matrices can change without a user camera move. It reads the same
activity flag whose script setter arms the idle timer. If activity is not observed,
the safe result is a full-detail frame, rather than an unpaired reduced display.
No new always-running polling loop or display-time scene traversal is introduced.

The exact contact optimization caches immutable triangle data, capped at 65,536
triangles per collider (80 charged bytes each), and a 928-byte candidate memo per
worker. A repeated candidate must match guide ID, node positions, frame values
and root policy bitwise. Cache hits preserve logical work charges and output.
The memo's scratch charge is included in worker admission; uncached triangles
use the same exact fallback.

Physical mouse-up also needs a final publication of edited transforms for
spacing, rendering and saved/Library snapshots. Its epoch, Edit/filter preparation
and contact-layout counters can advance without regenerating base candidates.
The final harness checks each leaf's `paintCacheStats()` and
`receiverCacheStats()` build counters separately. A development assertion which
treated every new epoch as a static rebuild was too strong; the actual base and
receiver build counters stayed unchanged while their cache hits increased.

That audit did identify an unnecessary **4,400,160-byte** upload per release in
this grass: 27,501 triangles × 10 binding words × 16 bytes. The drawing path
compared temporary preview-wrapper identities. Bindings derive solely from the
immutable prepared `Source`, so matching Source identity under the existing
geometry/full-detail compatibility guard can retain the same binding buffer and
memory lease. New preparation or geometry still invalidates reuse. Pose and
changed-instance data remain generation-owned and update normally. The final
physical drag receipts distinguish these uploads rather than asserting that
required final publication must disappear.

Paired numeric replay of the captured broad-stone fixture, initial state plus
four moves, retains identical pose digests, warnings and logical work budgets.
Median wall time changes from 2,201.8 to 2,111.4 ms (about 4.1%); initial exact
checks change from 159,701 to 156,504. This modest result is not a universal
speedup or presented FPS claim. Raw evidence is
`build/source-scale-edit-08753-20261028-01/exact-cache/comparison.json`.

The artist's existing **Under collider** hiding policy can avoid fitting roots
whose ground area is covered by a large stone. A development control changed a
roughly two-second broad solve to 174.3 ms while hiding 24,659 rooted groups and
fitting 820 guides instead of 12,552. This changes the requested output; it is
not an equal-output solver comparison. Final-host measurements supersede these
development figures in the qualification.

## Measurement discipline and remaining boundaries

- Contact timings measure CPU command/fit costs. Worker times overlap and must
  not be summed into wall time. Native display callback counts are not FPS.
- Each measured Edit step asserts actual movement and returns to its starting
  position. Warm movement checks preparation/capture/cook/layout counters.
- Orbit checks use real mouse input, visible textured plants, automatic idle
  return and unchanged geometry/transform/owner/pose/binding upload counters.
- Relocating the copied scene broke relative opacity maps. The test loader
  resolves unambiguous assets against the two known model roots before retained
  capture and configures supported default OCIO. It logs changes, rejects
  unresolved assets and never writes the artist input file. Flat-material and
  wireframe controls are labelled separately from original-material results.
- A shader branch experiment did not justify a change and was rejected. The
  production HLSL remains unchanged. This delivery adds no CUDA/OpenCL solver,
  automatic convex hull generator or universal million-object real-time claim.
- Deep overlap can still exceed the existing stem-edge strain quality limit.
  That warning remains observable; a faster update is not proof of botanical
  correctness. Exposed roots and arbitrary collider topology retain their own
  outstanding acceptance.

The knowledge corpus was stale at startup (32/64 enrolled parents fresh).
Current implementation files were inspected directly; no index refresh or
promotion of older qualification is included.

## Final package observations

The final matched package passes 62 native tests and the host-11/12 campaign. Actual Edit dragging uploads zero geometry/binding bytes while a new preparation uploads 4,400,160 binding bytes. Base/receiver/source construction stays cached. Real orbit changes no publication, contact work or buffer uploads and restores idle detail. Planned idle/moving geometry is 27,501,084 / 495,102 triangles. The final broad Inside solid eight-move median is 1,735.55 ms fit; changing to Under collider at the initial footprint gives 157.43 ms, 24,659 hidden roots and 820 fitted guides. This policy control is not an equal-output optimization. See [delivery](DELIVERY_08753.md) and [exact qualification](QUALIFICATION_08753.json); development timings above retain their original scope.
