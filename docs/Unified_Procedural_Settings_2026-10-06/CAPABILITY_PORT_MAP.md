# Capability ports and setting ownership

6 October 2026. Proposed target contracts, grounded in the [current 34-family review](../TyFlow_CyrusScatter_RnD_2026-10-06/CAPABILITY_MAP.md). The [245-control register](CONTROL_PORT_REGISTER.csv) accounts for the present semantic controls; it does not enumerate every parameter or certify every combination. Before each code deletion, extend its relevant row with actual persisted-field, caller, invalidation and test evidence.

## One model with explicit ownership

| Owner | Settings/data it owns |
| --- | --- |
| Scatter controller | Receiving surfaces, enable, Manual/Live, global source pool, layer order, inter-layer pair rules, viewport/output limits, renderer lifecycle and diagnostics. |
| Layer | Population count/density and seed, generation/assignment, include/exclude and Analyzer/falloff inputs, random transforms, default self-spacing, default sibling spacing, cleanup and optional constrained Relax. |
| Paint set | Stable identity/order, name/enable/visibility/share, independent sources and Brush history, declared source-pool selection, self-spacing override, earlier-set coverage references and explicit sibling-pair exceptions. |
| Source record within each set | Stable source reference/identity, weight, color/group, scale, Z offset, forward axis, radius/follow-scale and Point/Empty flags. Shared geometry does not merge independently authored settings across owners. |
| Instance | Stable candidate/Edit identity, artist transforms/delete/clone state and radius override. Overrides retain their binding guard. |
| Source container | Stable node identity, boundary dimensions/frame, label, links to consuming owners and one movement-owner relationship per following source. It has no separate population or collision engine. |
| Editor/session | Selected owner/topic, expansion, scroll, label cache and presentation state. Changing these does not change the procedural recipe. |

Use a small explicit field/ownership table and normalized evaluation inputs over the working records. Do not replace the C++ kernels, introduce a general node graph, or move the entire UI to a new framework as part of cleanup. Existing internal shadow fields may be removed after consumers are changed and tested; they must not become additional editable copies of a layer setting.

Layer population is divided between enabled paint sets using the existing allocation contract. Keep ten **total** populations for this slice. Growing the limit is a separate measured resource decision. Manual retains the previous complete publication while edits are pending; Live publishes after relevant edits settle. Preview limits change display only.

## Calculation and failure boundaries to preserve

Keep the working [procedural pipeline](../TyFlow_CyrusScatter_RnD_2026-10-06/CYRUS_PIPELINE.md) as the comparison baseline. Resolve relevant input validity and layer/set defaults, admit the bounded candidate pool, and reuse unchanged preparation. Generate deterministic candidates/source assignment and transforms with stable ordinals; apply Area/density/falloff/Brush eligibility at the documented support anchors, retaining the deliberate protected-Edit exception. Apply artist transforms and source/instance radii, then resolve layer order, sibling-set rules and self rules. Cleanup/refill remains bounded and operates on the accepted layer union.

Stage accepted rows, source correspondence, radii, statistics, Edit state and preview/publication data before committing one coherent epoch. On a failure, roll back staged mutation and retain the last complete publication; do not erase Brush histories, radius overrides or valid buffers to hide the error. Preview, exact output, renderer and publication export consume that same accepted state. This is CPU/publication coherence, not a promise of an atomic transaction with a GPU driver.

New assignment, Relax and container changes enter those stages deliberately. Browsing the UI is outside the calculation recipe. A placement/eligibility edit, a display-budget change, a metadata rename and a source-palette translation must not all trigger the same blanket “clear everything” invalidation.

## Port map covering every capability family

