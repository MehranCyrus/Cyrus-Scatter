# Phase specifications

Read with [the roadmap](README.md), [validation](VALIDATION.md) and
[the current checklist](TODO.md). These are chosen initial implementation scopes;
record any material refinement before coding that phase. Existing contracts
F01–F12 remain required. Every phase includes documentation, appropriate current
schema save/copy/merge/Undo handling and its relevant regression checks.

## P01 — Workflow, ownership and feedback

**Artist outcome:** understand which layer is being edited, whether its displayed
plants are current, why the result is empty/reduced, and which action is needed.

**Baseline:** generated approved panels, tooltips, cached statistics, layer status,
Manual/Live controls and compact rectangle properties already exist. Some old
workflow text remains in the controller template but is hidden by the approved
layout. Do not restore large explanatory paragraphs to the main panels.

**Implementation sequence**

1. Audit actual generated panel labels, tooltips and callbacks against layer-owned
   models/population and receiver-bound Paint Areas. Correct retired paint-set
   explanations and ambiguous preview-count/rejection terminology.
2. Make Statistics/Help identify its selected layer and state: not calculated,
   cached, pending, disabled/hidden, empty or failed with prior result retained.
   Show the appropriate next action without guessing the cause of an empty result.
3. Distinguish last-calculation requested/eligible/accepted numbers from preview
   samples and source representation; do not label point samples as plant counts
   or cached samples as measured currently drawn geometry.
4. Reuse passive cached readers. Owner switching, help, statistics refresh and
   display feedback must not call generation, source preparation or upload.
5. Profile opening the full controller and warm status/layer navigation. Fix a
   demonstrated redundant read/rebuild if found; record cold cost separately.

**Source areas:** `AminScatter/tools/ui/templates/unified-core.ms`, approved UI
template/rows, `container-system.cjs`, control tooltips and generated inventories.
Relevant functions include `CyrusUILayerState`, `uiLayerStats`, `cacheSnapshot`,
`procStatistics` and the statistics/help binding handlers.

**Acceptance:** actual generated UI shows truthful feedback for empty, populated,
pending Manual, disabled, hidden, Point, Point Cloud, Mesh, failed successor and
owner-switch cases. Repeated cached reads leave full placements, publication,
preparation and upload counters unchanged. Existing layout remains usable at the
tested panel width; physical/DPI coverage is recorded accurately. F01/F04/F05/F08.

## P02 — Named settings and curve presets

The [source/format preflight](P02_PREFLIGHT.md) records current ownership,
unit/curve constraints and unresolved implementation decisions. It is planning
evidence; P01 acceptance and its verified push still precede P02 implementation.

**Artist outcome:** save and apply a named set of reusable settings without
retyping values or accidentally replacing receivers and source assets.

**Scope:** explicit categories for population, transforms, spacing and sampled
falloff curves. Full multi-layer recipes and asset substitution belong to P10.

1. Define a small versioned data format with typed physical units, category,
   display name and validated numeric data. Serialize data, never executable
   MAXScript. Curve samples and editable graph handles have explicit roles.
2. Capture supported authored settings through an allowlist. Do not serialize
   transient publication/preview caches, node handles, credentials or UI objects.
3. Apply a selected category as one validated Undo operation. Validate all fields
   before changing the owner. Remap distances/density using existing unit rules.
4. Provide Save, Apply, Rename and Delete in a small preset list. File writes use
   a bounded format and atomic replacement; only explicit user actions overwrite.
5. Trigger one appropriate invalidation after applying; Manual remains pending,
   Live follows the existing scheduling policy. Opening the list is passive.

**Source areas:** controller authored parameter/copy paths, curve editor,
generator UI; a focused serializer module is justified only by the format.

**Acceptance:** equivalent capture/apply after unit conversion; valid curves round
trip; corrupt, oversized, unsupported or incomplete files make no partial change;
missing/unwritable storage reports an actionable error; Undo restores the exact
prior settings; browsing adds no solves. F01/F04/F05/F06/F10/F11.

## P03 — Slope and altitude filters

**Artist outcome:** vegetation avoids unsuitable slopes/elevations with a smooth
transition, while other layouts and spacing continue to work.

