# Cyrus Arrange — quick start

For the 0.3.2 development interface, use the [geometry quick start](GEOMETRY_USER_WORKFLOW_0.3.2.md). The instructions below retain the qualified 0.3.1 workflow.

For **Cyrus Arrange 0.3.1 / Max 2027**, start with the [simple workflow](SIMPLE_WORKFLOW.md)
or the [native Modify controls](MODIFY_PANEL.md). Use the qualified matching
installer identified by the
[current validation report](RELEASE_VALIDATION_0.3.1.md).
The preserved [0.3.0 report](RELEASE_VALIDATION_0.3.0.md) records that earlier
qualified pair and the bulk/group workflow retained here.

1. Select a new arrangement's cyan icon and open **Modify → Cyrus Arrange**,
   or open **Cyrus Arrange** from your toolbar. You can also press **F11** and run
   `macros.run "Cyrus" "CyrusArrangeStyling"`. Cyrus is the action category in
   **Customize → Customize User Interface**, where you can assign the toolbar button.
2. For an existing scene, select its furniture in Max or choose an arrangement
   from the list. It loads automatically. For new furniture, choose its type and
   click **Use selected furniture**.
3. Click **Props...** to review the saved library or add selected original
   models/groups together with a shared type. Create a named decor group from
   pieces you have already arranged together to reuse it as one prop.
4. Set **Amount (%)** and **Spacing (mm)**, then click **Generate**.
5. Click Generate again for a new variation. Turn on **Repeat seed** when you want
   to repeat the displayed seed. Select output and **Keep selected props** to
   retain it during later variations.

The main flow does not need a separate Apply, Analyze or Reroll command.
Modify and the main window use the same saved arrangement. Moving its icon
does not move the furniture or generated props; opening its controls does not
calculate a new layout.
**Advanced...** retains detailed rules, Preview/Commit and Live for the same
native arrangement. Its **Regenerate same seed** action explicitly repeats the
seed; **New variation** advances it.

## Detailed controls and boundaries

The following reference describes the detailed controls now reached through
**Advanced...**. Its baseline examples and recorded 0.1.3 qualification remain
historical; new native/UI qualification is recorded separately for the current delivery.



1. Open **Advanced...** from **Cyrus Arrange** from the Cyrus category after installing the matching
   package and restarting Max. In a development environment, load the matched
   native modules and scripts, then call `caShowAdvancedArrangeUI()`.
2. For an existing arrangement, select its setup helper and use **Use selected setup** in Advanced. For new furniture, select a TV console, shelf, table or kitchen counter. Select its group head
   or all its geometry parts, choose the furniture category, and press
   **Create from selected furniture**. Keep unrelated room geometry outside
   this selection. A small setup helper owns the arrangement.
3. Open **Asset Library**. Select a prepared accessory model or group, use
   **Use selected model / group**, choose its category and allowed furniture,
   then **Register new asset**. Repeat for the accessories you want.
   Keep minimum and maximum scale at **1** for real physical sizes. Prepare
   upright and flat books as separate sources with their intended base down.
4. Open **Surface rules…**, press **Analyze furniture**, and review the detected
   surfaces. Label important shelves, exclude unwanted ledges and choose which
   accessory categories each surface may receive. Press **Apply surface rules**
   for each edited surface before selecting another. Analysis itself preserves
   existing generated objects. An already armed Live setup may update afterward;
   use Manual mode to review rules before generating.
5. Open **Collision scope…** and explicitly add a TV, existing decor or other
   geometry that should block placement. For an area that must remain empty,
   add a simple blocker volume rising above its surface. These objects never
   become supports.
   Use the horizontal approach requirement for shelves where the objects must
   fit through the front opening. After changing that checkbox, press **Apply
   approach setting**. Ordinary collision checks stay active when that
   requirement is off.
6. Choose a seed, style, density, spacing and edge gap. Press **Preview bounds**
   to inspect the proposed arrangement, then **Commit preview**. **Regenerate same seed**
   publishes directly. Both actions validate support, obstacles and clearance
   before replacing the previous result.

Surface exclusions and category rules control where an accessory's **anchor**
may land. They do not clip its footprint to that region: it may extend onto a
touching, coplanar excluded surface while remaining supported. Actual gaps and
holes still reject unsupported contact. Use the obstacle volume in step 5 for a
physical keep-clear area; an excluded label or flat outline alone is not one.

Distances in the interface are millimetres regardless of Max display units.
The plugin evaluates the selected geometry and modifiers; names and category
tags describe your intent. It does not infer what a model means from an image.
**Suggest furniture category** can read useful names and the explicit
`CyrusArrangeFurnitureCategory` tag, but ambiguous names require a selection.

## Refine the result

- **New variation** changes the seed and generates another arrangement.
  Reusing the same seed and unchanged setup reproduces its placement records.
- Move or rotate a generated object, then **Lock selected outputs** to capture
  its pose. Keep it upright with uniform positive scale. Locks retain complete
  connected stacks so that their children do not lose support. For a generated
  book row, selecting one member locks or unlocks the entire row; translate its
  members together when repositioning it.
- Use **Surface rules… → Use ID for selective Generate**, then click
  **Regenerate same seed** in Advanced to regenerate one surface. Clear the
  Region IDs field to regenerate all unlocked surfaces.
- **Allowed-category rules** controls each category's relative frequency,
  maximum per support region and stacking permission. Set its maximum to zero
  to disable it, then press **Apply category rules** to save the changes.
  The category weight multiplies each eligible asset's own
  weight; accepted category percentages also depend on the library and fit.
  Asset eligibility and surface rules must also permit it.
