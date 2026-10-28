# Panel audit and decisions â€” 0.87.6

The [control ledger](CONTROL_LEDGER.md) records 367 panel controls, seven independent
container properties and the main controller header. This report explains the
presentation decisions. The [qualification](QUALIFICATION.md) separates source
review, actual host events and numerical assertions.

| Panel | Purpose / owner | Decision and observed coverage |
|---|---|---|
| Main header | Controller enablement and Manual/Live scheduling | Keep these together. Pending Manual edits still require Update scatter. No new automatic placement evaluation was added. |
| Layers | Ordered layer membership, identity, visibility and variation | Keep primary. Copy, rename, remove and scalar handlers passed. Visibility and enabled state remain different operations. |
| Surfaces | Layer receivers and optional shared source rectangles | Keep receiver assignment primary; shared-pool tools live in **Surface tools**. Receiver assignment passed. Source rectangles are model pools, not receiving surfaces. |
| Source containers | Selected layer's model collection | Keep the collection mode and create/pick/unlink controls together. Create/unlink passed; automatic imported-source combinations retain existing limits. |
| Layout | Planting positions and source assignment | Keep mode-dependent controls contextual. Correct the garbled Band buttons in the refresh handler itself. Move ordering/details behind **Band order & details**. Grid, Clusters, Bands, source assignment and Band overlays passed. |
| Models & Points | Source membership, identity, weight and transform | Keep Add point / Use point / Replace selected together. Move radius policy and clearance into **Spacing overrides**; Empty sources live with **Assignment groups**. Fix Point tokens entering native node-scale conversion. Add/convert/replace/remove, save/reopen and Point Undo/Redo passed. |
| Amount | Requested population and image/surface density | Keep population and masks together. Use one **Show/Hide density preview** button. Sampling, preview detail and retry policy remain available under **Sampling & display options**. Density preview and scalar settings passed. |
| Painting | Receiver-bound painted coverage and edge behavior | Keep brush and basic fade controls together. Rename inward/outward controls; group **Fade curves**, **Paint preview** and **Spline tools** separately. Disable edge edits while a brush is active and explain Manual pending changes. Numerical fade, clear/fill, density and size parameters passed. |
| Include / exclude | Closed boundaries and surface eligibility | Keep closed-area operations primary. Show slope/altitude ranges only when enabled; show boundary fade distances only for their active effect. Separate **Analyzer tools**. Include/exclude and recovery from missing Analyzer input passed. |
| Transforms | Per-placement appearance | Keep proportional scale, rotation and offset primary. Put separate X/Y/Z scale in **Non-uniform scale**. Scalar handlers and proportional-scale reset passed. |
| Spacing & cleanup | Layer defaults, placement separation and cleanup | Retain explicit default ownership. Put cleanup and selected-instance overrides in **Cleanup & instance overrides**. Native spacing, clearance and boundary suites passed; the generic fixture does not certify every selected Edit combination. |
| Viewport & render | Shared display representation and display budgets | Keep representation, budgets and Fast navigation primary; group **Display options**. All five representation choices passed. This round does not change the renderer or interaction buffer code. |
| Stats & diagnostics | Completed-result inspection and optional recording | Cached statistics stay primary; recorder controls use **Diagnostic recording**. Reading stats and repeated panel browsing did not rebuild placements. |
| Interactions | Prepared source response in the selected layer | Preserve the endorsed Bend/Trim and trunk controls. Prepare on a small ribbon, common response controls, preview percentage and response choices passed. Detailed contact and preparation limits remain secondary. |
| Scene colliders | Ordinary scene objects driving a setup | Keep the existing optional list and clear ownership. Pick/remove passed with a prepared small source. No new scene-collider evaluation path was introduced. |

## Reported problems and actual causes

- **Add Point:** native source-transform code assumed every source entry was a Max
  node. Point/Empty entries are integer row tokens. Reading one as a node failed
  before publication. Integer tokens now bypass node-scale capture while authored
  scale and Z offset remain active.
- **Broken Band symbols:** the generated controls were correctly encoded, but the
  runtime refresh method assigned already-corrupted text. The repair changes that
  assignment to short ASCII labels, so reopening/rebinding cannot restore the bad text.
- **Paint fades looked inactive:** the isolated numerical test confirms both fade
  directions work. A filled receiver has no space to extend outward; overlapping
  Paint Areas can also cover each other's transitions. Manual mode needs Update.
  The UI now explains this state and keeps editable edge settings out of an active
  brush operation. Edge/inner size endpoints remain ordered during editing.
- **Too many controls at once:** secondary disclosures hide presentation only.
  Their authored values still apply when collapsed. Existing mode-specific visibility
  conditions are retained inside the new groups, avoiding empty or irrelevant rows.
- **Narrow columns and swatches:** the owned host's actual layout width was 154
  logical pixels. Sampled control bounds and the native layer/source swatches fit
  this width; swatches occupy x=126 through x=148. No claim is made for all DPI or
  multi-monitor configurations.

- **Library version gate:** three-part release `0.87.6` has .NET assembly version `0.87.6.0`. Both Library guards now compare the normalized four-part identity. The final generation check validates both guards.

## What was deliberately retained

Image density, surface density, Paint coverage and Band previews answer different
questions. They were grouped and named rather than merged into one ambiguous switch.
Likewise, Point and Empty sources, layer visibility and enablement, and authored
placement settings versus display budgets retain separate meanings.

No option was deleted merely to shorten a panel. File dialogs, licensing, renderer
integration, remote Library transactions and physical curve-editor dragging remain
outside this focused UI smoke. Paint curve opening and programmed endpoint publication
passed, as did the three Paint preview choices. The next performance campaign is separate.