**Chosen starting behavior:** disabled by default; slope measured from world up
against the receiver's geometric normal, with the supported 0–180 degree range
and underside behavior exposed explicitly. Altitude is world Z in scene units.
Independent lower/upper transition widths soften the allowed interval. Validate
crossed ranges and transition overlap rather than silently guessing settings.

1. Freeze exact endpoint/transition functions with analytic examples. A value
   outside an unsoftened allowed interval has zero eligibility; a hard boundary
   has a specified inclusive endpoint. Record how overlapping fades combine.
2. Reuse evaluated receiver positions/normals. Apply to candidate eligibility at
   the appropriate post-Relax/reprojection point; preserve the established Edit
   policy. Do not make normal alignment the filter itself.
3. Multiply the new eligibility factor with existing applicable density factors,
   preserving the existing max/union policy among overlapping Paint Areas. Use
   an independent random channel and do not reroll positions or source choices.
4. Include filter settings and relevant receiver transforms/geometry in keys.
   Hidden/disabled UI controls do not mutate settings. Add bounded rejection
   diagnostics without changing the existing meaning of accepted-target retries.
5. Add clear controls and representative slope/elevation examples to the guide.

**Source areas:** `scatter.h`, receiver/native bridge, candidate/eligibility path,
`procedural.cpp`, controller keys/parameters and generated UI.

**Acceptance:** flat/inclined/vertical/underside fixtures; transformed receivers;
hard and soft edges; min=max and invalid ranges; unit conversion; combination
with Paint, Bands, Texture Density, protected Edit, cleanup and bounded refill;
unchanged results with filters disabled; cache/Manual/Live/save/Undo checks.
F02/F03/F04/F05/F06/F09/F10/F11.

## P04 — Density mapping controls

**Artist outcome:** choose the receiver's intended UV channel and enough sampled
map detail for the scene with a clear quality/cost tradeoff.

**Baseline:** controller `renderMap` uses 128×128; native density validation accepts
square grids 2..512; `meshOf` reads channel 1. Preserve current defaults.

1. Add a saved UV-channel selector and bounded resolution choices initially
   64/128/256/512. Confirm actual supported Max channel ranges from the SDK.
2. Transport the selected channel explicitly through receiver reading; validate
   map vertices/faces and report the particular invalid receiver/channel.
3. Replace hardcoded bake dimensions. Share a bake only when map identity,
   evaluation validity/time, resolution and sampling semantics match.
4. Specify addressing, interpolation and grayscale/color-space interpretation
   before changing existing results. Keep the existing behavior as the default.
5. Separate map-bake keys from receiver geometry/UV keys. Material/UV edits that
   matter invalidate; unrelated scene animation and UI selection do not.

**Acceptance:** two UV channels deliberately producing different patterns; no UV,
partially invalid UVs and deleted maps; each resolution including tiny features;
animated maps only rebuild on relevant time changes; Manual preserves old plants;
filter/Band/Paint interactions; peak bake/preparation memory and cold/warm cost.
F02/F04/F05/F06/F07/F09/F11. Higher resolution is not a speed promise.

## P05 — Paint/spline conversion

**Artist outcome:** take an authored Paint Area into Max spline editing, then
apply a valid edited boundary back to a selected receiver-bound Paint Area.

1. Export current canonical vector outer contours and holes with the correct
   receiver-local-to-world transform. Name outputs clearly and select them.
   Export is a snapshot; keep the source Paint Area intact.
2. Import closed spline contours through the existing vector normalization path.
   Define fill/nesting, sampling tolerance, self-intersection policy and limits.
   Reject unsupported projection/non-finite geometry before replacing anything.
3. Offer explicit Replace or Add-to-area import behavior; preserve the area's
   identity and unrelated settings. Keep source splines intact. No implicit live
   link or stroke-history reconstruction is introduced.
4. One Undo per conversion command. Live/Manual follow existing area-edit rules.
   Imported curves become canonical vector coverage; display remains cached.

**Acceptance:** circles/polylines, concavity, holes/islands, multiple loops,
mirrored/nonuniform receiver transforms, scene units, tiny/huge inputs, malformed
and excessive geometry. Export/import coverage agrees within the declared
tolerance. Source ownership, Undo, save/reopen and failure retention remain correct.
F01/F04/F05/F06/F09/F10/F11. General curved-surface painting is outside this phase.

