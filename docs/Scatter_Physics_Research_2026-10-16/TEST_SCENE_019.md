# Physics Lab 0.1.9 — installation and test scenes

Use **Max 2027**. This is the standalone **Cyrus Physics Lab**, independently
versioned from CyrusScatter. The installer and scenes are local testing artifacts.
Nothing was installed in the artist profile or integrated into Scatter.

## Install

1. Save your scene. Finish/Freeze or cancel an old pending session before upgrading.
2. In **Scripting > Run Script**, run the supplied
   **CyrusPhysicsLab-0.1.9-Max2027.mzp**.
3. Restart **Max 2027** to load the matching script/native pair. Loading only the
   loose `.ms` file does not update the native module.
4. Open **PhysicsLab-0.1.9-Mountain-Test.max**. For the regression scenes with
   saved output, adopt the file's system units when Max asks about units.

An old completed result retains its saved poses. An older pending session can
Freeze its saved preview; Resume requires its original exact solver fingerprint.

## Ready mountain scene

The selected **PhysicsLab_Brush_Ready_019** is empty and ready to brush. It uses
the supplied mountain, original pyramid, Sphere32 and Teapot. All three models
are enabled in Detailed mode. Source meshes and other comparison Labs are hidden.
The receiving mountain is visible, and the selected Lab has a 2 m icon above it.
This saved demonstration radius is separate from the corrected creation default.

The toolbar below Models has **+**, **x**, and **Replace...**. Tick the models you
want to spray, and highlight a row for its collision settings. Remove unlinks the
highlighted model from future strokes; it keeps the scene model and saved bodies.
Finish, Freeze or cancel before editing pending-session bindings.

Suggested artist checks:

1. Open Collision quality at narrow and wide panel widths; confirm all three
   choices are visible.
2. Brush a stroke, then another while the first objects still move.
3. Leave the receiver and re-enter. No bodies should be emitted on a miss or
   connected across that gap.
4. Pause, Undo stroke and Redo stroke. Freeze, then test ordinary Max Undo/Redo.
5. Remove a model, add another and check its name, enabled state, quality and
   material. Undo/Redo the binding changes. Existing scattered bodies stay intact.
6. Create a fresh Lab in **Geometry > Cyrus Labs > Cyrus Physics Lab**. Confirm the
   first-click marker is small and dragging sets its size.

**Show collision shapes** draws moving/completed model shapes in cyan and static
collision surfaces in amber. Detailed improves the teapot exterior, but the
known handle opening is still filled at the 16-piece limit. Friction and surface
grip have their preceding meanings; no wall adhesion was added.

## Additional regression scenes

- **PhysicsLab-0.1.9-Palette-Retired-Test.max** preserves completed output whose
  former models have been removed from the palette. The one visible palette model
  uses a later stable physical slot. It tests retention and subsequent brushing.
- **PhysicsLab-0.1.9-Palette-Order-Test.max** has Sphere then Box in the visible
  list, with physical source slots 2 then 1. The hole was reused while another
  model remained. It tests that checks, quality, materials and emission follow the
  intended model after save/reopen.

These are frozen diagnostic examples, including bodies captured while moving.
They are not certified settled arrangements. Freeze can retain temporary overlaps;
Finish can reach its finite settle limit. Use the ready scene for new experiments.

The original **Test Scene/Mountain Scene Brush Test.max** and original artist
diagnostics are preserved. The [technical repair report](STABILITY_UI_019.md) and
machine evidence identify the exact delivered package, scenes and accepted tests.
