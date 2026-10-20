# Cyrus Arrange geometry workflow — 0.3.2 development

This describes the developing interface, not an installer to use with 0.3.1.
Current acceptance and remaining work are in
[the implementation ledger](GEOMETRY_WORKFLOW_0.3.2.md).

## Arrange props on geometry

1. Select a table, shelf assembly or other receiving geometry and run **Create
   Cyrus Arrange**. Its selectable icon opens **Modify → Cyrus Arrange**. You can
   instead add the Cyrus Arrange modifier to receiving geometry and choose
   **Use this geometry**.
2. Open **Props → Pick props**, choose the original models or groups you want to
   repeat, then right-click to finish. The native library preserves their geometry
   and materials. **Add selected props** also accepts a bulk selection while the
   modifier stack is pinned.
3. Set **Copies**, then **Generate**. Generate applies the visible drafts and
   chooses a new seed. **Repeat seed** keeps a saved variation reproducible.

For grouped furniture, select the complete group and run **Create Cyrus Arrange**.
Select the new arrangement icon to edit **Modify → Cyrus Arrange**, then add
props and Generate. The group stays the receiving reference; you do not need to
edit its group head's modifier stack.

There is no furniture-type choice and no separate Apply button. A book, plant,
device or other chosen source is eligible wherever the geometry checks accept
it. Bounds alone do not prove support: final placement still checks support,
clearance and collision. Unfilled copies are reported rather than overlapping
objects being forced into the result.

Collision refinement is automatic. Closed props can use compound geometry checks
when their complete boxes overlap empty space, for example beneath an arch.
Actual occupied parts still block collisions. Open or unproved geometry retains
conservative full bounds. There is no new collider-setting window or extra knob.

Automatic source capture now separates the base from upper overhang. A pot can
use a narrower shelf while foliage extends past its edge, provided the base is
supported and the complete plant clears all obstructions. This checks geometry;
it does not simulate gravity, balance or flexible leaves. Authored support patches
stay authoritative. This extension is undergoing the acceptance listed in
[the source-base contract](BASE_SUPPORT_0.3.2.md).

Receiving analysis also recognizes consistently closed surfaces authored with
inward-facing triangles, such as the supplied glass table. It prepares a private
calculation copy automatically; the original model and materials stay unchanged.
Open, inconsistent or potentially nested/intersecting shells keep their authored
facing. This does not repair arbitrary modeling defects or simulate physical forces.

**Fill available space** provides a density target instead of an exact quantity.
The gap is separation between generated copies. Surface sampling is calculated from the
receivers, source sizes and bounded analysis budget; there is no everyday sample
grid setting to tune.

## Optional controls stay in Modify

The main section and Props start open. Scale, Keep clear and Path start
collapsed. No extra Props or Advanced window is required.

Generate applies your visible drafts. Undo restores accepted settings and results
without reviving an older rejected draft's error. Current scene-change/load notices
can still ask for Generate to validate dependencies; the existing result stays
visible. They use the same Generate button, with no extra Apply action.

- **Scale:** enable Random scale for a percentage range, or Shrink to fit to permit
  bounded uniform reductions. With Random scale off, original size is preferred
  before fit reductions. With Random scale on, its chosen size is preferred first.
  The source model stays unchanged; generated copies receive the final scale.
- **Keep clear:** receiver collisions are automatic. Pick obstacles adds other
  scene geometry or complete groups to avoid. They do not become receiving
  surfaces. Remove obstacle removes only that reference, including a missing one;
  it leaves the scene model unchanged. In the same section, pin the stack, select
  generated copies and Protect selected to preserve their placement.
- **Edge gap (mm):** optional distance between the prop's base and the receiving
  edge, in Keep clear. New arrangements start at zero to use available support;
  saved arrangements retain their existing gap. The draft applies with Generate.
- **Clear approach:** an optional extra horizontal access check in Keep clear.
  Enable it only when objects also need an unobstructed approach from the support
  region's front direction. Collisions are always checked. The checkbox applies
  with Generate, together with the other drafts.
- **Reusable props:** Pick components as a decor group to create one copied source
  that can be repeated together. The original components stay unchanged.
