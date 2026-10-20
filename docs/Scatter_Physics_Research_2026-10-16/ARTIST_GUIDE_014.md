**Current standalone workflow:** [0.2.0 artist guide](ARTIST_GUIDE_020.md) and
[technical qualification](BAKE_WORKFLOW_020.md). The [0.1.9 repair](STABILITY_UI_019.md)
and this document's 0.1.4 body/receipts retain their historical scope.
**Current completion workflow:** [0.2.0 artist guide](ARTIST_GUIDE_020.md). Finish/Freeze now bake independent Editable Poly colliders; this versioned 0.1.4 text remains historical.

# Physics Lab artist guide

For current controls and scenes use the [0.2.0 artist guide](ARTIST_GUIDE_020.md).
This page remains the explicitly versioned 0.1.4 foundation below.

**Version 0.1.4 · Max 2027 · 17 October 2026**  
[Documentation home](DOCUMENTATION.md) · [Troubleshooting](DIAGNOSTICS_GUIDE_014.md)

## What you can make

Physics Lab places rigid assets by brushing them onto a surface and letting them
collide. Typical experiments include leaves on a pavement, small stones around a
curb and rigid street debris. A leaf remains a rigid shape: this version does not
simulate flutter, bending, cloth or wind.

A Physics Lab node owns one receiver, a list of source models, static colliders
and its own result. The output is combined geometry managed by that node. The
tool does not create an independently editable Max scene node for every body.
It remains separate from CyrusScatter and its display/instancing pipeline.

## Install and prepare

1. Run the [0.1.4 MZP](../../dist/CyrusPhysicsLab-0.1.4-20261017-03/CyrusPhysicsLab-0.1.4-Max2027.mzp)
   through **Scripting > Run Script**. Save your work, then restart **Max 2027**.
2. Create **Geometry > Cyrus Labs > Cyrus Physics Lab**. Select it through Scene
   Explorer if it has no visible geometry yet, and open the Modify panel.
3. Under **Objects**, pick a receiver. A simple horizontal Plane is a useful
   initial scene. Leave **Receiver collides** enabled unless another mesh supplies
   the intended physical support.
4. Use **Add...** under Models to add a source. A normal detailed sphere can use
   automatic collision geometry. It does not need a manually simplified copy.
5. Add any static obstacles with **Add collider...**. A receiver and a collider
   have different roles: the receiver controls where births are allowed; collision
   geometry determines where already-born objects can move and come to rest.
6. Set the values under **Brush**, then press **Start brush**.

All brush distances are **metres**, even when Max displays millimetres or
centimetres. Radius `0.25` is 25 cm; thickness `0.002` is 2 mm. Check the physical
size of your assets before judging the drop height or contact gap.

## First continuous session

Drag on the receiver and release. Earlier bodies continue moving. Draw another
stroke immediately: both strokes participate in the same live world, so new
bodies can push bodies from the earlier stroke.

Emission uses distance along the stroke. Holding the cursor still does not keep
spraying more bodies, although simulation continues. Releasing the mouse ends
that gesture; it does not finish the session.

When the composition looks right, choose **Finish** to let it settle or **Freeze**
to keep its current positions. Save the MAX file to preserve the scene on disk.

## Session controls

| Control | What it does | What remains available |
| --- | --- | --- |
| **Start brush** | Captures the current setup and opens a new live world | Further strokes can interact with all pending bodies |
| **Pause** | Stops simulation and leaves the brush | Pending bodies and stroke history are retained |
| **Resume** | Continues the pending world after validation/recovery as needed | Existing pending bodies continue participating |
| **Finish** | Stops emission, waits for the quiet-motion criterion and publishes | A completed result, recorded as one ordinary Max Undo operation |
| **Freeze** | Publishes current poses immediately | A completed result marked as not certified settled |
| **Undo stroke** | Pauses and restores the whole world to before the last stroke | Earlier bodies return to their earlier poses and motion state |
| **Redo stroke** | Restores the later world captured by Undo | Resume to continue simulation or brushing |
| **Cancel session** | Discards pending strokes | Earlier completed output remains |
| **Open logs** | Opens the local diagnostic recording directory | Logs and recovery files can be preserved for investigation |

