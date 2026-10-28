# Scene colliders and branch adaptation — 0.87.5.4

This workflow keeps walls, stones and buildings as ordinary Max objects. They
do not need a scatter layer or Cyrus Edit. Plant instances remain procedural.

## Set up

1. Select the Scatter setup and open **Scene colliders**. Use **+** to pick an
   object or **Add selected** to enroll selected scene meshes. **x** removes a
   list reference and keeps the scene object. Missing references remain removable.
2. Select a plant layer, choose **React to colliders**, and prepare its original
   sources once. Use **Edit preparation** if the inferred branch ownership needs
   correction. The prepared source is shared by its scattered instances.
3. Choose **Bend then prune** for the broad architectural workflow. Move, rotate
   or scale an enrolled wall normally in Max. Sources need no new preparation
   merely because the wall moved.

Existing scenes open with **Detailed contact**, preserving their former behavior.
Choose a broad response explicitly when trying this new workflow in an old scene.
The **Scattered colliders** layer role remains available for procedural stones.

## Artist controls

- **Bend branches** rotates prepared guides around their attachments. A branch
  that cannot clear remains visible and is reported as blocked.
- **Prune branches** hides eligible guide subtrees without changing the original
  source. Attached foliage follows that decision. Moving the obstruction away
  restores the original geometry.
- **Bend then prune** tries bending first, then prunes eligible blocked branches.
- **Bend strength** sets the permitted bend search angle, up to 60 degrees at
  100%. This is a bounded pose search, not a dynamic stiffness simulation.
- **Clearance** expands the contact envelope used for bending and pruning.
- **Prune penetration** requires a deeper envelope penetration before a blocked
  branch is eligible for pruning. A larger value retains more shallow contacts.
- **Prune amount** selects a stable fraction of eligible branches. Zero retains
  them; 100% allows every eligible branch. Descendants follow a pruned parent,
  so the percentage is not a promise about polygon count or total crown volume.
- **React to neighboring trees** is opt-in. Both layers must opt in. Stable
  layer and instance identity determine which tree yields; queries use the
  neighbors' rest branches. This avoids feedback flicker. Use ordinary spacing
  for trunk placement; this is not symmetric tree-to-tree physics.

Structural trunks that own branches are protected from automatic deletion.
Keep preparation ownership meaningful: a tree prepared as hundreds of unrelated
leaf roots cannot provide the same branch-level art direction as a branch forest.
The preparation editor can assign fixed pieces and repair guides/attachments.
Ordered circular tube meshes can include triangulated end caps on their existing
end rings. Their width is assessed relative to their length, so a normal tree
trunk is no longer rejected by the earlier 3 cm inference limit. Arbitrarily
welded branch junctions and meshes with unrelated vertex ordering still need
review; this is not universal automatic botanical reconstruction.

## Geometry and limits

Broad adaptation checks simplified guide envelopes, rather than every visible
polygon. It does not certify leaf-level intersection freedom. Inspect close-up
shots, use **Check full visible mesh** when useful, and choose Detailed contact
for the earlier mesh-refinement workflow. A failed detailed solve retains the
last completed result.

Scene colliders must be closed evaluated meshes with nonzero thickness. Positive
nonuniform scale, rotations and mirrored collider transforms use a private
collision copy; the scene object's visible mesh and transform are preserved.
Collapsed transforms are rejected with the prior result retained. Reacting plant
instances still require positive uniform scale. World-space modifiers require a
static collider snapshot because their geometry can depend on world position.

The setup admits 256 scene references and 250,000 vertices / 500,000 triangles per
ordinary scene collider. Optional neighbor proxies and affine copies have a
128 MiB geometry admission, charged to shared viewport memory before construction.
At most 64 relevant obstacle/tree shapes are admitted per plant. Broad pose search
allows 250,000 envelope queries per affected plant. Exhausted searches retain and
report unresolved guides. These are work/memory bounds, not random plant removal.

Detailed contact's Hide covered roots / Hide margin controls apply only to that
mode. Broad pruning uses Clearance, Prune penetration and Prune amount instead.

Use **Scene presets** to preserve this setup, including ordinary collider
references. Portable recipe 9 currently supports the earlier Detailed contact
settings; unsupported broad-response or scene-collider captures are rejected
explicitly. Imported older recipes retain their original Detailed behavior.

## Trial installation

The combined EXE in the delivery report contains distinct Max 2024, 2026 and
2027 payloads. Close the Max versions selected for installation, run the EXE,
then reopen Max. Keep your existing shared Library; its content version remains
0.86.7. The EXE does not include a new model-library download.

Alternatively, run the MZP matching your Max year through **Scripting > Run
Script**, then restart Max. Do not mix a new script with old native modules.
Runtime testing for this delivery covers Max 2027 only. The older hosts were
not launched: Max 2024 has SDK/native checks, and Max 2026 has compilation only,
as requested. Native Scene presets remain a Max 2027 feature. Portable recipes
retain their earlier supported scope.

Saved grass, fern and generated branch-tree trial copies are linked in the
delivery report. The fern trial uses Mesh display so its optional renderer
materials are not required for inspecting the interaction. These copies do not
replace the original artist input.
