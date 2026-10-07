# Changes in this campaign

## Production UI

The ten pages follow the approved prototype: Receiving surfaces, Layers & paint sets, Models & source containers, Population, Coverage & painting, Include / exclude areas, Transforms, Spacing & cleanup, Viewport & render, Statistics & diagnostics. Enable, Manual/Live and Update now stay together at the top. Infrequent settings are inside each page's closed Advanced disclosure. Empty setups expose global controls without guessing a layer.

`approved-layout-rows.cjs` declares order and disclosure. `approved-layout.cjs` composes the existing canonical handlers, qualifies their local names and lays out controls. `templates/approved-main-ui.ms` retains the SDK's native pages. The optional editor and container Modify view reuse the same definitions and bind the same records. Stable semantic MCP control IDs remain independent of presentation; all 240 current controls and the disposition of 245 old controls are accounted for.

Cold mount, rolled-up initialization, discarded rollout locals, closed-handler and warm owner/set switching are guarded. There is a one-shot mount timer, not an ongoing UI refresh timer. Advanced, scrolling and selection do not request placement calculation. Spinner captions use separate labels because MAXScript spinner position identifies its arrows rather than the complete caption/field. Numeric fields align right; paired fields stack when narrow, axis fields use three columns. Long help labels resize at layout/bind/fold boundaries instead of polling.

Actual container re-selection exposed native clipping even though the manager's controls were bound and its requested height was 620. Max had arranged the pages before their final measured bodies. The main bind and one-shot mount now refresh native layout after those heights are assigned, including the container properties. This is event-driven layout work; it adds no idle timer or solver dependency.

## Small behavior corrections

The real viewport Move tool exposed a source-following gap. `HelperObject::TransformStart/TransformHoldingFinish` describe sub-object transformations; they did not run for the selected whole helper node. The old direct and simulated-callback fixtures therefore passed while actual dragging left models behind. `source_container.cpp` now observes admitted static node transform changes, freezes bounded recipients and applies their translation at the end of Max's Move hold. A restore object keeps container/source Undo/Redo in that original transaction. Transient weak observers stay out of Undo, unchanged transform notifications are ignored, and recursion/restoration are guarded. There is no movement polling timer, geometry evaluation in the notification or placement rebuild added to this path.

The new whole-node fixture never calls the simulated helper callback. It checks Move, repeated Undo/Redo without an empty Undo entry, combined selection without double translation, a complete group, cancellation and rollback after an independent source edit. The actual pointer rerun remains a separate receipt. Sources follow when the drag is committed; this slice does not move/rotate/scale every source continuously on each mouse sample. Rotation/scale change the boundary only.

The obsolete UI gate that forbade Line/Analyzer selection on multi-set layers was removed. The evaluator already supports those per-set choices; current host tests exercise them. Random/Clusters, Line and Analyzer continue through the same procedural pipeline.

Diagnostic export now retains the primary failure message and adds cleanup failures. A locked temporary file previously allowed cleanup to mask the useful error. The private injected identity failure and positive atomic replacement exercise both paths. MAXScript forbids the original dynamic `throw` expression directly inside a catch body; a helper outside catch raises the final message.

`preview.cpp` and `point_display.cpp` remain unchanged. This campaign does not replace the procedural evaluator, introduce GPU placement, change scene class IDs, change licensing authority or implement artist ML.

## Diagnostic fixtures

Real-asset tools verify matching SDK receipts, use isolated profiles and scene copies, record actual accepted/shown geometry and errors, collect whole-host RAM/GPU counters, and align PresentMon phases using QPC. The private single-slot transport now serializes clients and correlates replies to request paths. An overlapping diagnostic request and invalid stress weights/triangle budget were fixture errors; their earlier measurements are excluded from display qualification.

Fixtures are test support, not installer content or new public MCP tools. Final computer-driven Brush, controlled Undo/Redo, two-column re-selection/scrolling and captions supplement scripted handler checks. Final narrow/wide dimensions have automated coverage; earlier pointer evidence does not qualify a final border resize or every DPI. Failed/intermediate observations remain in evidence, with their interpretation recorded in RESULTS.md.