Right-click and closing the panel also pause the session. Saving or rendering
pauses continuous brushing. Reopen the panel and use Resume when appropriate.

Completed sessions become **fixed collision obstacles** during the next session.
They do not wake up when a later session touches them. Keep gestures within one
session when you want all those bodies to continue interacting. Use the explicit
Rebuild operation when you deliberately want to resimulate the recorded result.

## Brush settings

| Setting | Default | Meaning and practical effect |
| --- | ---: | --- |
| Radius | 0.25 m | Size of the footprint around a path sample |
| Spacing | 0.08 m | Travel distance between births; smaller values create bodies more densely |
| Height | 0.4 m | Drop height above the receiver; spawn handling can lift a body further to avoid immediate overlap |
| Min / Max scale | 0.8 / 1.2 | Random uniform size range for each birth |
| Seed | 42 | Controls emission variation; it is not a promise of identical results across changed inputs or solver builds |
| Body limit | 1,000 | Admission setting for completed bodies plus births in the pending session |
| Friction | 0.6 | Contact friction used by the lab solver |
| Bounce | 0.05 | Restitution used by the lab solver |
| Thickness | 0.002 m | Thickness policy for preparing eligible thin/open collision proxies |

Friction, Bounce and Thickness are under **Collision and proxies**. Settings and
bindings lock while a session is pending, including while paused. Finish or
Freeze to keep that work, or Cancel to discard it, before editing the setup.

### More than 1,000 objects

Set **Brush > Body limit** above 1,000, up to the current maximum of **5,000**.
If a session is already pending, Finish or Freeze it first, change the setting,
and start another session. Completed bodies still count; Finish does not reset
the node's body allowance.

The limit is an admission boundary, not a target that the brush fills
automatically. Lost births still count toward the current session's authored
history, and the saved recipe has a separate 5,000-birth cap. Consequently, a
scene can reach a limit while displaying fewer bodies. Geometry and history
budgets can also stop admission before the selected body count.

