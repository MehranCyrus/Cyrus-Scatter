# Edit instances in 0.87.6.7

Move, rotate or scale an instance in **Cyrus Scatter Edit > Instances**. It now
keeps its authored placement, rotation, scale and source choice when you change
**Amount > Seed** or the procedural size variation. The other instances follow
the changed settings. Copies are pinned independently; deleted instances stay
deleted. Pins remain part of spacing, Interactions and rendering.

**Reset selected edits** returns selected generated instances to the current
procedural result and removes selected copies. **Reset all edits** clears the
whole modifier. Both support Undo. Use the instance gizmo to change a pinned
item further.

Ordinary Mesh/Proxy instances now follow the gizmo while the mouse is held.
The preview reuses source geometry and patches selected transforms. Unselected
edit markers and selected mesh outlines are suppressed during the gesture;
the complete instance meshes remain visible. Up to 4,096 selected instances use
this transient preview. Larger selections and Point Cloud retain their existing
update path. Existing prepared Interactions continue through their own live path.

Pending Manual settings still wait for **Update scatter**. Moving an item does
not apply a pending Amount or Seed change. A removed source or receiver can
suspend an edit; restoring the same compatible owner restores it. Receiver
geometry and unresolved old histories remain guarded. Separate per-instance
radius overrides keep their existing compatibility rules.

Open a supported older edited scene with its matching generation first so its
saved deltas can acquire pins. If it was saved after an incompatible Seed change,
restore the prior Seed once; the plugin cannot reconstruct a missing old placement
from an unknown generation. Save an upgraded copy and preserve the original:
0.87.6.7 writes native Edit storage 4, which older plugins reject. Portable Edit
payload 2 preserves pinned placement relative to the destination generation.
Scene schema 65 and recipe envelope 9 remain unchanged.


## Panel and Band display

Checkbox and radio captions repaint after expanding sections or changing panel
columns. Band list badges show the assigned model colour. Multiple models use a
split badge (up to four distinct colours); an unassigned band has none. The
separate authored Band viewport colour remains available.

## Prepare stems, leaves and flower heads

Open **Interactions > Prepare model**. Select complete pieces with Click, Box,
Brush or **Same material**; use **Isolate** and **Frame** to inspect them.

- Choose **Profile > Stem** for a bending stem.
- Choose **Profile > Leaf** for an independent leaf guide, including broad leaves
  the automatic detector leaves rigid. It starts as an independent root; use
  **Edit guide > Pick parent stem** to attach it when needed.
- Choose **Profile > Flower head** to keep petals/head pieces rigid and follow
  the nearest stem. Pick a parent explicitly if the automatic choice is wrong.
- After preparation is ready, choose **Guide points > 3, 5, 9 or 16** for the
  selected bending pieces. These correspond to 2, 4, 8 or 15 guide segments.
  More points follow curves more closely and cost more to prepare and bend.

Other pieces keep their automatic guide shapes and attachment owners. Existing
authored guide edits are resampled when detail changes. Use Undo/Redo while
editing, inspect roots and attachments, then click **Use preparation**. An invalid
successor cannot be accepted; Undo or repair it to return to a complete draft.
Manual pending scatter settings still wait for **Update scatter**.

These controls create deformation guides inside the existing mesh. They do not
add missing visible petiole geometry or subdivide the source mesh. Profiles are
artist choices, not automatic botanical classification. Default preparation
quality stays unchanged. New profile/detail data requires 0.87.6.7 or later;
save upgraded scenes as copies if you need to keep using older plugin versions.

## Library recovery

Scene-load staging is now marked before copying. Library recovery can remove an
abandoned owned copy after its process exits while retaining active and unverified
folders. Previously leaked unmarked folders remain untouched. New Scene presets
record the actual loaded Gallery version, and licensing captions no longer show
the obsolete 0.80.0 label.

Run the [Max 2027 MZP](../../../dist/CyrusScatter-0.87.6.7-20261029/CyrusScatter-0.87.6.7-Max2027.mzp)
through **Scripting > Run Script**, then restart Max. The installer was not run in
the artist profile. This delivery is Max 2027 only; older-host packages retain
separate historical qualification.
