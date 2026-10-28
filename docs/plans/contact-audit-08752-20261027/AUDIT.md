# Correctness, necessity and cost — 0.87.5.2

## What this audit establishes

The current contact pipeline can avoid substantial repeated work while producing
the same accepted poses. This is a scoped finding for the admitted geometry,
captured models and movements below. It does not prove every plant, collision
proxy or future edit is correct, or that all remaining work is necessary.

The baseline is the complete 0.87.5.1 Scene preset delivery. A dedicated source
snapshot preserves pre-existing changes before this task. Max 2027 is the only
host used. Interactions 12, schema 63, portable recipe 9, Scene preset metadata 1
and Edit/storage 3 remain unchanged.

## Work decisions

| Operation | Why it exists | Audit result / decision |
| --- | --- | --- |
| Source capture, preparation and collider BVH construction | Validate copied geometry, bindings and units | Keep by relevant source revision. Zero during the observed warm passive actions and physical drag. |
| Plant and collider indexes | Find possible contacts without scanning every detailed mesh | Keep immutable base indexes and bounded edited-obstacle index. Old and new collider surroundings must both be revisited to restore plants. |
| Root coverage and fixed-root face checks | Separate intentional hiding from impossible anchored contact | Keep. A root point alone cannot prove its whole anchored face is clear. |
| Guide-capsule queries and bounded hinge search | Find a rooted candidate cheaply | Keep. They do not replace detailed broad-leaf surface validation. |
| Every-vertex solid classification in each exact candidate | Detect containment | Reduce to one point per certified connected component, including unused vertices. All triangle surface checks remain. |
| Triangle-to-local-vertex searches | Reconstruct exact candidate triangles | Cache addresses once in the immutable source. No repeated binary searches during dragging. |
| Repeated identical ring/leaf attachment interpolation | Transform exact candidate vertices | Reuse the immediately preceding identical span/u or part within that candidate. No approximate interpolation or cross-pose reuse. |
| Full visible-mesh audit | Independently inspect delivered polygons and root/edge errors | Keep as an explicit check. It is not automatically run over the whole scene on each pointer sample. |
| Source geometry uploads | Draw real source triangles | Keep cold uploads, reuse warm buffers. Actual held-pointer check uploads zero source geometry. |
| Pose and sparse transform uploads | Draw the accepted local successor | Keep for changed poses/instances. Physical drag records three native successors and 238,784 pose bytes. |
| Preview timing | Explain actual preparation cost | Fix: preserve the last build duration; report cached reads separately. A later cheap read must not overwrite a costly build measurement. |

The exact component proof, cache ownership, memory cost and failure boundary are
in [the implementation plan](PLAN.md). Numerical workers make no Max calls;
every complete successor still passes the existing atomic publication boundary.

## Correctness evidence

The new component predicate is tested against analytic axis-aligned box
containment and exhaustive triangle distance for 6,000 deterministic varied mesh
cases. Explicit cases include disconnected enclosed components, an unused
interior vertex, triangle-interior contact with all vertices outside, invalid
indices and work-budget exhaustion. Existing tests retain rotated/scaled
witnesses, clearance, roots, broad faces, parallel ordering and failure behavior.
The exhaustive face oracle shares low-level geometric primitives, while the box
containment oracle is independent of the BVH/parity code; neither is presented as
a separate general-purpose collision engine.

Captured grass, Brainea Insignis fern and authored Neottopteris inputs replay
14 movements each. Old/new pose digests match at every captured state. The dense
1,000-plant fixture also matches exact pose digests, hiding and quality warnings
in alternating old/new/new/old producer runs. These comparisons demonstrate
preservation, not botanical correctness.

On the final installed Max pair, natural grass, fern and authored fixed-base
contacts pass complete visible-mesh audits. Bake preserves the authored plant's
183,030 visible triangles. Physical Cyrus Edit dragging, Undo/Redo, invalid-gap
retention/recovery, complete hiding including box preview, Manual pending edits,
save/reopen and independent Scene preset save/merge pass.

The unchanged production HLSL math is compiled/read back again on hardware:
2,412,954 corners, zero visibility mismatches and maximum source-space error
1.3328e-7 m against canonical CPU geometry. GPU/CPU agreement is a delivery check;
the independent geometric controls above are needed to assess correctness.

## Measured cost

The final alternating numeric benchmark uses the same 1,000-plant fixture and
14 moves per process on a Ryzen 5600X. Median-of-run-medians falls from
**100.3062 ms to 78.7602 ms**, a **21.48%** reduction. In the first paired runs,
summed detailed-check worker time falls from 2,401.23 to 1,192.34 ms and point
classification time from 895.19 to 58.00 ms. Summed worker time is not elapsed
wall time; these figures include the initial evaluation plus 14 updates.

Actual final Max movement callbacks have medians of **37.38 ms for 200 plants**
and **111.84 ms for 1,000**, including native publication preparation. First
redraw command medians are 13.36 / 14.82 ms. These are CPU command measurements,
not presented FPS, isolated GPU timings or guarantees for other scenes. Earlier
baseline host runs overlapped other work; use the alternating numeric comparison
for the controlled improvement claim. Timing varies with contention and warmth.

Warm idle, camera/FOV changes, selection changes and unrelated animated Point
movement produce zero new captures, preparations, cooks, layouts, contact fits,
placement epochs and geometry/transform/pose/binding uploads. The physical drag
adds three evaluations/fits and no source work or layout reconstruction.
This does not measure every library panel, renderer callback or source-edit case.

## Remaining issues and next useful work

The dense/deep stress audit is **not a visual-quality pass**. Its 588,355 visible
triangles have zero penetrating vertices, zero touching triangles and zero root
anchor error, but some stem edges exceed the existing 25% strain threshold.
A separate diagnostic finds an approximately 0.840 mm edge becoming 4.756 mm:
about **3.915 mm absolute change**, so this is not merely a harmless percentage
on an infinitesimal edge. The old/new digests and warnings match; the limitation
predates this optimization. A subsequent solver/mapping repair should improve
that basal chart while retaining clearance and anchors, rather than suppressing
the warning or hiding the leaf.

Palette/material changes can still invalidate more source display data than
necessary. Sparse per-guide pose packing and cross-layer GPU deduplication remain
possible follow-ups. They need separate invalidation/memory measurements before
changing the existing retained generations. Exposed-root collider fitting remains
on hold. No CUDA solver, hull-approximation feature, arbitrary-scale support,
production renderer qualification, million-object FPS or older-Max support is
claimed by this patch.

Development records include an intentionally edited regression rig whose derived
topology initially needed rebuilding, passive presentation checks attempted on
minimized Max windows, a missing relative texture path in the private Library
fixture and a managed-save poll before completion. These are separated from the
final passing receipts. No artist scene/profile or original asset was modified.
