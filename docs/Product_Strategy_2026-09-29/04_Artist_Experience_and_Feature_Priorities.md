# 04 — Artist experience and feature priorities

**Everything labeled U or F below is proposed. Existing controls remain supported.**

## U1 — A successful first five minutes

Provide a compact setup path: choose surfaces → choose sources → create a populated first layer → choose Count or Density → preview → render preflight. Default preview should be inexpensive and its status obvious. An empty controller should explain the next missing input rather than require the artist to discover a particular rollout order.

Keep detailed controls in progressive sections: Setup, Distribution, Rules, Variation, Edits, Display/Render. Preserve familiar advanced workflows during a staged UI change. Do not redesign all ten generated rollout factories at once.

**Acceptance:** a new tester completes a simple scatter from the quick start; no blank result without an explanation; defaults use scene units correctly; keyboard navigation and 100/150/200% DPI remain usable. A scripted test cannot replace visual inspection.

## U2 — Explain the population

Show separate values for requested candidates/target, placements after rules, edited result, displayed representation, and render transport count. For density mode display the area and units used and whether the cap was applied. For edge rows explain that spacing defines population.

Add a collapsible “Why this result?” view with stage counts: surface validity, density/masks, clearance/collision, source filtering, final cleanup, edits. These counts must come from the real pipeline. Do not invent additive rejection totals where retries or overlapping reasons make them misleading.

**Acceptance:** a zero-result fixture points to a relevant rule; counts reconcile at each actual boundary; inspecting status does not trigger another evaluation.

## U3 — Explicit freshness and recovery

Distinguish Current, Updating, Manual preview pending, Last valid preview, and Error. A failed proposed transactional rebuild retains the previous display with an unmistakable stale label. Final render must evaluate the intended current state or fail clearly; it must not quietly render the old preview.

Keep errors local to the affected layer when possible, with an action such as pick a replacement source or reduce a work budget. Preserve a useful diagnostic detail without overwhelming the main panel.

**Acceptance:** failed rebuild, deleted source, disabled Analyzer, manual mode, undo, and rapid input changes cannot leave a stale result labeled Current.

## U4 — Make editing consequences predictable

Before a base-generation change that could invalidate edits, show the reason and affected layer/stack. Offer deliberate choices appropriate to the implemented system: cancel the change, save a scene copy, keep suspended records, or explicitly reset edits. Do not promise automatic remapping until a validated identity model exists.

Expose counts of active/suspended/invalid edit records. Explain that final manual moves and edge offsets can override earlier placement constraints. A future “validate final clearance” overlay can flag conflicts without silently undoing artist choices.

**Acceptance:** move/clone/delete through several modifiers survives toggle/undo/save; an unresolvable change never reassigns an edit to an unrelated instance.

## U5 — Readable layers and dependencies

Add duplication, meaningful naming, enable/solo, and a clear list of blockers/dependencies where missing. Any new reorder operation needs stable layer identity before release. Keep the current ten-layer ceiling visible until storage, UI factories, dependency resolution and edit mappings support expansion safely.

Avoid rebuilding hidden rollouts or the entire scene when only selection styling changes. A dependency summary should explain which layer will recompute after a blocker change.

## U6 — Small, portable recipe library

First recipes: courtyard planting, ordered roadside objects, and layered vegetation with exclusion zones. Use original simple assets and let users substitute their own source meshes. Include one-page instructions, expected results, units, host/renderer requirements, and reset steps.

Future preset format: versioned data with declared units, settings, source slots, dependency references and optional thumbnails. Import validates bounds and unknown fields; it never executes arbitrary script. Missing assets prompt explicit replacement. Preset application is undoable and does not overwrite existing layers without a clear action.

**Acceptance:** export/import into a differently scaled scene produces the documented physical spacing; unresolved dependencies are reported; old preset migration is covered.

## Feature priorities

| ID | Feature / purpose | Scope and acceptance | Priority |
|---|---|---|---|
| F1 | Slope and altitude constraints | Explicit up vector/space, units, falloff, rejection semantics; default off preserves all legacy output | Next workflow enhancement after baseline |
| F2 | Selectable density map channel and resolution | Start with current UV raster model; missing UV and color-management fixtures; no promise of arbitrary 3D shader evaluation | Next if pilots need texture precision |
| F3 | Reusable rule/recipe data | Share working layer setups with safe import and asset replacement | Early beta |
| F4 | Constraint visualization | Show fit disks, exclusions, edge direction, blocked/underfilled regions on demand | Early beta |
| F5 | Stable layer/source identities | Needed for safe reorder, richer presets and dependable interop; versioned migration | Foundation before those features |
| F6 | Brush add/erase or painted masks | Define whether strokes alter procedural rules or manual instance records; deterministic replay and undo | After editing/identity qualification |
| F7 | Temporal surface attachment | Rest frame, surface face/barycentric binding, stable IDs, topology-change policy and motion samples | Separate animation milestone |
| F8 | Camera/distance display culling and LOD | Display-only first; deterministic hysteresis and picking; final render population unchanged | Measured viewport need |
| F9 | Render culling | Explicit opt-in; reflections, shadows, GI, panoramas, multiple cameras and animation tests | Later, renderer-specific |
| F10 | Group/hierarchy source support | Define nested transforms, materials, pivot and visibility; preserve hierarchy or reject unsupported input clearly | Pilot-driven |
| F11 | Field-driven controls | Optional 2027 Field Helper adapter plus portable Cyrus mask contract | Prototype after basic masks |
| F12 | USD instance export | Units, axis, identity, prototype/material paths, animation and transform representability | Studio-driven experiment |

These priorities are recommendations, not commitments to ship every row. Current source does not establish full implementations of these proposed workflows.

## Detailed rules for the first additions

**Slope/altitude:** filtering changes output counts. Choose candidate thinning versus refill deliberately; preserve original candidate identity for downstream randomness. Use surface geometric normal initially and state how mirrored surfaces are handled. A units change must not alter a physical altitude range unexpectedly. Adding a default-off filter must not consume new RNG draws in legacy scenes.

**Texture controls:** current density uses a 128×128 raster and UV channel 1. First make that limitation explicit, then add controlled choices. Treat numeric masks as data; test legacy gamma and OCIO behavior before changing sampling. Avoid calling arbitrary material/shader APIs on worker threads.

**Temporal consistency:** deterministic reseeding each frame is insufficient. A topology or triangle-order change can relocate samples even at the same seed. This feature needs a separate scene contract and must not be implied by ordinary time-change callbacks.

## Deliberately deferred ideas

A general-purpose node editor, AI scene generation, material conversion, a content marketplace, procedural plant modeling, and a new standalone application. Reconsider only when specific customer tasks and sustainable support justify them. Improve discoverability and reliability of existing depth first.
