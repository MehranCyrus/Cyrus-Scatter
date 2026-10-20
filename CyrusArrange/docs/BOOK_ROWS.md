# Book rows — 0.1.3 artist guide

Use **Cyrus Arrange 0.1.3 for Max 2027** with the matching modules/UI identified by
the [release report](RELEASE_VALIDATION_0.1.3.md). That report records exact
functional, example and installation evidence. Book rows were introduced in
0.1.2; the preserved 0.1.1 installer does not include them. Saved scenes and the
scoped balance comparison are described in the [current book-row examples](BOOK_ROW_EXAMPLES_0.1.3.md). The [0.1.2 examples](BOOK_ROW_EXAMPLES.md) retain their historical native28 evidence.

## Prepare the books

1. Choose a **TV console** or **Open shelf** setup. Book rows support these two
   furniture categories.
2. In **Asset Library**, select one upright book or its assembly, press **Use
   selected model / group**, choose **Book**, then **Register new asset**.
   Register different designs separately. A source containing three books is
   still one asset, rather than three independently generated row members.
3. Keep **Min scale** and **Max scale** at **1** for real physical sizes. The
   original book fixtures provide heights 100/200/300 mm, thicknesses 20/30/40 mm
   and depth 120 mm. Different authored heights supply genuine height variety.
4. Select the entry and open **Upright book row profile...**. Check **This asset
   is an individual upright book**, choose **Spine side in the captured asset
   frame**, then **Apply profile**. A Book category or book-like shape alone
   does not enable rows.

Choose the physical outside spine face: **-X, +X, -Y or +Y**. Registration
captures the evaluated source in its current world orientation, then moves its
base centre to the asset origin. Its captured axes follow the scene's world
axes at capture; they are not the source's pivot axes or the camera axes. Keep
the book upright along captured +Z.

The unrotated original fixtures have their spines toward **-Y**. With a -Y
surface front, allowed yaw **0** faces those spines correctly. Other fronts
need a compatible allowed yaw; quarter turns cover cardinal fronts. Review
fronts in **Surface rules...**. A profile does not add allowed rotations or
force scale 1; those existing asset controls still apply.

Use Manual mode while revising a source or its profile. After rotating,
replacing or editing a source, refresh its geometry and recheck
the physical spine side before generating. For example, rotating an original
-Y spine by +90 degrees about world Z makes it face +X in the new capture.
Refresh, Generate and rebind keep the saved profile tag; they do not recognize
the new spine or reinterpret its side automatically. Apply a corrected profile
and allowed yaws when needed.

## Generate and preview

Open **Book rows / height balance...**. Enable **Generate rows of individual
upright books**, set **Minimum books** and **Maximum books** between **2 and 6**,
choose **Gap within a row (mm)**, and **Apply composition settings**.

The row gap affects members of the same row. For example, a 3 mm row gap can
coexist with ordinary 20 mm prop spacing. Separate rows and other props retain
ordinary spacing; zero gap still forbids overlap.

Each member consumes one population slot and one Book category count. Density,
category limits, surface rules, space and compatible yaw angles may prevent a
complete row. Valid individual books can still appear as ordinary props.
Selection weights apply to eligible individual assets, rather than reserving
an equal share for each category. See the [asset guide](ASSET_LIBRARY.md) when
tuning the mix of books and other accessories.

Use **Preview bounds**, then **Commit preview**, or **Generate** directly.
Every member must fit before its complete row is accepted. Manual mode waits
for these commands; armed Live can respond to applied changes. Preview retains
current outputs and pauses Live until Commit or Generate.

## Optional row height balance

**Row height balance** defaults to zero. Increasing it allows newly generated,
unlocked rows to translate within their current surface to improve its
left/right height profile. It tests up to eight alternative positions per row
and keeps the original when no better valid choice is found.

Sizes, orientations and internal gaps stay fixed. Other props, stacks, locked
rows and unselected surfaces stay in place. This measures object heights
relative to the surface's front; it does not invent different heights, evaluate
physical stability or judge a camera render. It works within one horizontal
support region, with ordinary fit and work limits still active. A low value
penalizes movement more strongly; even at 1, a better legal location may not be
among the eight alternatives. **Balanced** style does not enable this control.

## Select, lock and revise

After generation, **Refresh saved settings** refreshes the book-row list and
statistics. Select a row, then **Select all members of this row**.

**Lock selected outputs** locks the entire row when any member is selected;
**Unlock selected outputs** unlocks it together. To reposition manually,
translate all members together before locking. Moving one independently breaks
the relationship: unlock and regenerate, or Undo. If one was deleted, select a
remaining member to unlock the row before Generate.

Protected rows retain their saved gap when the new-row gap changes. Disabling
row generation preserves valid protected rows. Incompatible profile, front or
geometry edits must be resolved before regeneration; failure retains the prior
output. Use **Region IDs** for selective surface regeneration.

A lock preserves the row's placement IDs and valid poses. A successful Generate
can replace the actual Max nodes, including locked members. Refresh the output
or row list before selecting again; do not attach permanent rigs, animation or
external references to generated nodes. Manual mesh/material edits to them are
not saved asset overrides.

Removing an in-use asset requires the Asset Library's output-removal option.
It removes complete affected rows and supported stack children, including row
members using other assets. Those other library entries remain registered.

## Save and reuse

Save the `.max` scene to retain settings, profiles, membership and locks.
Undo/Redo covers authored settings and published rows. Preview is temporary;
after reopening, Live needs an explicit successful Generate to resume.

**Save asset library...** stores explicit profiles with geometry and placement
metadata. Older libraries load without row eligibility; mark intended books
explicitly. Portable libraries still omit materials, textures, UV channels and
modifier stacks. Keep the source `.max` library for appearance.

Rows remain upright and use conservative collision bounds, so tight fits can
be rejected. Leaning books, automatic bookends and arbitrary decorative
relationships are outside this release. See the
[arrangement quick start](ARRANGE_QUICKSTART.md) for the wider workflow.
