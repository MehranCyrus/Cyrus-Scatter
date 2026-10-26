# Source Preparation Editor — 0.87.4

Max 2027. Use the matched MZP and restart before trying the editor. The [delivery receipt](DELIVERY_0874.md) records the exact tested payload and remaining limits.

## Start simply

1. Select the plant's Scatter layer and choose **React to colliders**.
2. Add the original plant source using **+** if necessary.
3. **Prepare model** remains the automatic workflow. To choose parts yourself, click **Edit preparation…**.
4. Click a leaf or connected piece in the popup. Ctrl adds; Alt subtracts. Box and Brush select groups of whole pieces.
5. Choose **Bend**, **Follow stem**, **Keep fixed**, or **Automatic**. The preview updates automatically.
6. Click **Use preparation** when ready. **Cancel** discards this window's draft.

The popup shows the entire admitted source mesh independently of Scatter's foliage display percentage. It does not alter the original mesh. All instances using the source slot reuse its prepared definition; other layers retain their own settings.

## Choose the behavior

| Choice | Use it for |
| --- | --- |
| Bend | A supported separate leaf/blade or stem that needs its own flexible guide. |
| Follow stem | A rigid flower head or detail. After assigning it, click its parent stem in the model. |
| Keep fixed | A pot, decorative base or other part that should keep its rest shape within the plant. |
| Automatic | Clear the selected pieces' authored corrections and let preparation infer their behavior. |

Green represents bending parts, blue attached details and brown fixed parts. Gold is the current selection. Fixed geometry still moves with the plant's scatter placement. It is not removed or automatically registered as a collider.

## Navigate and select

- Right drag: orbit. Middle drag: pan. Wheel: zoom. **Frame** fits the displayed source.
- **Visible only** selects frontmost geometry. Turn it off to select through the model.
- **Isolate** toggles the selected pieces inside the popup.
- **Select all**, **Invert selection**, **Clear selection** and **Select same material** help select many pieces. Material selection expands to complete connected pieces.
- Popup **Undo / Redo** (Ctrl+Z / Ctrl+Y while the popup is active) restores draft edits. After Use, ordinary Max Undo/Redo restores the scene's preparation.

“Whole piece” means connected mesh geometry. If the model has several leaves welded into one branching piece, they cannot yet be edited independently in this version. No partial-face weight painting or destructive splitting is performed.

## Repair a guide

Open **Edit guide…** for the optional controls:

- **Set root end**: select one guide-bearing piece and click its intended base end. Preparation extracts and displays the supported base patch.
- **Flip direction**: reverse the guide's intended base/tip direction and rebuild its bindings.
- **Move guide point**: select one guide-bearing piece and drag an interior point near a bend in its guide. The current representation supports 3–16 points. This edits the guide, while preserving the source's rest mesh.
- **Pick parent stem**: connect the selected branch/detail to a bending stem; its attachment is inferred near the parent's guide. Invalid cycles or distant links are rejected.
- **Make root**: return a supported guide to a planted root rather than a child branch.

Minimum stem, stiffness and branch connection remain the existing layer settings in Interactions. The popup displays their captured values. If these settings or the source change outside the editor, close/reopen it before applying a conflicting draft.

## Test contact

**Test sphere / drag** creates a private sphere in the popup. Drag it in the model view; its radius is in centimetres and its test gap is in millimetres. It uses the layer's captured stiffness and the existing contact fitter. Toggle the sphere off to return to rest.

The private sphere creates no scene node and is not saved as a collider or a baked pose. The actual scene continues to use its Collider layers and Cyrus Edit transforms. A collider intersecting an immovable root or fixed part can be impossible to resolve; the editor reports that conflict rather than removing leaves.

Changing behavior or guides schedules a complete draft update. Wait until Ready before Use. Repeated Prepare and supported automatic setting refresh preserve the committed authored edits. Use does not apply unrelated pending Manual Count/placement changes.

## Keep and share the result

Save a `.max` copy. Authored source preparation is guarded by the new saved formats, so preserve originals if you need an older build. Current recipe packages do not carry prepared contact definitions; use a Max scene for this setup.

The delivered trials are in `Test Scene/CyrusScatter_0874_OwnedTests/`: one fern and one grass workflow. Their exact final collider/contact state is recorded in the delivery. Renderer-specific shading and broader plant families retain the qualification limits there.