| Family | Disposition in the unified model |
| --- | --- |
| C01 Enable/controller | Retain. One evaluator; procedural default; remove policy conversion UI. |
| C02 Receivers/units | Retain supported receivers, transforms, units and target guards. No silent unit migration. |
| C03 Layers/order | Retain explicit top-to-bottom order, stable IDs and copy/remove/reorder rules; remove old priority arbitration. |
| C04 Paint sets/defaults | Retain shared layer defaults/population, independent source/paint data and Base ownership. |
| C05 Asset palette | Retain all per-owner source settings and persistent parked records. |
| C06 Point/Empty | Retain distinct placeholders/counts and the existing weighted-Empty accepted-target restriction. |
| C07 Source containers | Extend with labels, linked Modify editing and source movement; preserve membership semantics. |
| C08 Source transforms/radii | Retain units, offsets, orientation, source radius and follow-scale behavior. |
| C09 Population/seed | Retain deterministic RNG channels and pre-rejection ordinals. |
| C10 Budget/target/refill | Retain separate candidate-budget/accepted-target modes, finite attempts/rounds and honest shortfalls. |
| C11 Density texture | Retain in-place/nested map dependencies and clean-input reuse. |
| C12 Include/exclude | Retain the actual Area domain and supported boundaries. |
| C13 Analyzer Area/falloff | Retain the Analyzer as a separate cached producer with its own Manual/Live controls. |
| C14 Brush coverage | Retain editable Paint/Erase, flat/curved static meshes, anchors and captured-view behavior. |
| C15 Brush history/persistence | Retain stroke editing, Undo/replay and geometry guards; BR-01 still needs diagnosis. |
| C16 Background composition | Retain separate Outside Coverage, Between Plants and bounded replacement controls. Earlier sibling references stay explicit. |
| C17 Random/clusters | Retain assignment and deterministic copied-data worker behavior. |
| C18 Line/Analyzer assignment | **Port**, including bands/strokes, direct-source/color-group choices, scale, edge/corner/forward/street orientation and published Analyzer channels. Resolve source choices against each set's stable source identities. Do not leave disabled legacy controls behind. |
| C19 XYZ transforms | Retain rotation/scale/whole-scale/movement/projection/reset behavior. Surface projection performance work stays separately measurable. |
| C20 Three collision scopes | Consolidate into self, sibling-set and layer-pair rules with `factor × (rA + rB) + gap`, XY/3D and explicit overrides. Keep deterministic winners and protected conflicts. |
| C21 Edit/instance radius | Retain protected artist edits, clones, stable bindings and stale-binding denial. |
| C22 Cleanup | Retain isolated/small-island cleanup over the accepted layer union and consistent final statistics. |
| C23 Relax | **Port with a defined movement/eligibility contract**, not by deleting guards. Keep finite iterations/strength/movement bounds and protected Edit behavior. See below. |
| C24 Manual/Live | Retain relevant-input validity and coalescing; no global per-frame or idle scene scans. |
| C25 Preview | Retain 0.63 Point Cloud and 0.64 Mesh paths, budgets, lifetimes and unchanged-generation upload reuse; Proxy remains a separate draw-cost measurement. |
| C26 UI | One selected-layer Modify view, optional shared-model popup, guarded warm retargeting and automatic field saving. Retire duplicate pages/factories only after a caller audit. |
| C27 Statistics | Retain published/pending distinctions and accepted/rejected/protected/shortfall categories. Container counts identify saved versus active source models. |
| C28 Renderer | Retain epoch-based exact output, callback exclusion, verified Stop handling and previously qualified floating-IR slice. Docked IR and long sessions remain gates. |
| C29 Bake/clear | Retain exact published source/transform/material association and safe output cleanup. |
| C30 Undo/save/load | Retain supported current identities, authored data and transaction behavior; retire only old development schema migrations. Never alter original artist files in this work. |
| C31 Publication/export | Retain passive cached pages and epoch consistency. Version changed configuration fields explicitly; do not label rows as a complete portable recipe. |
| C32 Diagnostics | Retain integrated bounded/off-by-default recording; add useful container causes, not hot-loop printing. Address the documented export-cleanup failure separately. |
| C33 MCP | Port the useful closed-plan authoring subset into an explicit new schema/model. Retire schemas 1/2 with clear early rejection; never reinterpret them as new semantics. Preserve passive reads, enrollment, freshness, local approval, bounded work, transaction/Undo. |
| C34 ML/design lab | Preserve the small offline experimental ranker and proposals. No new trained/reference-image capability is implied. |

## Features that need behavioral decisions in their port

**Line and Analyzer assignment:** layer settings define the pattern field; each set supplies its own allowed sources. Resolve groups/source references by identity, never a sibling's row index. An empty source selection for a band must have an explicit empty/ineligible result, not an accidental random fallback. Preserve existing single-set outcomes as comparison fixtures. Multi-set behavior is a new qualified combination; removing a current rejection is insufficient. Include radius/scale/orientation after assignment in the normal downstream collision pipeline.

**Relax:** the current point and boundary movement algorithms are not qualified with procedural/Brush/shared spacing. The recommended first integration places ordinary-candidate relaxation before final eligibility/Brush and protected Edit application, then uses the existing three-scope solver. Recompute support anchors for moved candidates; keep authored Edit exceptions deliberate. A boundary operation that needs an accepted layer union requires staged movement, eligibility rechecks and scoped collision revalidation before publication. That is a separate port, not a late unvalidated position change. Defaults remain off; unsupported combinations remain explicit until their tests pass. Do not retire the only working old execution path and call this port finished while it is still missing. Expected placement differences from moving a stage must be documented and accepted against the new contract, rather than presented as bit-for-bit old-result parity.

**MCP:** current host apply is tied to policies 1/2; [the policy-3 compiler](../../CyrusMCP/cyrus_mcp/procedural_plan.py#L1) has no host adapter. This plan requires an honest typed successor for the already-supported authoring subset or an explicitly incomplete development milestone. It does not permit deleting the mutation guard and exposing arbitrary plugin settings. New Brush/container/Edit authoring tools can stay future work. Until the successor host slice passes, policy-3 inspection remains read-only.

## Remove duplication without changing defaults accidentally

Existing constant self-distance maps to factor 0 and gap `2 × collisionRadius`; source-radius rules remain separately expressible. Old higher-priority/pair/blocker controls become explicit order and canonical pair rules, not a second hidden collision pass. Self rules, sibling rules and inter-layer rules must remain independent.

All parameter fields save on their appropriate change/commit event; no generic Apply spacing step. Keep explicit artist actions such as Paint, Erase, Fill, Delete stroke, Assign selected instance radius and destructive resets. Retaining an action button does not imply continuous polling.

The port register uses **retain**, **merge**, **port** and **retire** dispositions. Removing old schema parsing, stale version upgrades and unused generated declarations is distinct from deleting normal authoring inputs such as ordinary Rectangle shapes or the cached Analyzer. Review dependencies before deleting either.