- **Book rows / height balance...** attempts rows from
  separately registered upright Book assets on TV consoles and open shelves.
  Mark each book's spine side explicitly first. Follow the
  [book-row guide](BOOK_ROWS.md) for this optional step. When a row cannot fit,
  a valid result may contain ordinary props without a row.
- Density and empty space control the target amount of decoration. Spacing and
  edge gap constrain fit. An underfilled result can be correct when furniture,
  source sizes and the requested spacing leave too few valid locations.
- **Grouping** biases new positions toward accepted props and can favor
  permitted stacks. It does not enable book rows. **Scale variation** changes
  uniform scale only within each asset's Min/Max scale limits; fixed-size
  assets stay unchanged.

Advanced-panel edits in Manual mode are drafts until **Apply settings**, **Preview
bounds** or **Regenerate same seed**. The surface, category and approach editors have their
own Apply buttons; Advanced-panel Preview/Regenerate same seed does not save their unsent fields.
**Refresh setup view** and **Refresh library list** read saved data.
**Refresh source assets** instead recaptures bound accessory geometry; recheck
its dimensions and authored support/profile before generating after a source edit.

A rule change that conflicts with a locked object rejects the next generation
and keeps the previous complete output. Unlock the conflicting objects or
adjust the rule. If you remove or reshape a shelf, analyze it again and choose
a current surface ID; retired IDs are never silently attached to another shelf.

The surface list shows sampled bounds and furniture-only overhead clearance.
Full-footprint containment and conservative collision checks validate actual
candidates. A label such as “Left bay” is authored metadata; the plugin does not
claim automatic semantic recognition of cupboards or compartments.

## Keep and reuse your work

Save the `.max` scene to retain the setup, source references, accessory metadata,
rules and generated objects. After reopening, select the furniture so the Main
window finds its arrangement, or choose it from the arrangement list. In Advanced,
select the setup and use **Use selected setup**. A successful Main **Generate**,
Advanced **Regenerate same seed** or **Commit preview** re-arms enabled Live updates. The native plugin must be available to edit its procedural data.

Keep source accessory models in an organized, hidden scene layer if desired.
Registration and generation preserve those sources. If a required source is
deleted, the library marks it missing and generation retains the old output.
Rebind the entry to another model, restore the deleted source with Undo, or
explicitly choose **Use stored geometry**.

**Save asset library** creates a reusable `.cyalib` containing geometry and
placement metadata. Loading it appends assets with new IDs. This portable format
does not include materials, texture files, UV channels or modifier stacks.
Preserve your source `.max` library for visual fidelity. Bound scene sources
supply evaluated material/map data to generated objects; imported geometry-only
entries are marked separately.

Manual mode waits for an explicit Regenerate same seed. **Live after first Generate**
responds to relevant furniture, accessory and obstacle changes. Unrelated
objects and opening panels do not rebuild the arrangement. Preview temporarily
disarms Live so that the current published objects stay in place. Commit or
Regenerate same seed re-arms it; clearing a preview alone does not.

Ordinary Undo/Redo covers authored settings and published scene changes. A
preview is transient and disappears on scene save, load or Undo/Redo. Successful
regeneration may replace Max node handles while preserving placement record IDs;
do not use the generated nodes as permanent rig or animation dependencies.
Manual material/mesh changes to generated nodes are not asset overrides.

## Practical boundaries

The current placement engine uses upright assets, authored contact footprints
and conservative oriented bounds. It can reject a tight fit that exact accessory
triangles would allow. It does not simulate gravity or physical stability,
open doors or create dining place-setting relationships automatically. The
row height balance moves rows using a limited height-profile score;
it does not judge the finished interior. Relational dining place settings and
broader visual-hierarchy optimization are deferred recipe extensions, not
implemented features. Small support features still depend
on the analysis sampling grid. Scene proxies are
limited to the geometry they expose through Max's evaluated triangle interface.

Zero-offset setup/system cloning has explicit qualification. For translated
copies, unlock copied placements and Regenerate same seed against the copied furniture;
automatic frame reconciliation for offset/rotated/scaled clones is not promised.
See the native lifecycle documentation for the precise scope of tested behavior.

If an input exceeds native work or geometry limits, reduce the source complexity,
increase the sampling spacing or split the furniture into separate setups.
Failure preserves the last complete result and reports its cause. Processing is
synchronous on Max's main thread; large admitted models can still take time.

## Examples and further detail

The supplied gallery covers TV consoles, open shelves, a curved coffee table, a round dining table and an L-shaped counter with a real sink opening. Extract the matching Source-and-Examples ZIP, open a working copy of the `.max` scene with the matched package, use the main window's arrangement list or select its bound furniture. The detailed **Use selected setup** command is available inside Advanced. Use Save As to preserve older originals when editing. [EXAMPLES.md](EXAMPLES.md) explains the versioned gallery, hidden source library, portable library and scoped render/timing evidence. Its isolated generation scripts reset disposable scenes and should not be run in an artist scene.

The [0.1.3 imported examples](IMPORTED_EXAMPLES.md) contain saved cabinet/shelf
setups, three full-size accessories, supplied textures and actual Scanline views.
That guide explains the matching-package requirement and the explicit texture
relocation step after moving the whole example folder. It records the exact
import, artist-workflow and render scope separately from package installation.
The cabinet binds only its three
triangle-surface parts; the two original vertex-only paths stay present and
unbound. Do not run the scene-resetting QA scripts in an artist scene.

For detailed controls, see [ASSET_LIBRARY.md](ASSET_LIBRARY.md). For native
records and script commands, see [ARRANGEMENT_API.md](ARRANGEMENT_API.md).
