# Cyrus Scatter 0.74 UI refinements

Development source, 8 October 2026. Package/native version **0.74.0**, UI **0.74**, calculation model **CyrusUnified1**, serialization **54**. Analyzer and MCP protocol versions remain independent. No normal-profile installation was performed.

## Installer

[Max 2027 installer](../../dist/UI_Refinements_0.74_2026-10-08/Max2027/CyrusScatter-0.74.0-Max2027.mzp) · [package identity](PACKAGE.json). The local installer contains the exact script and four native modules qualified below; archive integrity, manifest hashes and Max 2027 guard passed. Binaries stay local and are not stored in Git. In Max, choose **Scripting > Run Script**, select the MZP, then **restart Max**. Analyzer and MCP need no update for this pass.

## Implemented scope

- [x] Visible receiving-surface list with additive viewport picking, additive selection by name, deduplication and multi-row removal of assignments. Scene nodes are retained. Existing receiver identity/resource bounds still apply; this adds no UI count limit. Brush still requires one shared receiver.
- [x] Per-object session view state: expanded rollouts, Advanced/Properties disclosures and list heights survive deselection/reselection. All-open, all-closed and mixed states are covered. Restart/save-reopen persistence of view state and exact scroll/column restoration are not added.
- [x] Horizontal drag grips below native list controls, with a 42–900 pixel height range and layout reflow. The height limit bounds presentation, not list membership.
- [x] Independent Properties disclosures for layer/source settings. Lists and actions stay available while those properties are folded.
- [x] Compact layer/source/set action rows, layer name below its actions, square identification swatches and colored layer/model list markers. Only meaningful actions are shown for each list; source removal does not delete scene geometry.
- [x] Optional source labels default to scene-node names; renaming changes the Scatter label only. Clearing the label restores the scene name. Metadata survives copy and scene save/reopen and remains keyed to the referenced source object. Point/Empty placeholder labels/colors retain their existing behavior.
- [x] Source/layer identification colors are separate from cluster color groups. **Viewport & render → Color by** chooses Model or Layer; the existing Solid Color mode overrides identification colors. Points/Proxy and shaded Mesh previews use this presentation, while Mesh retains its real geometry. Material-textured viewport rendering is not added.
- [ ] Layer/set ownership and final terminology. See [the recommendation](../Product_Discussion_2026-10-08/MODELS_AND_PAINTING.md). Current set ownership and brush/population semantics are preserved; the existing Layers & paint sets and Coverage & painting captions remain until that design is resolved.

## Engineering details

Changes originate in the authoritative UI template and generators. All 246 semantic controls remain accounted for by the generated inventory, layout manifest and MCP catalog. Internal class identities are preserved.

UI presentation state is session-only object-local data. Identification metadata is saved independently of calculation keys and source grouping; copying a layer copies its metadata explicitly. Display refresh uses the published source order with the published placement rows. A color change must not evaluate pending Manual placement edits.

Colored list presentation forwards selection to the original component model. Its synchronization suppresses recursive selection/layout callbacks; the draw callback does not relayout or calculate. No new placement algorithm or native display-buffer implementation was introduced.

## Verification and remaining acceptance

The focused [Max regression](../../tools/procedural_lab/Max_UI_074.ms) checks compact action rows, Properties folding, list-height reflow, labels, color isolation, layer copying, pending Manual edits, additive receivers, multi-remove, Undo/Redo, mixed/all-open/all-closed view restoration and metadata save/reopen. Exact final identity and results belong in [EVIDENCE.json](EVIDENCE.json).

Final checks passed: generated UI/catalog consistency, **141 Python checks**, **14 native tests**, and both focused Max 2027 regression functions in a fresh private host. Shared-view checks include source/layer selection, Ctrl-add focus, the double-click action helper, owner isolation, separate container/setup state and popup reflow at two sizes. Both host requests outlasted their 55-second clients; their matching completion records and PASS receipts were inspected before proceeding. The final script includes two selection-action corrections after the native build; every native build input still matches that build's receipt, and the exact final script/native pair passed the host checks.

- [ ] Actual mouse dragging and visual inspection at supported DPI/column widths. The computer-use runtime returned `failed to write kernel assets: The system cannot find the path specified` before window access. Host-script checks do not substitute for pointer and screenshot acceptance.
- [ ] Artist review of icon glyphs, color markers, keyboard selection and narrow/wide popup/container layouts.
- [ ] Max 2026 runtime; it is not installed. No new renderer or comparative FPS qualification is claimed.

The [discussion backlog](../Product_Discussion_2026-10-08/BACKLOG.md) remains the place to collect further requests. Finish this interaction review and the ownership decision before expanding into asset downloads, broad Forest/Chaos feature parity or a performance rewrite.