- **Min copies:** select a prop in the Props list and optionally set its minimum.
  Zero lets the solver choose. Positive values reserve part of total Copies for
  that source, including its protected copies. Increase total Copies if the sum
  of minimums exceeds it. An object that cannot fit leaves those copies unfilled.

Changing controls is a draft until Generate. Invalid generation retains the last
accepted settings, seed and output. Source binding and explicit protection/removal
commands and obstacle binding/removal are separate Undoable edits. Undo after Generate restores that complete
generation transaction.

## When copies remain unplaced

Select a prop in the Props list. A single source is selected automatically.
After Generate, its contextual feedback explains the tested support, clearance,
occupied space, gap or lane problem. **Show fit space** highlights the relevant
space/obstruction in orange and a physically checked candidate in green, when one
is available. The same button hides those boxes. It creates no scene objects and
does not change your selection.

When a smaller checked size is available, **Use checked size** enables Shrink to
fit and changes the visible minimum percentage for this arrangement. Press
**Generate** to apply it. Original size is still preferred, proportions and
source models are preserved, and every generated pose must pass the normal
physical checks. A suggested value below the old minimum is shown explicitly.

Feedback describes tested positions; it does not prove an optimal size or that
every possible arrangement was searched. Some spaces may still remain unfilled.
After relevant scene edits, Undo or reopen, Generate again to refresh advice.
Successful placement hides irrelevant feedback controls. Everything stays in
Modify; there is no fit-settings popup.

## Arrange along a spline

Select a spline before Create Cyrus Arrange, or use **Path → Pick spline path**.
Add props and Generate using the same main controls. Their base centers follow
the path; Align and Model front control upright heading. In a path-only setup,
the spline's height is the authored placement height. Binding receiving geometry
adds physical support and clearance checks.

The main amount choice becomes **Quantity / Center spacing**. Path shows center
spacing only in spacing mode. Offset follows the curve's local left/right
direction; Sideways and Along add seeded variation. Keep inside width constrains
the complete footprint, not just its center.

Enable **Two-way placement** to reveal the other side's quantity, offset, width
and direction in the same Path section. For three cars each way, set First copies
and Other copies to 3, choose suitable opposite offsets and lane widths, and
Generate. Widths, end fit and collisions can legitimately reduce the accepted
count. Use surfaces instead clears the path binding and returns the main amount
choice to Quantity / Fill.

Min copies applies across both active lanes: four required copies are valid in
a three-plus-three layout. In spacing mode, the available path slots bound the
minimum. Switching to surfaces carries over the combined Quantity target, or
the visible output count from spacing mode, while retaining other pending edits.

The native path host is tested with primitive cars, transformed Bezier curves and
[complete modeled sedans on a curved two-way road](ROAD_SCENE_0.3.2.md), including
three cars each way, scale, lane containment and unit conversion. An additional
[actual shelf/stair campaign](SHELVES_STAIRS_0.3.2.md) passed with
100 detailed imported books and 48 mixed props, including independent geometry
verification. The broader real-model campaign, viewport picker gestures,
broader support/shape precision, diagnostics, performance and final installer remain
release gates; this guide does not certify them. Surface required/large-first
packing and the optional Min copies field are covered by the
[packing checkpoint](PACKING_PRIORITY_0.3.2.md) and
[path-minimum extension](PATH_MINIMUMS_0.3.2.md). An older saved book-row recipe
switches to ordinary geometry placement when you press Generate. Protected row
members keep their exact placements and relationship; Undo restores the old mode
and result together. Opening the scene alone does not change it. See
[path API and evidence](PATH_API_0.3.2.md).

For **Quantity**, Generate can try alternate layouts when an unlocked placement
leaves too little room for the remaining copies. Protected objects stay fixed.
Your seed, quantity and scale limits keep their meaning; impossible capacity still
shows the actual unfilled count. There is no recovery button or additional window.
The [recovery validation](PACKING_RECOVERY_0.3.2.md) covers complete appliance
meshes, protection, obstacles, random scale, Undo and reopen. This remains a
development workflow while final release work is open. The complete
[device/imported-table campaign](RECEIVING_PREPARATION_0.3.2.md) now passes with
two original-size devices on the unmodified supplied glass table, plus cabinet
fit, occupied space, Undo and save/reopen checks.
