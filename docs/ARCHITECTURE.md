# Current codebase architecture

Applies to Cyrus Scatter 0.77, saved schema 54 and `CyrusUnified1`. Use [the artist guide](ARTIST_GUIDE.md) for controls, [the backlog](BACKLOG.md) for unfinished work, and [qualification](Paint_Feedback_0.77_2026-10-10/README.md) for measured evidence. This is the maintained architecture reference; dated implementation reports describe their own snapshots.

## Ownership

| Owner | Responsibilities |
| --- | --- |
| Scatter controller | Ordered layers, setup enable, Manual/Live, global palettes, between-layer relationships, preview and output publication |
| Ordinary layer | Receiving surfaces, models, amount/seed, assignment layout, transforms, masks, spacing defaults, candidate Relax and accepted-union cleanup |
| Paint Area | Named coverage document and one explicit receiver target; shares its layer's models and population |
| Source row | Stable source identity, local alias, identification color, assignment group, weight, scale/lift, forward axis and radius settings |
| Source container | Palette boundary and cached consumer/ownership presentation; optional guarded static source movement |
| Surface Analyzer | Independently updated boundary/path/point results; Scatter consumes its published output |

Older supported 0.74 model-owning sets retain separate models, shares and collision relationships. They are not Paint Areas and are not silently flattened. New layers have receiver ownership; retained older records can still use shared receiver state until explicitly changed. Removing a receiver link preserves inactive paint; recreating a scene node with the same name does not restore its identity.

## Evaluation and publication

The generated controller prepares geometry and keyed candidates, applies supported candidate Relax, coverage/area/falloff and transforms, resolves Edit/radius information, evaluates ordered spacing and accepted-union cleanup, and stages the complete result. Candidate budget and accepted target have different bounded retry semantics. Earlier accepted owners and protected edits affect later acceptance.

Paint Areas combine coverage by maximum within their layer; a candidate is accepted at most once. Areas do not create additional population quotas. Each receiver now has a persistent UUID-salted candidate stream. Density rounds independently per receiver below its allocated cap; Fixed Total and capped Density use area/weight-based largest-remainder quotas with saved receiver-slot tie breaking. Removed quotas drop local suffixes. Reorder and rename do not reseed unchanged receivers; unlink/relink retains their identities. A same-name replacement node has a different identity.

Candidate IDs encode an append-only saved receiver slot plus local ordinal, within the owning population's namespace. A separate schedule places initial quotas before refill and protected-only suffixes; rejection does not renumber IDs. Admission includes per-receiver requirements from moved/cloned Edit inputs and stays bounded to 100,000 candidates per population and the existing root limit. Geometry face indices plus barycentric coordinates locate samples and Brush anchors; they are not persistent identities across topology changes. Orientation uses geometric face normals. No rest-pose or arbitrary-remesh correspondence is introduced.

Receiver-local row caches include generation settings, source state, receiver geometry/UV hashes, relevant spline geometry, Analyzer revisions and texture state. Adding a receiver can reuse old candidate rows, but Update still reads geometry/area for validation and runs shared acceptance/publication. This does not claim zero host geometry evaluation or incremental GPU upload. Projection and candidate Relax use the candidate's receiver; changing its own quota/neighborhood can change Relax positions. Shared masks, collision scopes, cleanup and protected edits can change which candidates survive.

Receiver-aware Edit/radius receipts compare common generation settings and known receiver geometry while allowing membership changes. Missing targets remain inactive; geometry changes are guarded. The first rebuild of an older combined-sampler scene changes placements. Old Edit/radius bindings are explicitly rejected and require artist reset or the old matching build; saved records are not silently rebound. Schema 54 is unchanged because the serialized format is retained, not because old generated positions are preserved.

Brush 0.76 prepares at most 1,000,000 derived dabs and 8,000,000 dab-to-face links per document, including reused strokes. It checks connected-patch growth and resampling before exceeding those counts. The face lookup uses contiguous ordered ranges; reverse evaluation and full replay retain the same paint/erase semantics. Failed preparation leaves the previous immutable field and complete Scatter publication available. Authored history remains intact for Undo or reducing the offending radius/history. These are per-document count bounds, not a total process-memory or full-scene budget; authored copies, Undo, old/new fields, mesh acceleration and feedback have separate costs.

Brush 0.77 retains authoritative receiver-bound strokes and introduces disposable feedback caches. Coverage nodes preserve the pre-gesture value and current maximum dab influence; verified derived-dab prefixes update only the extension. Appends reuse the completed field, while earlier edits, invalid owners/geometry, cancellation and Undo rebuild affected cache state. Conservative footprint refinement still finds interior paint islands; cached feedback weights use forward floating-point composition and are not authoritative placement decisions. Cache storage is capped at 393,216 coverage nodes and 100,000 feedback anchors per document; stopping a paint session releases the two feedback caches. This is not a whole-scene byte budget.

