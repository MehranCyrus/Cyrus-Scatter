# Physics Lab 0.2 — artist workflow

**Current installer: 0.2.1.** The [small baked collider repair](COLLIDER_COOK_021.md)
fixes the millimetre-scale teapot Fast → Finish → Detailed → Start failure.
It preserves this workflow and existing baked geometry. Finish/Freeze/Cancel any
pending session before upgrading; the new solver has its own recovery fingerprint.

Keep the Lab separate from CyrusScatter. Install its Max 2027 MZP with **Scripting
> Run Script**, save work and restart Max 2027. The supplied testing kit includes
the installer, mountain scene and this guide.

1. Create/select **Geometry > Cyrus Labs > Cyrus Physics Lab**. Pick a receiver.
2. Add models with **+**; **x** removes the highlighted binding. **Replace...**
   changes it. Tick the small checkbox to enable a model. Clicking its name only
   selects settings. Clicking empty list space changes nothing.
3. Set Fast, Balanced or Detailed for the highlighted model. Moving objects use
   convex collision pieces; Detailed is tighter but still approximate. Use
   **Show shapes** to inspect them. Assigned single materials are retained;
   unassigned models use their viewport colours.
4. **Start brush**, drag on the receiver and release. Keep drawing while earlier
   bodies move. Outside the receiver emits nothing. Pause/Resume preserves the
   live world. **Undo stroke** restores the whole live world before that gesture;
   **Redo stroke** restores its captured state.
5. **Finish** waits for settling, then creates one selectable Editable Poly named
   Physics_Baked_*. It is automatically a static collider for new strokes. If
   settling reaches its bound, **Freeze** bakes current positions, including any
   remaining overlaps. Finish does not immediately force moving bodies to sleep.
6. Change model quality and brush again. Baked batches keep their geometry and
   positions; the new quality affects the new moving objects. New objects collide
   with the polygon surfaces of earlier batches.

Use ordinary Max Undo/Redo to remove/restore an entire completed batch together
with its collider binding. Edit or move baked geometry normally; the next Start
recaptures it. Deleting a baked node removes that obstacle. Deleting the Lab keeps
the ordinary baked geometry. Save the **MAX scene** to retain all batches. JSON
export, Clear and Rebuild operate on retained procedural data, not baked nodes.
Remove/unlink a material intentionally through normal Max tools; editing shared
material contents affects every object using that material.

Pending sessions lock model/quality settings. Finish, Freeze or Cancel first.
No fallback is assigned to original source objects, and no separate node is made
for every sprayed body: each completed session is one combined Editable Poly.

There is a shared 200,000 collision-triangle budget and a 64 collider limit,
including the receiver. High-detail meshes can reach it before the body limit.
A rejected bake keeps the preview and reports the budget. Cancel it and reduce
batch density/source detail, or use a separate Lab. Existing baked nodes remain.
The teapot's dynamic handle opening can still be filled by its convex proxies.

For manual acceptance, open PhysicsLab-0.2.0-Mountain-Test.max and select
PhysicsLab_Brush_Ready_020. Spray Pyramid, Sphere and Teapot separately and mixed,
Finish a small batch, switch quality, spray across it, Undo/Redo the new batch,
then save/reopen. Baked comparison batches are already present in the scene.
See [technical qualification and limits](BAKE_WORKFLOW_020.md) for automated scope.

## Small baked-collider error in 0.2.0

The generic `Jolt collider cook failed` after Finish could be caused by small
valid triangles being discarded during static mesh preparation. Changing to
Detailed exposed the next Start; its dynamic hull cooking was not the failing
stage in the recorded teapot case. Install the [0.2.1 correction](COLLIDER_COOK_021.md).
Cancel a failed pending session before saving/upgrading; keep the baked poly
nodes. You do not need to clear those batches or enlarge your scene to work
around this particular defect. The new version validates the baked collider
before publication and records a specific reason for unsupported geometry.
