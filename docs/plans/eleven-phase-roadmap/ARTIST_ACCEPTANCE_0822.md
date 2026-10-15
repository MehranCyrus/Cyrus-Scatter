# Artist testing — Cyrus Scatter 0.82.2, Max 2027

14 October 2026. Phases 1–5 are implemented. Their corrected labels are 0.81.8,
0.81.9, 0.82.0, 0.82.1 and 0.82.2. Phase 6 stays paused. These are manual
acceptance steps for the cumulative 0.82.2 installer; you do not need to install
five separate versions.

## Start here

1. **Save your work and restart Max 2027.** The installation was updated on disk
   while your existing Max session remained open with 0.81.6 modules loaded.
   Restart loads the new scripts and native engine together. The Modify panel
   should say **Cyrus Scatter 0.82.2**. If it shows an older version or reports a
   native mismatch, stop and report it before testing. Do not run a loose script
   over the old loaded modules.
2. Begin in a new test scene. Add a roughly 30 × 30 m plane, create a Scatter,
   add a named layer **A**, assign the plane, and use **Add Point** in Models &
   Points. Choose **Candidate budget**, a Count around 2,000, and a fixed seed.
   Disable spacing/Relax/cleanup restrictions for the initial visual comparisons.
   Keep **Manual** on and press **Update scatter**.
3. Add a second named layer **B**, preferably on a separate plane, with a visibly
   different source or identification color. This makes accidental owner changes
   easy to notice. Save this small scene as your starting copy.
4. Test copies of your production scenes after the small cases. Keep their
   original files. Open Paint/CS Edit scenes using their saved system units;
   unsupported native geometry-binding rescaling is still guarded.

Point placeholders make quick placement tests; use actual models for render
tests. Display limits can show a subset of accepted plants. Keep the preview
limit high enough for visual comparisons, and read accepted and cached-preview
counts separately.

## Phase 1 — 0.81.8: clear state, ownership and feedback

**What changed:** Statistics identifies the selected layer and separates accepted
placements from cached preview data. Status distinguishes a new/uncomputed
layer, pending Manual edits, a completed empty result and a failed successor
retaining an earlier result. Generated callback/binding guards were corrected.

- [ ] Rename A and B, switch between them, and open Statistics & diagnostics.
  **Expected:** the selected layer name and statistics follow the selected owner.
- [ ] In Manual, change A's Count from about 2,000 to 3,000. Browse panels and
  select B and A without pressing Update. **Expected:** A's existing plants stay
  in place and the UI indicates pending work. Press Update to consume the edit.
- [ ] Switch between Point Cloud, proxy and Mesh representations. Try a low
  preview limit. **Expected:** displayed/cached preview counts are not presented
  as the complete accepted population; display changes do not alter planting.
- [ ] Add a new uncalculated layer, then calculate a deliberately empty result,
  such as a black texture mask in Phase 4. **Expected:** new/pending and completed
  zero-result states are understandable and distinct.
- [ ] Move through panels and select unrelated scene objects repeatedly.
  **Expected:** static placements stay stable and interaction remains usable.
  Record visible stutters; visual inspection alone cannot prove cache counters.

## Phase 2 — 0.81.9: named settings and curve presets

**What changed:** a local preset browser saves Population, Transforms, Spacing
and supported curve settings. Apply targets a captured owner, supports one Undo
and follows Manual/Live. These are setting categories; complete multi-layer
recipes and asset substitution are planned for Phase 10.

- [ ] In **Amount → Presets...**, save A's Count/seed as `My population test`.
  Change the Count/seed, then Apply the preset. **Expected:** the saved settings
  return; A's receivers, models and layout assignments remain intact. Manual
  placements wait for Update.
- [ ] Repeat from **Transforms → Presets...** with a recognizable scale/rotation
  range. Repeat a Spacing preset for the currently chosen **Within this layer**
  or **Between layers** scope. **Expected:** only the named category/scope changes.
  A spacing preset stores the rule, not peer identities or Relax/cleanup.