## P06 — Regular planting grids

**Artist outcome:** control row/column spacing, staggering, orientation, offset
and bounded jitter for rectangular, running and hexagonal arrangements.

1. Specify a world-unit layout frame/origin and receiver projection behavior.
   Keep grid origin independent of the current include-boundary bounding box so
   moving one border does not slide the entire orchard.
2. Specify identity as owner/receiver/layout mode plus lattice cell. Prove a
   collision-free bounded representation in the current candidate identity
   transport; do not hash cells into IDs without collision handling. If a new
   identity/schema contract is needed, record it before coding.
3. Generate bounded candidate ranges through the existing receiver plan and
   acceptance pipeline. Define which projected hit is used for stacked surfaces.
4. Apply deterministic cell-keyed jitter and the existing source/transform/
   spacing systems. Document that spacing can remove grid points.
5. Make explicit spacing authoritative; disable incompatible Count/Density
   controls rather than letting two controls silently fight. Resource/candidate
   limits still bound enumeration; explain truncation/failure.

**Acceptance:** analytic cell positions/counts; staggering/hex parity; spacing in
different units; border expansion preserving surviving cell IDs; translated
origins; jitter stability; steep/curved/multiple receivers; Paint/Bands/filters,
spacing, Points/Empty and quotas. F01/F02/F03/F05/F06/F09/F10/F11.

## P07 — Orientation controls

**Artist outcome:** face an explicit direction or target, with predictable surface
alignment and retained random variation.

1. Define orientation modes and order: receiver alignment/base direction,
   source forward-axis correction, then documented random/local rotations.
2. Implement fixed world direction and Look At target with a specified up/roll
   rule. Handle coincident target, zero direction and parallel-up degeneracies.
3. Recompute final source bounds/radius from the resulting basis before spacing.
   Rotation of tilted or nonuniform models can alter XY and 3D clearance.
4. Track only the chosen target's relevant changes. Manual keeps the published
   basis/radii; Live follows a relevant animated target.
5. Persist modes/references and preserve meaningful defaults when disabled.

**Acceptance:** known axes, targets above/below/on the plant, mirrored sources,
surface alignment and random rotation order, final-radius collision checks,
target deletion, relevant/unrelated animation and save/copy/merge/Undo.
F02/F03/F04/F05/F09/F10/F11.

## P08 — Paths, sequences and references

**Artist outcome:** evenly spaced trees/lamps along open or closed splines,
repeating named source sequences, and exact placement on reference markers.

1. Add a true path generator using bounded arc-length sampling, spacing, starting
   offset and optional along-path jitter. Define closed-seam and endpoint policy.
2. Follow path tangents with P07's robust orientation handling. Keep direct
   3D-path placement versus projection onto a receiver explicit.
3. Define path/subcurve/station identity under edits. Source sequences reference
   persistent source-row IDs, not visible row indexes. Define whether a rejected
   station consumes its sequence entry; default is yes, so later stations do not
   reshuffle when an earlier station is excluded.
4. Add reference-node pivot placement first. Optional face/vertex references are
   a separate bounded extension only if required for this phase's chosen scope.
   Use explicit source assignment rather than fragile name matching by default.
5. Connect the resulting candidates to existing eligibility, transforms, protected
   Edit, spacing and complete publication. Preserve their provenance in diagnostics.

**Acceptance:** lines, arcs, closed loops, multiple subcurves, sharp corners,
zero-length segments, nonuniform transforms, sequence gaps/replacement/Undo,
deleted/animated references and receiver projection; no seam duplicates; compare
arc positions against an independent high-accuracy oracle. Measure long-path
preparation and cache reuse. F01–F07/F09–F11.

## P09 — Transform maps and model assignment maps

**Artist outcome:** drive size/rotation and plant-type regions with maps while
retaining predictable collision and source selection.

1. Extend P04's map sampling contract to scalar scale and rotation channels.
   Specify remapping ranges, neutral values and Replace/Multiply/Add meanings
   separately. A missing required map is an actionable failure, not an implicit
   black/white value that destroys the previous output.
