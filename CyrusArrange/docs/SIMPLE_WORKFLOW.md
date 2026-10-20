# Arrange furniture with Cyrus Arrange 0.3.1

For the 0.3.2 development interface, use the [geometry workflow](GEOMETRY_USER_WORKFLOW_0.3.2.md). The instructions below retain the qualified 0.3.1 window-based workflow.

The main window now follows **choose furniture → add props → Generate**.
Use the matching 0.3.1 installer identified by the
[validation report](RELEASE_VALIDATION_0.3.1.md), then restart Max
2027 before opening a new icon scene. The actual installer and automatic
installed startup passed their private-host qualification.
The [current contract](REAL_WORLD_0.3.1.md) records the scope; a label alone does
not establish a tested native/script pair.

## Open the tool

Select an arrangement's cyan viewport icon and open **Modify → Cyrus Arrange**.
Its compact controls use the same arrangement as the main window. You can also
add **Cyrus Arrange** from the Modifier List to furniture and choose **Use this
furniture**. Opening its panel does not generate props. See [Modify panel](MODIFY_PANEL.md).
For a complete furniture group or several parts, use the main window's
**Use selected furniture** action. Moving the arrangement icon changes its
selection location without moving the furniture or placements.

Your existing Cyrus Arrange toolbar button opens the new main window after
installing and restarting. To open without a toolbar, press **F11** and run:

```maxscript
macros.run "Cyrus" "CyrusArrangeStyling"
```

To assign a toolbar button, use **Customize → Customize User Interface →
Toolbars**, choose the **Cyrus** category, and drag **Cyrus Arrange** onto a toolbar.
Cyrus is the action category in that dialog.

## Try the existing TV and shelf examples

1. Open a working copy of the [ready TV and shelf scene](../examples/simple-0.2.0/CyrusArrange-Simple-Workflow.max).
   Its [guide](../examples/simple-0.2.0/README.md) identifies each setup. Existing
   0.1.3 scenes also retain native document format 4 and can be reused.
2. Open **Cyrus Arrange**. Choose the TV or shelf in **Arrangement in
   this scene**, or select its furniture in Max. Its saved setup binds automatically.
3. Click **Generate**. Each successful click normally chooses a new seed.
4. Adjust **Amount (%)** or **Spacing (mm)**, then Generate again.
5. Select generated props and click **Keep selected props** to protect them
   during future Generate commands. **Release selected props** unlocks them.
   Book rows stay together when a member is kept or released.

There is no separate Analyze, Apply or Reroll step in this main workflow.
The saved setup, furniture sources and registered original props must remain
in the scene. Use Save As to preserve the supplied scenes.

The [bulk/group demonstration](../examples/simple-0.3.0/README.md) contains a
shared reusable source group and color-coded numerical TV/shelf fixtures.
Its saved settings enable one known support board per furniture for clear
geometric checks. The detailed 0.2.0 scene above remains useful for ordinary
multi-shelf styling with the new plugin.

## Start with new furniture

1. Select the furniture model, its group head or its geometry parts in Max.
2. Choose its **Furniture type** and click **Use selected furniture**.
   If it already belongs to an arrangement, that arrangement is reused.
3. Click **Props...**. Select the original accessory models or existing groups
   together in Max, choose their **Type**, and click **Add selected props**.
   Each selected model or outer group becomes one entry. Already-added sources
   are skipped without changing their settings.
4. Return to the main window and click **Generate**.

New props retain their physical scale. The quick add allows four upright yaw
angles and does not enable stacking. Use **Library & detailed options...** to author
upright book profiles, stacking support, exact allowed angles or other metadata.
Explicit existing surface/category restrictions still apply to newly added props.
An accessory registered to several arrangements remains a shared source model;
each arrangement keeps its own placement settings and output.

## Make a reusable decor group

Arrange a few pieces together first, such as a stack of books beside a candle.
Select those pieces or existing groups, enter a group name in **Props...**, then
click **Create decor group**. Cyrus copies them into one new source group and
adds one prop entry. It preserves the originals and the pieces' relative positions,
materials and physical size. It does not assemble widely separated props for you.

Select that new source group and add it to another furniture arrangement to reuse
it. Keep it in the scene; saving the Max scene preserves the group and its bindings.
Generated placements contain the whole decor group as one mesh. Each placement
passes the same support and collision checks as an individual prop. A large group
can fit fewer times or fail to fit; Cyrus does not silently shrink it.

Use complete Max groups for assemblies; ordinary parent/child hierarchies must
be grouped first. Bulk Add and Create decor group each have one Undo step. Invalid selections leave
the previous catalog and placements intact. Furniture, obstacles and generated
outputs cannot be quick props. Use **Library & detailed options...** for individual
metadata, removal and portable geometry libraries. Portable libraries contain
geometry and metadata; keep or rebind scene sources for their materials.

## Repeat a result

Enable **Repeat seed** to show the seed and regenerate using it. Copy or enter a
seed to revisit a variation. The number used by a successful Generate is saved
with the scene. Repeat seed is a view preference and starts off when the main
window reopens or a Modify view opens; changing views does not change the saved seed.
An unchanged seed reproduces output when the other inputs/settings are unchanged.
Locks, source edits and changed rules can change a result even with the same seed.
An unsuccessful Generate retains the previously published seed/settings/output.
Normal Undo restores a successful seed and its placements together.

## Advanced controls

**Advanced...** opens detailed controls for the same arrangement: edge gaps,
style, scale, allowed categories, selected shelves, collision scope, book rows,
Preview/Commit and Live updates. **Regenerate same seed** there repeats its seed;
**New variation** uses the detailed view's next seed.

The main window reads current native settings at Generate. An untouched main
field does not overwrite a setting you applied in Advanced. A main field you
edited explicitly takes precedence for that command. Closing Advanced refreshes saved values while preserving explicit ungenerated
main drafts. Opening either window does not arrange anything.

Selection and window opening only discover existing ownership. They do not
analyze geometry or generate. Where shared furniture or mixed selections match
several arrangements, choose one in the list; the tool does not guess an owner.
The amount is a density target, not an exact item count. Support, collision,
spacing and category rules can leave fewer props placed than requested.