- [ ] Open the browser for A, select B while leaving the browser open, inspect
  its target caption, and Apply. **Expected:** it still targets A. Reopen it to
  target B. B must not change accidentally.
- [ ] Save a supported density/scale curve with a recognizable bend. Change it,
  apply its curve preset, then Undo/Redo. **Expected:** the curve shape returns;
  its enable state, fade width and surrounding settings remain separate. If the
  graph reports an external change after Undo, close and reopen it before editing.
- [ ] Browse and rename a test preset without Apply. Delete only a disposable
  preset using the confirmation. **Expected:** library operations do not change
  plants; the test preset persists when the browser is reopened.
- [ ] Test Apply once in Live. **Expected:** the completed settings update the
  planting normally. One Undo restores the preceding authored settings.

## Phase 3 — 0.82.0: slope and altitude eligibility

**What changed:** independent per-layer slope and altitude filters decide where
plants can grow, with soft transitions inside their allowed ranges. Normal
alignment continues to control orientation separately.

- [ ] Use flat, approximately 30° and approximately 60° upward-facing surfaces.
  In **Include / exclude areas → Surface eligibility**, enable **Filter slope**,
  set 0–35° and zero fades. **Expected:** the flat/gentle surfaces remain eligible;
  the steep surface is excluded. With the filter off, ordinary eligibility returns.
- [ ] On terrain with varying slope, set **Upper fade** to 10°. **Expected:**
  density is full through 25° and thins toward zero at 35°. Use Candidate budget
  so Accepted target refill does not conceal the thinning.
- [ ] Disable slope temporarily and use a sloping receiver with a useful height
  range. Enable altitude from 10–30 m, with a 5 m lower fade and a 5 m upper fade.
  **Expected:** no ordinary plants outside the range; thinning from 10–15 m and
  25–30 m, with full eligibility between those bands, before other restrictions.
- [ ] Move the receiver vertically. **Expected:** altitude follows **world Z**,
  not distance above that receiver. Source pivot/lift offsets do not redefine the
  receiver height used by the filter.
- [ ] Test a filter edit in Manual and in Live. Try a crossed Min/Max or an
  overlapping fade range. **Expected:** Manual waits for Update; Live follows
  relevant changes. Invalid updates report an error and retain the earlier result.
- [ ] Keep B visible while changing A. Later combine A's filters with Paint or
  a texture. **Expected:** restrictions combine; B's unrelated settings stay
  intact. Explicitly moved/cloned CS Edit plants are protected and bypass these
  filters, so they are not suitable ordinary-candidate test samples.

## Phase 4 — 0.82.1: density UV channel and resolution

**What changed:** Texture Density can select UV channels 1–99 and sampled map
resolutions 64, 128, 256 or 512. The defaults remain channel 1 and 128. Unchanged
map samples are cached; invalid UV inputs retain the last complete result.

- [ ] In **Amount → Advanced → Texture Density**, assign a black/white mask.
  Test white, black and a gray value. **Expected:** white permits, black excludes,
  and gray thins ordinary candidates. Invert reverses permission.
- [ ] Prepare distinct receiver mapping in channels 1 and 2—for example, rotate
  the second mapping by 90° for a striped image. Change **UV channel** and Update.
  **Expected:** the distribution follows the selected mapping.
- [ ] Use a mask with narrow lines or small islands. Compare resolutions 64,
  128, 256 and 512. **Expected:** finer sampling can capture more detail, at a
  greater preparation/memory cost. Different resolutions need not give identical
  coverage. 512 has sixteen times as many samples as 128.
- [ ] Select an absent channel, such as 99 on a receiver that only has channel 1,
  then Update. **Expected:** an error identifies the receiver/channel and keeps
  the preceding planting. Restore the valid channel to recover.