2. Add color-to-source/group assignment. Freeze color space, nearest-color or
   categorical sampling, tolerance, unmatched-color behavior and deterministic
   ties by persistent row identity. Keep identification colors distinct from
   material/render tint; this phase does not add renderer shading plugins.
3. Define how a map selects among Random Mix/Clusters/Band-eligible source sets.
   Choose one explicit assignment authority per layer initially; do not silently
   combine competing owners. Preserve each Band's existing membership rules.
4. Apply final scale/rotation before bounds and spacing. Maps must not reroll
   candidate positions. Share immutable baked data only when all keys agree.
5. Include animated-map validity, source-row membership and remap settings in
   dependencies; retain bounded preparation and atomic failure behavior.

**Acceptance:** analytic constant/ramp/checker/color maps, exact/near/tied colors,
zero weights, empty eligible subsets, Model/Point/Empty distinctions, missing
sources, mirrored/nonuniform scale, final-radius collisions, every active layout,
Manual/Live animation and map cache/memory measurements. F01–F11 as applicable.

## P10 — Planting recipes and browser

**Artist outcome:** save and reuse a complete layer or multi-layer planting setup,
substitute the artist's own models and understand any unresolved dependencies.

1. Build on P02's validated format. Describe authored layers, relationships,
   Bands, filters, map settings and stable role IDs separately from scene nodes.
2. Add roles such as canopy/shrub/groundcover and explicit receiver/path/map/
   source binding. Applying a recipe creates new identities and deliberately
   remaps all internal references. Do not copy runtime candidate/cache identities.
3. Resolve required assets before commit. Provide a preview of bindings and
   unresolved roles. No silent substitution of a same-named scene object.
4. Provide a small searchable local browser with names, descriptions, tags and
   optional bounded thumbnails. Keep bulk models/textures external to the plugin.
5. Apply as one transaction/Undo. Preserve the current scene if validation or
   asset binding fails. Loading metadata/browser previews does not solve plants.
6. Supply a few recipes using clearly identified demo/simple assets and document
   how artists replace them. Do not bundle third-party libraries by assumption.

**Acceptance:** single/multi-layer round trips, role replacement, duplicate names,
cross-scene units, collisions/Band memberships after ID remap, broken paths/maps,
unsupported format, excessive file sizes, cancelled apply, undo/redo, storage
failures and browser responsiveness with many entries. F01/F03–F06/F10/F11.

## P11 — Adaptive viewport completion

**Artist outcome:** predictable interaction with dense/heavy planting and clear
feedback about the displayed representation, while the accepted result stays
unchanged.

1. Re-audit the existing 0.81.6/0.81.7 idle/navigation budgets, stable draw prefixes,
   oversized-source boxes, zero-limit point sampling and mode cache reuse.
   Preserve the original failure witnesses and their correction tests.
2. Benchmark scenes produced by P03–P10 and mixed heavy source families. Measure
   cold source preparation, first display, warm edits, navigation, mode switches,
   upload volume, active/retained/peak memory and whole-scene baseline separately.
3. Improve the highest measured bottleneck within current ownership and renderer
   contracts. Consider indexed source geometry or better deterministic quota
   allocation only after a measured comparison demonstrates value.
4. Make preview fallback/sample status understandable; point samples, centres,
   box instances and full meshes have distinct units. A zero artist draw cap
   still respects resource admission. Existing budgets remain configurable.
5. Validate prolonged transitions, relevant source changes, failure/recovery and
   global resource contention. Avoid global garbage collection as a normal fix.
6. Qualify Max 2026 with compatible assets; do not hide the existing missing-class
   terrace limitation by silently substituting geometry. Record physical and
   presented-FPS evidence separately from scripted redraw timings.

**Acceptance:** all new features retain IDs/full transforms and output selection
across preview changes; static navigation/status reads cause no solves/uploads;
cache resources stabilize across repeated cycles; failures keep the last complete
view; renderer output agrees with the accepted publication. All required phase
regressions pass on the final frozen source. F02/F04–F08/F11.

Geometry LOD, automatic render-camera clipping, GPU placement calculation and a
general async/incremental solver are not required to finish this phase. They need
separate cost/behavior evidence. Camera clipping can change shadows/reflections;
viewport culling must not silently change renderer output.