Candidate membership evaluates ordered history backwards and can stop only when a conservative residual interval proves the fixed candidate threshold is accepted/rejected. Near a threshold it finishes the original evaluator; overlapping Paint Areas remain a max union. A new gesture's Undo record stores that stroke, while whole-document operations retain their existing snapshots. Feedback arrays publish together after successful evaluation. The UI observes changes at a requested 33 ms timer interval and avoids rebuilding the history list during an unfinished gesture; the host message loop controls actual latency. No worker, GPU paint compute or retained tint drawing was added.

Publication commits compatible rows, sources, radii, statistics and display/output state as one complete epoch. Failed successors retain the prior complete publication and report the error. Pending configuration and published output can therefore legitimately differ.

Manual edits wait for explicit Update. Passive browsing, cached inspection and unrelated animation must not publish pending recipes. Cold reconstruction of a missing initial publication is distinct from evaluating warm pending edits. Live invalidation follows relevant dependencies, including relevant animation. Mouse-held interaction can defer scheduled work.

Host geometry access, scene mutation and publication belong on the Max thread. Native workers use copied input. Point Cloud, Mesh and all three Proxy shapes use retained buffers to avoid unchanged uploads. Proxy shares Mesh's immutable source faces and instance transforms, without expanding per-instance proxy triangles in normal operation. The GraphicsWindow fallback reads the same snapshots. Retained drawing uses GPU graphics, not GPU placement computation.

Explicit Update enters root evaluation once: that evaluation stages and installs every layer atomically. Installed previews remember their Analyzer publication revision. Scatter validates enabled Analyzer dependencies before a successor solve and preserves its last complete publication on stale-input failure. An unchanged cached read continues to consume the published guides even when the Manual Analyzer has pending edits. Analyzer stores publication freshness, linked input references, a settings/transform signature and the published time-validity interval; a drainable source-event queue invalidates the saved freshness flag. Validation, Analyze and save drain pending geometry notifications; delayed notification still schedules Live work after mouse release. Parameter replay during scene loading/merging must not overwrite the saved flag. Older guides without a freshness record require explicit Analyze.

## Source map

| Area | Maintained source |
| --- | --- |
| Controller, ownership, scheduling, publication, render bridge | [unified-core.ms](../AminScatter/tools/ui/templates/unified-core.ms) |
| UI generation and shared layouts | [generate.cjs](../AminScatter/tools/ui/generate.cjs), [approved-layout.cjs](../AminScatter/tools/ui/approved-layout.cjs), [approved-layout-rows.cjs](../AminScatter/tools/ui/approved-layout-rows.cjs) |
| Sampling and host preparation | [scatter.cpp](../AminScatter/src/scatter.cpp), [max_bridge.cpp](../AminScatter/src/max_bridge.cpp) |
| Receiver quotas, stable IDs, schedules and binding receipts | [receiver_plan.cpp](../AminScatter/src/receiver_plan.cpp), [receiver_bridge.inc](../AminScatter/src/receiver_bridge.inc) |
| Ordered acceptance and work limits | [procedural.cpp](../AminScatter/src/procedural.cpp), [group_spacing.cpp](../AminScatter/src/group_spacing.cpp) |
| Brush storage and host integration | [brush.cpp](../AminScatter/src/brush.cpp), [brush_host.cpp](../AminScatter/src/brush_host.cpp) |
| Individual Edit | [cyrus_edit.cpp](../AminScatter/src/cyrus_edit.cpp), [cyrus_edit_stack.inc](../AminScatter/src/cyrus_edit_stack.inc) |
| Display and dependency validity | [preview.cpp](../AminScatter/src/preview.cpp), [point_display.cpp](../AminScatter/src/point_display.cpp), [input_validity.cpp](../AminScatter/src/input_validity.cpp) |
| Container helpers | [source_container.cpp](../AminScatter/src/source_container.cpp), [container-system.cjs](../AminScatter/tools/ui/container-system.cjs) |
| Separate Analyzer | [module guide](../CyrusSurfaceAnalyzer/README.md) |
| Bounded automation | [MCP guide](../CyrusMCP/README.md), [capability matrix](Current_System_2026-10-05/CAPABILITY_MATRIX.md) |

Edit the template/generator and regenerate `AminScatterObject.ms`; never fix only that generated file. Installation is a separate authorized step. Preserve internal registration identities. Stable-only Edit storage rejects retired development formats rather than guessing a correspondence.

## Independent boundaries

MCP 0.73/Plan 0.73 is a restricted authoring subset, not access to every local control. Full Brush/container/Edit authoring and render jobs remain unavailable. The offline Design Lab is experimental and grants no host authority. Licensing is an independent default-off foundation. See the component guides for those contracts; do not infer new capabilities from historical plans.
