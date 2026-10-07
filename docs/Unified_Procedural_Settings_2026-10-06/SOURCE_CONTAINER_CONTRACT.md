# Source container contract

6 October 2026. User-agreed behavior plus explicitly identified implementation recommendations. **The current 0.72 ordinary rectangles do not implement labels, linked Modify editing or group movement.**

## Artist workflow

1. Select a layer or paint set and create a **Cyrus Source Container**. Global containers remain available for shared source pools.
2. Place mesh models inside its rectangle. Pivot inside the container's local XY boundary means active; height is ignored, as today.
3. Read the label beside it, for example `Trees | Layer_01 / Base | 2 active / 3 saved`. Details list active and parked sources. A shared container states its multiple consumers; counts always identify their scope.
4. Select the container to edit its linked Scatter setup/layer/set in the main Modify panel. The rectangle remains selected so moving/resizing still operates on it. A small Container section holds boundary/owner information; **Edit layer** remains an optional popup using the same model.
5. Move the container to carry its active managed source models. These are palette models; their scattered instances do not move.
6. Drag a source outside to park it. Its per-layer/set weight, radius, scale, offset, forward axis, color and other authored values survive. It stops following that container. Drag it back to reactivate the same saved record.
7. Resize Width/Length to change membership; resizing does not scale or move sources. Manual keeps the previous complete scattered result until Update; Live coalesces relevant edits into a new publication.

## Two separate relationships

**Usage:** any supported layer/set can consume a source through a global, inherited or own pool. The same scene geometry can have different saved settings in different sets. A parked record stays in its owning set, including its source identity; registration is not compacted and parked weights are not redistributed merely because the model crossed a boundary.

**Movement:** a scene model has at most one container movement owner, independent of how many sets use it. Moving one shared container moves each physical source once. Overlapping rectangles never acquire it repeatedly based on scene iteration order.

Recommended overlap rule: retain an existing movement owner while its model remains inside; on entering an unowned pool assign the unique containing container. If several containers compete, retain source usage but expose the movement conflict and let the artist choose the owner. Do not arbitrarily choose the first enumerated node. Returning to the previous container restores following when it is still an eligible, unambiguous owner. Rotation/scale following, bounding-box inclusion, volume inclusion and combining several meshes into one scatter asset are outside the agreed first translation slice.

## Scene node and Modify integration

Create a small dedicated non-rendering container helper with a supported rectangular frame and cached label. Add a frame adapter for it; today's [Rectangle-only guard](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/source-containers.ms#L25) must be changed deliberately. Avoid an ordinary Rectangle plus a full second Scatter modifier/evaluator.

Autodesk provides [HelperObject](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_helper_object.html) for helper plugins and exposes the command-panel edit lifecycle. This supports the proposed direction; it does **not** prove that forwarding the current scripted rollouts while keeping a different helper selected works correctly. The first isolated prototype must qualify entry/exit, warm retargeting, shared owners, selection changes, scene reset and Undo. Reuse the existing editor factories/binding model with explicit owner context rather than constructing a layer UI for every rectangle.

Store durable scene identities/references with clone/delete/Undo semantics. Do not persist only an animatable handle or Python/SDK pointer. Controller/container back-links must not create a strong dependency cycle; choose a single ownership direction and resolve the reverse relationship through bounded cached lookup. Autodesk's [ReferenceTarget contract](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_reference_target.html) explicitly provides cycle testing; the return convention deserves verification in the implementation rather than an assumed boolean meaning.

For a shared container, display a controller/layer/set selector and remember the editing context as presentation state. Selecting another consumer changes the view, not source membership, calculations or stored per-source settings. When an owner is deleted, keep the container/models and show an unlinked state. No unguarded callbacks can edit a previously selected owner.

Recommendation for existing ordinary Rectangle input: a **Create from rectangle** authoring action copies its frame/dimensions into a new Cyrus container and leaves the input scene node untouched. This is a normal creation aid, not ongoing support for old saved Scatter schemas. Do not silently replace an artist spline or attach a forbidden modifier. The new helper is the selected source container whose properties appear in Modify.

## Moving the source palette safely

At the beginning of a container translation, capture its initial transform, current movement recipients and their initial world transforms. Apply each update from that fixed start state; never accumulate deltas against an already moved node. Freeze the recipient list during the drag so an object crossed by the moving boundary is not suddenly swept into the operation. Reconcile enrollment/membership once the transform operation commits; cancellation restores the starting state.

Do not automatically parent all geometry to the container. Existing groups, parent hierarchies, constraints, instances, locked transforms and animated controllers must retain their relationships. Autodesk's [INode hierarchy API](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_node.html) makes attach/detach and transform preservation explicit; using it does not eliminate double-transform or controller risks.

Treat an existing wholly managed group/hierarchy as one movement unit when supported. A parent and its descendant must never both receive the same translation. A partially managed/locked/constrained hierarchy must fail preflight with an actionable status or remain explicitly excluded from following; never break the group or rewrite animation silently. The first supported scope is ordinary editable static source models and validated groups, not arbitrary animation controllers.

Container move and all accompanying source translations form **one Undo action**. Failure restores every changed transform, movement link and membership revision; there is no half-moved palette. Undo/Redo and save/reopen must restore identical participation and per-owner settings. A combined selection containing the container and its sources must not move them twice.

Pure palette translation must leave placement candidate IDs, accepted transforms, Brush field, Edit/radius bindings and retained placement buffers unchanged when membership and source geometry are unchanged. Source object-space geometry, scale/material edits and real membership changes remain relevant. Test source geometry whose object-space evaluation depends on its world position; such an input is a real geometry change, not automatically a harmless palette move. Do not bypass dependency validity for every source-transform event to meet a counter target.

## Event, cache and reporting contract

| Event | Allowed work / expected result |
| --- | --- |
| Select container, change editor topic, expand/collapse, hover | Bind cached values/owner and draw cached label. No enrollment, solve, Brush replay or placement upload. |
| Rename container/layer/set; change label visibility/style | Invalidate text/presentation only. |
| Move source within same container | Update relevant pivot/movement bookkeeping. No placement change solely from source translation, unless source geometry really changed. |
| Translate container with unchanged managed membership/geometry | Apply source movement, refresh boundary/label transform, reuse the same scattered publication. |
| Source crosses boundary or Width/Length changes participation | Retain records; update relevant membership. Manual reports Pending; Live evaluates the affected recipe and downstream consumers once settled. |
| Enroll a genuinely new source | Append one durable source record with defaults; source correspondence/recipe changes honestly. |
| Real source geometry/material/scale or receiving-surface change | Use the existing dependency path and invalidate only the required preparation/display/publication stages. |
| Unrelated animation, idle popup, redraw/navigation | No full scene scan, placement regeneration or upload of an unchanged generation. |
| Delete/unlink a container | Keep source models and settings. Reconcile the pool and movement relationships transactionally; missing links are explicit. |

The current relevant-event path is [source-containers.ms:125](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/source-containers.ms#L125) and time validity includes container dependencies at [input-time.ms:27](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/input-time.ms#L27). Extend those paths; do not add a continuously active membership timer. Enforce the existing 32-container/pool and 1,024 registered-source limits unless a separate measurement justifies changing them.

Use the existing bounded diagnostics recorder for container movement begin/commit/cancel, membership change, ownership conflict and failure reason. Emit one summary per action/batch, not per vertex/model on every frame. Cached labels and MCP reads expose pending/unavailable state honestly and never reconcile the scene merely to answer an inspection request.
