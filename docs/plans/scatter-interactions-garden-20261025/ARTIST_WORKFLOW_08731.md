# Interactions — 0.87.3.1

The [preparation correction](PREPARATION_FIX_08731.md) is the current tested Max 2027 package. Earlier build-only notes below describe the original delivery and are superseded for the correction's exact tested cases.

This Max 2027 update is prepared for artist testing. Native and host tests were
deferred at the user's request. Use the [matched package](DELIVERY_08731.md), run
it through **Scripting > Run Script**, then restart Max. The native bending change
requires the matching modules; a loose script cannot update the fitter.

## Prepare and interact

1. Set the sphere/stone layer to **Collider**. Closed geometry uses **Original
   closed mesh**, with no separate analysis or extra pick. Detailed trees may use
   a separate trunk/custom collider while retaining their full visual geometry.
2. Set the grass/flower layer to **React to colliders**. Select an original source
   in the Interactions list and click **Prepare model**. Repeat for any additional
   unprepared source models. Each unique source definition is reused by its
   scattered copies, including their supported rotations/scales/translations.
3. Move a collider instance with **Cyrus Edit**. All contacting guides enter the
   fitter. A root merely below a collider no longer causes its blade to be skipped.

Preparation stores usable guides immediately; no Accept step is needed.
**Show source guides** and **Frame source** are optional inspection tools.
Interactions hover tooltips have been removed; on-panel status text remains.

## Settings update automatically

- **Minimum stem / Branch connection:** automatically rebuild already prepared
  sources in the layer. No repeated Prepare/Accept sequence is required.
- **Preparation limits:** automatically revalidate/rebuild the prepared source
  realization using saved guides. Raising a limit permits more work; it does not
  change source geometry or make analysis faster.
- **Refinement stiffness / Contact gap / Hide roots / Preview percentage:** update
  contact/display data automatically. Blade preview remains 1–100%.
- **Prepare model:** prepares a new source or explicitly re-prepares a changed
  source. A failed source remains reported, with previous definitions retained.

Updates may take preparation time for heavy sources. Unchanged browsing does not
request another analysis. Manual pending scatter Amount/seed/surface edits still
wait for **Update scatter**; contact/preparation edits use the completed scatter.

## Optional hiding

**Hide roots inside colliders** is off for new layers. Existing saved choices are
retained. With hiding off, no rooted group is intentionally removed. With hiding
on, a rooted group is excluded only when its fixed root point or root anchors
intersect the solid or its **Contact gap** boundary. The old overhead-footprint
rule has been removed. Gap therefore increases root exclusion only when hiding
is enabled; otherwise it requests bending clearance.

A collider enclosing a fixed root, or a gap crossing its fixed anchors, cannot be
resolved by bending alone. With hiding off this now reports an explicit conflict
and retains the previous complete contact result. Move the collider, reduce Gap,
or enable optional hiding. Failed fits do not silently delete stems. Geometry,
work and memory admission still report explicit failures rather than skipping a
fraction of the plant.

For the first test, keep the sphere's bottom above the roots and move it through
the blades. Try hiding both off and on; hovering contact should retain those roots.
Then lower it into the roots and test the explicit hiding option. Move it away to
check restoration. Renderer fidelity, natural bending, Undo/Redo and large-scene
performance are artist checks for this build.