- [ ] Move/rotate the receiver, edit the map and browse unrelated panels.
  **Expected:** relevant updates behave normally; passive browsing does not
  change the planting. Compare first and repeated updates for noticeable stalls.
- [ ] Test one map edit in Manual and Live. **Expected:** Manual retains old
  plants until Update; Live responds to relevant changes. UVs outside 0–1 clamp
  to the sampled edge; this workflow does not provide repeating/UDIM addressing.

## Phase 5 — 0.82.2: Paint and spline snapshots

**What changed:** Export spline makes editable contours and holes from a Paint
Area. Pick spline imports closed contours with Replace/Add and a world-unit
tolerance. The area retains its identity, density and fades. Detached source
edits/deletion no longer force ordinary layers to rebuild.

- [ ] Enable **Use Paint Areas**, add/select an area on the test plane, and Paint
  an outer region. Erase a hole and optionally paint an island inside it. **Stop
  the brush**, then click **Export spline**. **Expected:** one selected Editable
  Spline contains the closed borders/holes; the Paint Area remains intact.
- [ ] Edit the exported shape with Max's spline tools, reselect the Scatter and
  the original area, choose **Replace**, and click **Pick spline...** to select
  the shape in the viewport. **Expected:** coverage follows the edited border
  after Update in Manual. The source spline is preserved.
- [ ] Import a second closed shape using **Add**. **Expected:** coverage expands
  by union; existing paint is not erased. Density/fades and B's settings stay
  intact. Try a nested closed-loop shape to check holes and islands; winding/order
  do not determine the result because the import uses even-odd fill.
- [ ] Pick again and press Escape. Try an open spline. **Expected:** cancellation
  changes nothing; an invalid import explains the repair and preserves old paint.
- [ ] Use Undo/Redo after import and export. **Expected:** one command is one
  Undo; export Undo removes its snapshot, while import Undo restores coverage.
  Use Update to inspect pending Manual coverage changes where needed.
- [ ] After a successful import, edit or delete the source spline without
  importing again. **Expected:** Paint stays unchanged. It is a snapshot workflow,
  so another import is required to apply later source edits.
- [ ] Compare a curved spline at two sensible **Curve tolerance** values.
  **Expected:** a smaller world-unit tolerance produces a closer approximation
  and can require more vertices. Inputs are bounded to 8,192 knots and samples;
  excessive geometry/tiny tolerance reports an error and retains old paint.
- [ ] Repeat on a rotated/scaled receiver prepared before painting, then on
  single-valued terrain. **Expected:** contours use receiver-local XY. Terrain
  export is a planar guide at local Z=0, not a draped terrain outline; import
  projects along local Z. Closed/folded/stacked receivers remain unsupported for
  vector Paint even though ordinary scatter can use curved surfaces.

## Final combined checks and feedback

- [ ] Combine a preset, slope/altitude limits, a texture and imported Paint on A.
  Keep B as a comparison. Test Manual → Update → Live, Undo/Redo and layer copy.
  **Expected:** each control retains its owner and the restrictions combine.
- [ ] Save a test copy, close/reopen with its saved system units, and compare the
  result and authored settings. Test a renderer with actual model sources if that
  is part of your normal workflow; renderer/material/proxy coverage is separate
  from the numeric and UI tests already run.
- [ ] On a production-scene copy, check navigation, panel switching, mode changes
  and sustained editing. Report freezes, unexplained movement, blank/incorrect
  statuses, lost Undo or growing memory along with the triggering action.

For each problem send: **phase/control, scene copy or simple reproduction steps,
expected versus actual result, Manual/Live, and whether Undo or Update recovers
it**. A screenshot/video and source/renderer details help for visual problems.
You can simply mark each phase Pass / Issue / Not tested and describe the issue.

The automated evidence covers the recorded fixtures, not every artist asset or
renderer. Phase 6 will remain paused while you perform this acceptance.
