# Editor workflow and layout

> Original 26 October research/proposal. Implementation was subsequently authorized as 0.87.4. See [current decisions](IMPLEMENTATION_0874.md) and [executed evidence and remaining limits](DELIVERY_0874.md); planned rows below are not all passed.

**Proposed interface.** Labels and behavior below are an implementation specification, not controls available in 0.87.3.2.

## Entry from Interactions

Keep the existing source list, + / x, Prepare model and ordinary settings. Add **Edit preparation…** directly below Prepare model. It is enabled for a valid mesh source even if automatic preparation failed. The popup always edits the original source slot selected at opening; it does not select or analyze a scattered instance.

The normal path remains: choose **React to colliders**, add a source and press **Prepare model**. Artists need the editor only when they want more control or preparation reports a specific unresolved part.

## Proposed window

Initial size approximately 1000 × 700 logical pixels, resizable; fit within the available monitor. Minimum practical layout 760 × 540, with a scrollable control column. Measure at 100%, 150% and 200% DPI rather than treating these sizes as qualification.

```text
┌ Source Preparation — Neottopteris • Plant layer ──────────────────────┐
│ Select [Click ▾]   [Visible only ✓]  [Isolate]  [Frame]  [Undo] [Redo] │
├───────────────────────────────────────────────┬───────────────────────┤
│                                               │ Selected: 4 pieces    │
│                                               │                       │
│              ORIGINAL MODEL                   │ Behavior              │
│                                               │ [Bend              ▾] │
│        Neutral shaded mesh                    │                       │
│        Colored regions                        │ [Select by material…] │
│        Highlighted selection                  │ [Reset selected]      │
│        Guides and root dots                   │                       │
│                                               │ [Edit guide…]         │
│                                               │                       │
│                                               │ From layer (read-only)│
│                                               │ Minimum stem   5 mm   │
│                                               │ Stiffness      0.5    │
│                                               │ Branch connection15cm │
├───────────────────────────────────────────────┴───────────────────────┤
│ [Guides ✓] [Region colors ✓] [Test sphere]     [Preparation limits ▸] │
│ Ready • 36 bending pieces • 8 following • 47 fixed • 0 unresolved   │
│                                   [Cancel]     [Use preparation]    │
└───────────────────────────────────────────────────────────────────────┘
```

Numbers in this wireframe are illustrative, not a prediction for the fern. The 3D view is a dedicated editor preview, not a render of the production material.

The side column is contextual. **Follow stem** reveals **Pick stem** and the selected guide/attachment. **Edit guide…** reveals only root/direction/point/parent tools. Existing Minimum stem, Stiffness and Branch connection remain editable in Interactions with their current layer ownership; the popup shows a read-only summary. Do not display an enormous permanent list of all guides or every resource limit.

## Selection

| Action | Exact behavior |
| --- | --- |
| Click | Select the nearest visible triangle's whole connected piece. Clear the previous selection unless adding/subtracting. |
| Ctrl / Alt | Add / subtract from the selection. Keyboard hints remain in a small help row, not hover tooltips. |
| Rectangle | Select pieces with visible surface samples inside the rectangle. A tiny or occluded piece can be reached by zooming, isolating or selecting through. |
| Selection brush | Brush adds/removes whole pieces to the selection. It does not paint continuous deformation weights or automatically change their behavior. One stroke is one local Undo step. |
| Visible only, default on | Select only frontmost geometry at a pixel. Both sides of a leaf are pickable; this is depth visibility, not backface culling. |
| Visible only off | Select intersected pieces through the model. Show a persistent “Selecting through” indicator. |
| Isolate | Toggle isolation of the selected pieces inside this popup. No scene hide/freeze or source visibility change. |
| Select by material | Select pieces using a chosen material ID from the captured mesh. Show mixed-material pieces; expand to the entire piece and report that expansion. No material-based automatic rigging. |
| Select all / Invert / Clear selection | Available in the selection menu. Operate on the current isolated/viewable piece set, so many decorative pieces can be selected without thousands of clicks. They change selection only. |
| Escape | Cancel the current gesture/tool. It does not discard the whole session. |

Unselected geometry remains visible. “Reset selected” removes the selected pieces' authored overrides and regenerates them automatically; it does not delete their source faces. “Reset all edits” belongs in the editor menu, is locally undoable, and has no effect until Use preparation.

Use neutral gray for Automatic, green for Bend, blue for Follow and a muted brown for Fixed. Gold outlines mark selection; red outlines mark unresolved parts. Include text labels/counts so color is not the only signal. Show a parent line and root dot for the selected guide rather than drawing every diagnostic at once.

## Corrections

