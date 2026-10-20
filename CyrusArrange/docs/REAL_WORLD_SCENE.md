# Use the real model scene

The example contains a coffee table and side table with original full-size
books, a complete potted plant and a vase set. The
[release record](RELEASE_VALIDATION_0.3.1.md) gives the current qualification
status, exact files and test evidence.

## Open and select an arrangement

1. In **3ds Max 2027**, choose **Scripting > Run Script** and run the matching
   **CyrusArrange-0.3.1-Max2027.mzp** from `dist/CyrusArrange-0.3.1`.
2. Restart Max so the matching native classes and UI scripts load together.
3. Open **CyrusArrange-Real-Models.max** from `examples/real-world-0.3.1`.
   Keep its **maps** folder beside the file. The original materials and saved
   renderer require **Corona**; this scene was tested with Corona 15.
4. If Max asks about units, choose **Adopt the file's unit scale**. The saved
   scene uses one millimetre per system unit.
5. Select **REAL_Coffee_Arrange**, the cyan diamond/C icon in front of the coffee
   table. Open **Modify** and select **Cyrus Arrange** in the modifier stack.

The parameters are inside the actual Modify panel. **REAL_Side_Arrange** controls
only the side table. Moving either icon moves the control without moving its
furniture or generated props. The icons are nonrenderable.

## Try a variation

1. The original props are already registered. Leave **Amount** and **Spacing**
   at their saved values for the first test.
2. Click **Generate**. It chooses a fresh seed by default and publishes the
   complete result through one native transaction.
3. Enable **Repeat seed** to reproduce the displayed seed. Disable it to make
   new variations again. Use Undo to restore the previous generation.
4. Select the side-table icon and repeat the same test there.
5. Open **Props...** to inspect the source list, add several selected original
   props or create a copied reusable decor group. **Advanced...** opens the
   detailed controls over the same native arrangement.

The saved coffee composition has three books, one complete plant and one vase
set. The side table has one vase set. Amount is a density target rather than an
exact item count; a new variation may report underfill when finite fit search
or category limits prevent filling it. Props retain their original size.
Changing Amount or Spacing waits for Generate.

If the loaded scene reports changed inputs, its saved output remains visible.
Enable **Repeat seed** before Generate to refresh that saved composition;
leave it off to create a new variation.

Original accessory meshes and the complete plant source group are retained on
**REAL_90_ORIGINAL_PROP_SOURCES**, hidden, frozen and nonrenderable. Keep that
layer for regeneration. Register original sources rather than generated output.

## Inspect size and contact

| Content | Prepared source | Approximate size in mm |
| --- | --- | --- |
| Coffee table | Coffee_Table_04 | 1262 × 1131 × 377 |
| Side table | Side_Table_01 | 500 × 500 × 535 |
| Flat book A | Books_01_Book_002 | 286 × 210 × 17 |
| Flat book B | Books_01_Book_019 | 240 × 210 × 21 |
| Complete potted plant | Decor_Set_01_Complete_Plant | 488 × 500 × 529 |
| Original vase set | Decor_Vases_01 | 281 × 192 × 205 |

The plant keeps all three original Group006 parts together, including the pot,
branches and autumnal foliage. It has 40,953 vertices and 71,637 evaluated
triangles. The saved output uses scale 1 and upright quarter-turn yaw, with
15 mm prop spacing and a 10 mm support-edge margin. Output poses were generated
without manual adjustment or shrinking to force a fit.

Use **REAL_Overview**, **REAL_Coffee_Detail** and **REAL_Side_Detail** for the
inspection cameras. The three example PNGs use those saved cameras. The 131
local maps keep their original bytes; some belong to unused pieces in the
source collections. The studio floor, cameras and lights are authored test
staging, while the model materials remain assigned.

The physical tests cover actual mesh scale, contact, full-footprint support,
clearance, conservative collisions, original geometry/UV/material preservation,
seed repetition and save/reopen. Read [the test design](REAL_MODEL_TESTING.md)
for numeric tolerances and [the Modify guide](MODIFY_PANEL.md) for other scenes.
These checks do not simulate rigid-body physics or establish support for every
third-party modifier, proxy or renderer.
