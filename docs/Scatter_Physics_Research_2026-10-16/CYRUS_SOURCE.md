# Current Cyrus source investigation

16 October 2026. SOURCE unless marked otherwise. The inspected sources are fingerprinted in [EVIDENCE.json](EVIDENCE.json). Required behavior is in [ENGINEERING_FOUNDATION.md](../ENGINEERING_FOUNDATION.md); the [I06 handoff](../plans/improvement-program/I06_0850.md) supplies historical qualification of its exact 0.85.0 pair, not the present dirty tree.

## Source state

The working tree contains pre-existing gallery/assets/recipe and documentation changes. Its CMake project declares 0.85.1, controller guards require that version and recipe format 5, while README still points to the delivered 0.85.0 baseline. Do not combine this source with that baseline's binaries for a host experiment. This research writes only this folder, one navigation row in `docs/README.md` and ignored research artifacts.

The end audit observed concurrent changes to `unified-core.ms`, `recipes_bridge.cpp`, `recipes.ms` and the generated script. Relevant preparation/publication and recipe sections were rechecked. In particular, `procPreparationKey` is now a named helper for the existing preparation key. No physics capability was found in these changes. The evidence retains baseline and end fingerprints; this was not a transactional frozen-source study. No concurrent edits were reverted or claimed as ours.

## Trace from gesture to displayed output

| Stage and source | Implemented behavior | Physics implication |
| --- | --- | --- |
| [brush_host.cpp](../../AminScatter/src/brush_host.cpp), `PaintDocument`, `prepare` | ReferenceTarget owns the Brush document. Host evaluates/triangulates the receiver and copies mesh data. The adapter binds Max Painter and stores/restores Painter options. | Reuse picking/session concepts; do not put physics state into the existing coverage document. |
| Same file, `StartStroke`, `addPoint`, `PaintStroke` | Copies the committed document to pending state, resolves a hit against the same numeric surface snapshot, unions/subtracts a swept footprint and updates feedback. | An emitter needs actual birth records, not Boolean union alone. |
| [brush_surface.cpp](../../AminScatter/src/brush_surface.cpp), `Surface::hit` | Numeric triangle hierarchy provides nearest ray hit; face+barycentric anchors locate points on a mesh snapshot. | This lower-level picking component is more reusable than the projected coverage model. |
| [brush.cpp](../../AminScatter/src/brush.cpp), `validateProjection`, `domain` | Coverage requires a single-valued receiver-local XY projection. Closed/folded/stacked projected sheets are rejected. | General physics colliders cannot share this restriction. Keep collider preparation separate. |
| `EndStroke`, `CancelStroke` in `brush_host.cpp` | One native Undo record publishes a successful pending document; cancellation/failure preserves the previous document. | A Physics gesture needs an equivalent transaction for emitted IDs and final transforms. |
| [unified-core.ms](../../AminScatter/tools/ui/templates/unified-core.ms), `CyrusStartBrush`, `CyrusBrushTick`, `CyrusStopBrush` | Script owns selected-layer/session coordination and reacts to native status. | Preserve a valid owning layer across panel rebuilds, removal and owner switching. |
| Same template, `cspImpl_placements`, `procApplyPaint`, `applyOrientation`, `procPrepare` | Generates receiver candidates, applies Paint/attributes/orientation/Edit and surface filters with keyed preparation. | Settled rows need a dedicated preparation branch; they are no longer constrained to the original receiver surface. |
| [group_spacing.cpp](../../AminScatter/src/group_spacing.cpp), `resolveVariable` and [procedural.cpp](../../AminScatter/src/procedural.cpp) | Radius-based rejection, priority/protected rules, target/refill and cleanup accept a population. | These are placement policies, not rigid-body dynamics. Post-solve rejection could remove a support from a pile. |
| Template, `evaluateProcedural`, `procStagePreview`, `procStagePublication` | Stages compatible owners, rows, sources, radii, metadata and preview, commits an epoch, restores on failure. | Reuse the publication discipline; generalizing the data inlet still requires design and tests. |
| [point_preview.h](../../AminScatter/include/point_preview.h), [point_publication.inc](../../AminScatter/src/point_publication.inc) | Retained geometry/instance snapshots and resource admission support display reuse. | A display route exists. Repeated moving-transform uploads during spraying have not been benchmarked or designed. |

Current brush feedback preparation uses a 16 ms interval and the script status timer uses 33 ms; normal scatter publication is deferred during a held gesture. These are scheduling choices, not measured cursor latency or FPS. Throttling visual updates must not drop authored emission samples.

## Important distinction: ray hits versus coverage support

`Surface` itself builds a 3D ray-query hierarchy. The local-XY restriction enters projected domain/field preparation. Therefore, we can consider a general 3D physics picking adapter without replacing ordinary Paint's representation. It would still need explicit policies for visible surfaces, backfaces, multiple eligible receivers, off-surface samples and nonuniform transforms.

The low-level constructor has its own numeric mesh limit; that is not the complete Brush authoring admission boundary. Likewise, the existing million-candidate root limit is not a physics-body capacity or response-time guarantee. Every new stage needs its own bounded count, scratch, contact and retained-result budgets.

## Data and lifecycle gaps

1. **Birth identity:** current candidate keys encode receiver-based samples. Physics needs persistent owner/stroke/emission identity; a solver's temporary BodyID must not become a scene identity.
2. **Authoritative transforms:** surface rows carry face/barycentric correspondence and follow projection/orientation policies. A leaf resting on another leaf has a world transform, not a meaningful new street barycentric locator. Preserve the original spawn anchor separately.
3. **Proxy geometry:** existing Auto Radius produces conservative spacing bounds, not contact shapes. Collision hulls require their own source-frame, scale and revision keys.
4. **History:** existing vector documents intentionally retain no stroke replay history. Physics Area can consume coverage; Physics Brush must author a separate emission document. Do not resurrect retired stroke compatibility inside ordinary Paint.
5. **Persistence and recipes:** [recipes.h](../../AminScatter/include/recipes.h), [recipes.cpp](../../AminScatter/src/recipes.cpp) and [recipes.ms](../../AminScatter/tools/ui/templates/recipes.ms) implement closed static settings/Paint/assets formats. They do not establish a Physics result format. Scene save and portable recipe behavior both need an explicit successor contract.
6. **Worker lifetime:** [execution.h](../../AminScatter/include/execution.h) uses synchronous ranges with joined workers and numeric input. It does not provide a long-lived cancellable simulation service. Time slicing or a dedicated worker requires a new bounded lifetime design; host calls still stay on Max's thread.
7. **Failure retention:** preserve all committed strokes and unrelated layers if a successor runs out of contacts, memory or time. Never silently commit a pile after the engine reports dropped contacts.

## Contracts selected for the proposal

F01/F03: layer ownership and explicit collision relationships. F02: birth choices are stable under a specified replay scope, but interactive bodies are causally coupled. F04/F08: Manual/Live and browsing reuse remain intact. F05/F06: atomic publication and bounded resources. F07: host-thread access and worker shutdown. F09/F10/F11: geometry bindings, physical units and saved state.

B26 remains relevant: current heavy MAXScript allocation can clear Undo under low heap headroom. Store large proposed Physics arrays natively and measure the full transaction; that is a design hypothesis, not a B26 fix. B04's physical input/heavy-scene limits and B08's geometry stress also remain open. See [BACKLOG.md](../BACKLOG.md).