**Set root end:** for one selected guide, click its intended base end on the piece. Use that as a seed for the supported tube-ring or ribbon endpoint anchor extraction, then show the resulting anchor patch. This changes preparation, not the original mesh or its world position. If the seed cannot produce a reliable base patch, keep the draft unresolved and offer Automatic/another end; do not create an arbitrary physical pin.

**Flip direction:** reverse an inferred guide and regenerate its anchors, frames, descendants and attachments. It must not simply reverse the line display. Reject ambiguous attachments rather than leaving stale parent-span indices.

**Move guide points:** adjust interior points of one existing guide. Keep the root patch fixed and maintain the current supported 3–16 control-point representation. Recompute rest bindings so the unchanged source mesh is reproduced exactly when the test sphere is off. Moving a guide is not a sculpt operation on the source.

**Connect to stem:** pick an existing parent guide and a location along it. Reject cycles and out-of-reach links. The selected guide becomes a branch, not a ground root. **Make root** detaches that parent only when a valid source anchor patch exists.

**Follow stem:** pick the guide a selected rigid detail should follow. The preview draws its attachment and keeps the detail's shape. An unresolved/missing parent blocks Use. First delivery does not promise independent flexibility for that detail.

Entirely new drawn guides, manual multi-guide skinning, shared-vertex weight painting and virtual splitting of welded plants are subsequent features. Their absence must be explicit when a model needs them.

## Automatic preview and scene commit

Selection, orbiting, framing, isolating and toggling overlays only redraw the editor. They do not prepare the plant or solve the scatter.

Role changes, root edits and structural settings schedule a draft update after the gesture finishes. A short debounce, initially 200 ms, coalesces spinner changes; only the newest revision may become Ready. While working, show the last complete preview with **Updating preview…**. Never present old guides as the result of the newest edits.

**Use preparation** is the only scene-writing action in the popup. It uses the latest complete draft; there is no extra Analyze or Accept button. Disable it while stale, updating, unresolved or incompatible. On successful commit it closes the window and updates applicable contact results. Cancel discards the editor's draft and leaves scene changes made outside the popup untouched.

This commit is distinct from **Update scatter**: it must not consume unrelated pending Manual placement edits. For an already published source, recompute affected contact results on existing placements. If a newly added source is still pending a Manual update, save preparation and report **Prepared; source placement is pending Update scatter**.

Edits affect the selected source slot's instances. Other layers referencing the same node retain their own authored settings. The header names both source and owning layer. Selecting a different layer while the window is open must not silently retarget it.

## Private test sphere

**Test sphere** toggles an editor-only sphere that the artist can drag around one prepared plant. Show its radius and contact gap when enabled. Use the production contact fitter, with root hiding off, and distinguish invalid fixed-root/rigid-part contact from successful bending. This test creates no Max node, changes no timeline or collider layer, and is not saved as scene content.

Turn it off to return to the exact rest mesh. Its pose is transient. Use preparation commits the definition, not the test pose. The real scene still uses its own colliders and validates its own contacts.

The editor draws all admitted source pieces, independent of Scatter's foliage preview percentage. Use neutral solid shading for reliable geometry selection; original materials, UVs and opacity are preserved for the plugin's normal output, not edited here.

## Two artist examples

### Decorative fern

1. Open Edit preparation for the original fern.
2. Select/isolate broad leaves and assign Bend.
3. Use Invert selection or material selection to reach the decorative base and tiny details; assign Fixed or Follow according to how they should move. Do not assume every unselected part should be fixed.
4. Correct a reversed leaf's root end if needed; inspect its guide.
5. Drag the private sphere to check bending, then Use preparation.

### Flower on a stem

1. Mark the stem Bend; mark its flower head Follow stem.
2. Pick that stem as the flower's parent and inspect the attachment.
3. Keep a pot Fixed. Test a side contact and Use preparation.

If several leaves are welded into one branching component, selection highlights the entire piece. Report **This connected piece needs more than one guide. Partial-piece editing is not supported yet.** Do not silently bend the entire bush as one leaf or automatically detach source vertices.

## Useful messages

| Situation | Message and next action |
| --- | --- |
| Missing follow attachment | “3 pieces need a stem. Select them and choose Pick stem.” |
| Invalid root end | “A stable base could not be found here. Pick the other end or restore Automatic.” |
| No guides remain | “No bending stems remain. Restore a Bend/Automatic part, or turn off React for this layer.” |
| Source changed | “The source geometry changed. Your edits are retained, but cannot be applied to this mesh.” |
| Newer draft supersedes a job | “Updating preview…”; discard the obsolete result without an error dialog. |
| Fixed part inside sphere | “The collider intersects a fixed part. Move the collider or change that part's behavior.” |
| Limit reached | Name the measured resource and configured allowance; keep the old result and the draft. |

No hover tooltips are introduced. Keep short inline guidance and a persistent status line. Technical detail can expand under Preparation limits or the report panel.