Increasing this number does not increase every other budget. A detailed source
can hit the combined output-geometry limit sooner. A 5,000-body low-poly stress
test passed, but it did not establish equal responsiveness for dense piles or
complex assets. See [performance evidence](VALIDATION_REPORT_014.md#performance-measurements).

## Brushing beyond the receiver

When the cursor misses the receiver, births stop and the stroke path breaks.
Re-entering starts a new segment: the tool does not fill a bridge across the gap.
If only part of the brush disk extends past the edge, unsupported candidates are
skipped. An entirely empty outside gesture does not add a live Undo entry.

Already-born objects can roll or be pushed off a finite surface. Once a pending
body is wholly below the lab's removal plane beneath all colliders, it is removed
from simulation. A lower supporting collider remains valid; the tool does not
delete a body merely for being below the receiver. Removal participates in live
Undo/Redo and is recorded in diagnostics.

Clipping emission to the receiver does not fence the simulation to that surface.
Use physical static obstacles if you want to contain moving bodies.

## Render models and collision proxies

The rendered model and collision shape serve different purposes. Automatic
proxies preserve the render geometry while providing a bounded convex shape for
physics. Detailed automatic sources above 128 input vertices use a conservative
approximation with at most 192 collision vertices. Ordinary detailed spheres are
supported through this automatic path.

Choose **Pick...** under Collision and proxies for a custom collision mesh.
Custom inputs are limited to **128 vertices before thickening**. Keep the proxy
pivot, orientation and scale aligned with the render model. **Use auto** removes
that override. The 128-vertex custom-proxy limit is not a limit on the render
model or receiver Plane.

Dynamic collision shapes are convex. A hole or concavity in a render asset may
be filled by its proxy, and an automatic proxy can leave a visible gap around
curved detail. Open meshes receive a thickness envelope; rendered curvature is
retained. Opacity maps do not cut away collision geometry. For an alpha-card
leaf, provide an explicit silhouette proxy when the rectangular card gives an
unsuitable collision outline.

Sources currently require one material; UV channel 1 and smoothing groups are
retained. Multi/sub materials, additional UV channels and explicit normals are
outside this delivery. Inputs are static: animated/deforming colliders and
two-way motion of scene objects are not supported.

## Undo and changing the scene

Use **Undo stroke / Redo stroke** for pending gestures. If stroke B knocks bodies
from stroke A, undoing B restores A's earlier positions, velocities and sleep
state too. Merely deleting B would leave a different physical world.

Use Max's ordinary **Undo/Redo** for a completed Finish/Freeze result. Global Undo
pauses live work. If it removes the completed base that pending work depends on,
that pending session is discarded to avoid combining incompatible states.

Changing a receiver, source, collider, owner transform or system units can
invalidate pending authoring. Review the copied preview, then Freeze it if that
is the desired result, or Cancel and prepare a fresh session. A normal open/merge
unit conversion is accepted only when recapture verifies the same physical inputs.

Moving a completed lab object moves its composition. Before adding work in a
different origin/unit frame, use explicit Rebuild or Clear. Authoring requires
the lab object's rotation and scale to be reset.

## Results, procedural areas and files

| Operation | Use it for | Important behavior |
| --- | --- | --- |
| **Rebuild all strokes** | Deliberately solve the recorded births again against current bindings/settings | Previously completed bodies may move; a changed build is not guaranteed to reproduce old poses |
| **Erase nearby...** | Remove completed bodies around a picked centre | Survivors stay fixed; ordinary Max Undo is available |
| **Clear result** | Remove the saved composition | Ordinary Max Undo restores it |
| **Settle area** | Generate a bounded population from receiver coverage or an optional boundary | Replaces the previous result only after completion |
| **Save... / Load...** | Exchange a native JSON result snapshot | Materials, bitmaps and live scene bindings are not embedded |
| **Recover session...** | Load the last durable live-session record after interruption | Restore from the saved MAX scene and review the preview before Resume/Freeze |

Complete or cancel pending brush work before running separate result operations.

Physics Area uses upward-facing receiver triangles without a boundary. Its
optional boundary is a closed world-XY polygon spline with corner knots. Convert
parametric shapes to Editable Splines first. Curved Bezier boundaries, multiple
loops and CyrusScatter Paint documents are outside this separate workflow.
Bodies can move outside the birth boundary after emission.

Save a **MAX scene** for the full handoff: object, sources, bindings, controls and
materials. Reopening displays cached geometry without automatically simulating.
Pending scenes can Resume with the matching solver build and valid inputs, or
Freeze the cached preview. Keep the installer and external bitmap assets with
the scene's backup.

Result JSON contains cached geometry, poses, settings and birth history. Loading
it retains the current node's editable controls and does not reconstruct live
scene references or material assignments. Review and rebind them before new
authoring. Result JSON and live-recovery JSON are different file types.

## A useful acceptance session

1. Start with a simple Plane, a sphere and one additional static obstacle.
2. Draw several strokes while earlier bodies are still colliding.
3. Leave and re-enter the surface, including a partially overlapping brush disk.
4. Undo a stroke that pushed older pending bodies, then Redo and Resume.
5. Pause, save, reopen and Resume with the same build.
6. Finish, use ordinary Max Undo/Redo, then start a further session and confirm
   the earlier completed bodies act as fixed obstacles.
7. Repeat with the intended leaf model and proxy, then increase the population
   gradually while observing response and contact quality.

This is a suggested artist test sequence, not a statement that every step was
already accepted on the artist's setup. Preserve **Open logs** if anything differs
from these expectations. The [diagnostics guide](DIAGNOSTICS_GUIDE_014.md) explains
what to send and how to recover.

Implementation references: [UI](../../CyrusPhysicsLab/scripts/CyrusPhysicsLab.ms),
[core](../../CyrusPhysicsLab/src/core.cpp),
[continuous session](../../CyrusPhysicsLab/src/live_session.cpp),
[host lifecycle](../../CyrusPhysicsLab/src/max_live.inc), and
[delivery ledger](CONTINUOUS_BRUSH_014.md).
