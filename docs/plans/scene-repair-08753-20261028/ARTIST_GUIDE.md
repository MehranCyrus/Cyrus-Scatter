# Using the Test22 fixes — 0.87.5.3

Install the complete Max 2027 MZP with **Scripting > Run Script**, then restart
Max. The package, trial scene and measured qualification are linked from
[the delivery](DELIVERY_08753.md). Existing prepared guides can be reused; this
patch does not require preparation solely because its version changed.

## Add, remove or replace a collider

1. Select its Scatter layer and choose **Collider** in Interactions.
2. Add the stone through **+** in either source list. Both lists show the same
   layer sources automatically.
3. To replace a source, select its row in **Models & Points**, choose **Pick
   object**, then pick the replacement. Its row/settings survive; an incompatible
   old preparation or custom collider link is removed for that row only.
4. **X** removes selected authored rows, including a missing/deleted model or
   Point/Empty row. It does not delete the original scene geometry. An empty
   layer can retain its Collider role for the next source.

Use the original closed mesh for an admitted closed stone. A plant/tree with
foliage can still use its separately built trunk/custom collider. This patch does
not automatically create a convex hull for arbitrary stones.

In **Live**, relevant source changes update automatically. In **Manual**, the
lists show pending source edits while the previous complete scatter stays visible
until **Update scatter**. Source add/remove/replace commands support Max Undo and
Redo, including their preparation/custom collider bindings.

## Scale and move

The scattered size now includes the source node's manual scale as well as Models
Scale. For example, node scale 0.2 with Models Scale 0.5 gives 0.1 before the
layer's random scale. The source's location and rotation retain their existing
placement semantics.

Earlier builds omitted node scale, so existing scenes with scaled source nodes
can change size when recalculated. Use the supplied copy to compare the corrected
result. Do not compensate by resetting or destructively editing the original
mesh. Contacts require a positive uniform source/instance scale; unsupported
mirrors, shear or collapsed transforms report a retained-result error.

Move individual scattered stones with **Cyrus Edit > Instances**. Changing Models
Scale afterwards now keeps the instance identities and authored Edit deltas.
An unrelated source/recipe incompatibility can still require explicit repair.

## Large stones and dense grass

For ground which a stone covers, enable **Hide roots inside colliders** and choose
**Under collider** for its hiding area. **Hide margin** changes the cleared area;
**Contact gap** changes bending clearance independently. This can avoid spending
time bending thousands of roots under a large rock. Use **Inside solid** when
you want the narrower solid-interior policy instead.

For orbiting, open **Viewport & render** and click **Fast navigation**. Moving
views use a 500,000-triangle limit; idle detail stays as configured and returns
automatically. This draws a subset of complete instances during navigation.
It does not lower placement counts or final render detail. Set the moving limit
to zero to request unlimited drawing again. Idle triangles and Preview leaves /
blades remain separate controls.

A thousand 27,501-triangle grass clumps represent roughly 27.5 million drawn
triangles. Shared geometry saves memory and upload work, but drawing all those
triangles and solving a deep broad overlap still has a cost. The viewport limit
and Under collider policy address different parts of that cost.

## Errors and limits

The eager combined 1 GiB render estimate no longer blocks a lightweight viewport
update. Exact render/Bake mesh construction uses bounded complete batches.
External renderers which request only one combined mesh still have a combined
construction limit, and total renderer memory is not bounded by the batch target.

A failed successor keeps the previous complete display. Read its reported source,
transform, topology or resource error before retrying. Deep-overlap stem-edge
quality warnings remain; this patch does not claim arbitrary topology or unlimited
real-time density. The [audit](AUDIT.md) distinguishes equal-output optimizations,
explicit preview choices and changes to the hiding policy.
