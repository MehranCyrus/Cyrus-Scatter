# Current codebase architecture

Applies to Cyrus Scatter 0.86.8.1, saved schema 59 and `CyrusUnified2`. Use [the artist guide](ARTIST_GUIDE.md), [the backlog](BACKLOG.md) and [current qualification](plans/source-clearance/DELIVERY_08681.md). Source implementation and scoped qualification are distinct. The [0.86.0 native execution evidence](plans/native-placement/EXECUTION_0860.md), [0.85.4 memory evidence](plans/memory-0854/README.md) and earlier dated records retain their exact scope. Read relevant [foundation contracts](ENGINEERING_FOUNDATION.md) with their verification limits. Versioned sections below describe their original foundation; current formats are recipe 8, numeric settings 3, library capability 4 and asset package capability 2.

## Ownership

The [maintained foundation](ENGINEERING_FOUNDATION.md#native-foundation-and-language-boundaries) specifies native bulk computation/storage and future physics/animation constraints. The default controller now uses native placement generations throughout generation, preparation, Edit, acceptance, display and output. The private controller comparison switch is removed. MAXScript retains authored parameter blocks, bounded orchestration and UI; the managed library retains bounded catalog/image work. The [N01–N09 plan](plans/native-placement/README.md) and [execution handoff](plans/native-placement/EXECUTION_0860.md) separate current qualification from historical prototypes. The independent [Physics Lab](../CyrusPhysicsLab/README.md) remains experimental and is not integrated into Scatter.

The [0.85.2 correction](plans/preset-gallery-improvements/UI_CORRECTION_0852.md) binds the existing native nested-rollout input handler once per lazy mount and releases it on unmount. It adds no scene callback, polling or placement work. Managed library scale normalizes Max’s default zero to one and re-arranges on parent-DPI changes. Saved contracts and calculation ownership are unchanged.

The **0.85.1 delivery** extends the preceding 0.85.0 foundation with the [gallery and format-5 contracts](plans/preset-gallery-improvements/FORMAT_5.md), [bounded asset adapters](plans/preset-gallery-improvements/PACKAGE_CONTRACT.md) and [shared installer engine](plans/preset-gallery-improvements/INSTALLER_CONTRACT.md). Its native worker reads metadata/typed copied data; the managed gallery owns bounded images and no scene references. MAXScript owns captured-owner review and authored transactions. Explicit capture, revision updates and import are separate from passive browsing. See [pair-specific evidence](plans/preset-gallery-improvements/PROGRESS_0851.md); the historical sections below retain their original version scope.

| Owner | Responsibilities |
| --- | --- |
| Scatter controller | Ordered layers, setup enable, Manual/Live, global palettes, between-layer relationships, preview and output publication |
| Ordinary layer | Receiving surfaces, models, amount/seed, assignment layout, transforms, masks, spacing defaults, candidate Relax and accepted-union cleanup |
| Paint Area | Named coverage document and one explicit receiver target; shares its layer's models and population |
| Source row | Stable source identity, local alias, identification color, assignment group, weight, scale/lift, forward axis and radius settings |
| Spline Path / Band | Stable local identities, Path corner policy, Band ranges, density/curve, membership, scale multiplier and identification color |
| Source container | Saved collection-enable flag (off by default), palette boundary and cached consumer/ownership presentation; optional guarded static source movement |
| Surface Analyzer | Independently updated boundary/path/point results; Scatter consumes its published output |

The current scene model has owning layers and receiver-bound Paint Areas. Model-owning paint sets, shared-receiver inheritance, old paint adoption and stroke-history evaluation have been removed. Schema 58 and vector payload version 1 reject unsupported saved data. Schema-55/56 migration and old internal placement readers are removed. Removing a receiver preserves its inactive area; a replacement node with the same name is a different identity.

## Native storage and lifetime

The 0.86.8.1 correction compiles clearance metadata once per evaluation. All
authored policies are validated, but only protected and authorized candidate
sources select schedules and spatial bounds. Equivalent policies share bounded
witness cohorts. A previous-round blocker is provisional: ranked settlement
removes stale rejection hints and settles the same candidate prefix before
cleanup or extension. Fifty million examined settlement rows bound this work
separately from the existing neighbor-visit limit. No intermediate result is
published.

Viewport source appearance is independent of instance transforms. Weak snapshot
ownership plus exact triangle correspondence permits material/UV reuse across
radius changes without pinning retired geometry. Relevant source, map and UV
revisions invalidate appearance; consumed animated map validity advances a
shared time revision for every consumer. Unrelated material validity does not
rebake static bitmap inputs. Colored Mesh prepares supported opacity only;
Textured mesh also prepares color. Immutable GPU geometry, UV and texture
resources can be retained while changed instance transforms are uploaded.
Existing conservative memory admission, host-thread preparation, Manual guards
and atomic generation publication remain. This is scoped reuse, not a cache
of every independent component's acceptance output.

0.86.0 stores immutable placement generations as 96-byte native records, with numeric generated identities, bounded authored keys and explicit source/receiver cohorts. Flat index views share storage. High-rejection accepted views compact when the base exceeds 1 MiB and accepted record bytes are at most one eighth of the base; a retained accepted publication then need not pin the rejected pool. Candidate schedules/radii remain native. The exact eight-field representation is an explicit inspection/comparison boundary, not the internal hot-path representation. Native placement capability 2, Brush POD API 2, procedural publication capability 3, saved schema 58 and `CyrusUnified1` must match their intended boundaries. Internal class IDs remain unchanged.

Admission uses checked candidate-count arithmetic and conservative native coexistence/scratch allowances against available Windows commit, leaving a 256 MiB reserve. Bounded authored/script work retains an 8 MiB workspace guard; native Count no longer requests script heap proportional to placement rows. These are admission allowances, not exact OS allocation predictions. A light-GC checkpoint after 64 MiB of tracked native allocation churn releases unreachable wrappers; a sufficiently large Count decrease releases rollback roots before collection. Cached/passive UI never triggers these checkpoints. Required publication, Undo and render pins are not evicted. Failed successors retain the previous complete result. No full GC, Undo flush or saved heap-preference change is requested.

CS Edit separates derived candidate input from authored deltas/identities/selection. Authored rows use immutable copy-on-write blocks of 128; selection uses compact bit blocks. Identity rows remain to preserve order and dormant behavior. Undo snapshots share unchanged authored blocks, omit derived matrices and charge changed blocks rather than both complete generations. Unique tracked Edit bytes and conservative owner/history attribution are separate measurements. Structural layer commands include native Edit ownership in the same host hold. Preset publication restore moves the native frame, epoch, manifest and display together; ordinary scalar Undo still changes authored parameters and re-evaluates according to Manual/Live behavior. Save/Load retains the existing Edit field chunk.

Native publication owns accepted views, radii, source correspondence, receiver revisions and statistics. Host-thread staging validates all owners before atomic installation; the Edit transaction remains rollback-capable through the install tail. PFlow pins immutable native groups and reads per-particle transforms without a persistent script matrix array. Bake and public inspection materialize pages of at most 500 records. Those explicit queries and real baked scene nodes have separate costs. Rendering remains a host integration with bounded script dispatch, not a new native Particle Flow channel-fill implementation or asynchronous solver.

## Evaluation and publication

The generated controller prepares geometry and keyed candidates, applies supported candidate Relax, coverage/area/falloff and transforms, resolves Edit/radius information, evaluates ordered spacing and accepted-union cleanup, and stages the complete result. Candidate budget and accepted target have different bounded retry semantics. Earlier accepted owners and protected edits affect later acceptance.

Paint Areas combine coverage by maximum within their layer; a candidate is accepted at most once. Areas do not create additional population quotas. Each receiver now has a persistent UUID-salted candidate stream. Density rounds independently per receiver below its allocated cap; Fixed Total and capped Density use area/weight-based largest-remainder quotas with saved receiver-slot tie breaking. Removed quotas drop local suffixes. Reorder and rename do not reseed unchanged receivers; unlink/relink retains their identities. A same-name replacement node has a different identity.

Candidate IDs encode an append-only saved receiver slot plus local ordinal, within the owning population's namespace. A separate schedule places initial quotas before refill and protected-only suffixes; rejection does not renumber IDs. Ordinal pages in 0.81.5 preserve existing IDs and prevent ordinals above 131,071 from overlapping another receiver slot. Admission includes moved/cloned Edit requirements and stays bounded to 1,000,000 candidates per population and 1,000,000 across the root, including retry/protected requirements. Geometry face indices plus barycentric coordinates locate samples and Brush anchors; they are not persistent identities across topology changes. Orientation uses geometric face normals. No rest-pose or arbitrary-remesh correspondence is introduced.

Receiver-local row caches include generation settings, source state, receiver geometry/UV hashes, relevant spline geometry, Analyzer revisions and texture state. Adding a receiver can reuse old candidate rows, but Update still reads geometry/area for validation and runs shared acceptance/publication. This does not claim zero host geometry evaluation or incremental GPU upload. Projection and candidate Relax use the candidate's receiver; changing its own quota/neighborhood can change Relax positions. Shared masks, collision scopes, cleanup and protected edits can change which candidates survive.

Receiver-aware Edit/radius receipts compare common generation settings and known receiver geometry while allowing membership changes. Missing targets remain inactive; geometry changes are guarded. Current-schema save/reopen/copy/merge remain supported within the documented binding limits. Earlier scenes require recreation; current source never guesses a migration.

### Spline fields, provenance and radii

One prepared native field supplies ordinary Band generation, movement eligibility and inspection. Consecutive intervals reserve empty gaps and use ordered first-match ownership. Independent ranges use separately keyed occupancy, owner, source and scale choices; density is applied once. Accepted target rejects Independent/nontrivial density before publication. Rounded queries use original segments; Sharp uses bounded shared contours and a declared aggregate error budget. See [design](plans/spline-bands/DESIGN.md) for the numerical contract.

Placement records preserve the eight-field semantic contract: transform, source, candidate identity, receiver correspondence, barycentric anchor, Band owner and protection. Native storage and bounded readback preserve the precision boundaries of the [Bands transport contract](plans/spline-bands/TRANSPORT.md); its original adapter version labels remain historical. Current native publication additionally owns `(XY, 3D)` radius pairs and source/receiver metadata. Owner provenance survives transforms, Edit, spacing, cleanup, output filtering and display; it is not reconstructed from position or source color.

Auto Radius uses finite face-referenced pivot-local source bounds and each final instance basis once. Manual values remain separately saved. Each spacing relation selects its own XY/3D metric for both participants. A bounded weak-reference source cache invalidates synchronously and observes animation validity; required invalid sources reject the successor before sampling. Unsupported source families expose Manual rather than guessed bounds.

### Vector field and feedback

The native Brush stores canonical local-XY polygon contours, including holes, plus sampled density and scale curves. Clipper2 integer Boolean union/difference consumes a 96-sided circular or swept footprint. No cursor-sample/stroke history is retained as model data. The surface BVH remains responsible for nearest ray hits. Preparation rejects vertical, folded and overlapping projected faces, including disconnected stacked sheets.

A segment BVH accelerates parity membership and closest-border distance. An object-transform metric preserves projected world widths under nonuniform scale/shear. Signed distance is positive inside; the ramp spans negative outside-width to positive inside-width. Density uses its own curve, and scale interpolates its configured multipliers through its own curve. Receiver-local candidates and IDs are not regenerated when these settings change. Overlap takes maximum effective density; the strongest area controls scale, with area order breaking ties. Explicit area constraints and acceptance rules remain in the same engine pipeline.

Painting prepares a tentative canonical document. Each successful gesture publishes that document under one native Undo record; Cancel discards it. Capacity/Boolean failures retain the previous complete document. Serialization accepts only the new vector payload. The core limits 200,000 contour vertices and one million receiver faces, with 0.0001 local-unit integer precision. These are admission bounds, not whole-process peak-memory guarantees.

Painter min/max size receives twice the authored radius: Autodesk’s implementation halves Size for cursor drawing and stored stroke radii. Vector authoring continues to use the original radius. Start and in-session radius changes use the same conversion; Stop restores previous Painter settings.

Feedback prepares complete line segments lifted onto the receiving surface, or optional bounded coverage samples. A failed successor does not replace the preceding feedback. Drawing consumes cached numeric segments/points and performs no Boolean operations or field queries. Painter callbacks prepare changed feedback after a 16 ms input-processing interval and flush the final border on release. The 33 ms script timer handles idle catch-up and status/publication; it skips duplicate feedback redraws. Unchanged brush status does not rearrange the panel. These scheduling intervals and synchronous preparation timings are not presented FPS or physical cursor latency. During a held gesture normal scatter publication remains deferred. Static target validity avoids treating clock changes as geometry changes.

Publication commits compatible rows, sources, radii, statistics and display/output state as one complete epoch. Failed successors retain the prior complete publication and report the error. Pending configuration and published output can therefore legitimately differ.

0.81.3 keeps this shared epoch but permits unchanged layer snapshots to survive
a new calculation. Staging compares ordered transforms/source indices/Band owners
against the last committed owner, plus source identities, geometry signatures,
Band dictionary, display settings and the published Point Cloud sampling seed.
Radius overlays additionally compare both published radius metrics and inspection
settings. Palette replacement shares immutable snapshots. Comparisons do not
install state; existing commit/rollback retains ownership of all cache keys and
metadata. The original 0.81.3 delivery deferred tests and Max execution. The
combined 0.81.5 source now has scoped two-host retained/publication witnesses and
a nine-layer garden campaign; see the current report for exact limits rather than
treating these as exhaustive Band/renderer acceptance.

Manual edits wait for explicit Update. Passive browsing, cached inspection and unrelated animation must not publish pending recipes. Cold reconstruction of a missing initial publication is distinct from evaluating warm pending edits. Live invalidation follows relevant dependencies, including relevant animation. Mouse-held interaction can defer scheduled work.

Host geometry access, scene mutation and publication belong on the Max thread. Native workers use copied input. Point Cloud, Mesh and all three Proxy shapes use retained buffers to avoid unchanged uploads. Proxy shares Mesh's immutable source faces and instance transforms, without expanding per-instance proxy triangles in normal operation. Mesh keeps source geometry independently of draw limits. Controller-owned idle/navigating caps choose stable prefixes across visible source groups; zero removes the artist cap. Mesh groups that cannot fit their triangle share use cached boxes, and memory admission may reduce all Mesh groups to boxes. The active view/projection and a settling timer switch precomputed quotas without rebuilding snapshots or uploading unchanged buffers. GraphicsWindow emergency fallback submits at most 2,048 centre markers per cache and no source triangles. Inspection lines retain their separate bounded policy. Retained drawing uses GPU graphics, not GPU placement computation.

Each population publishes a primary Point/Mesh cache and one inspection bundle combining radius rings, field samples and clipped boundaries. It may retain up to six current-publication CPU representations: Point Cloud, Centres, Mesh and the three proxy shapes. Mode switches reuse those immutable snapshots; a new publication or scene retirement clears the representation table, which participates in display rollback. Point preparation uses a conservative controller capacity before dividing work between populations, independently of artist draw caps. Large zero-limit requests therefore sample points and report reduction instead of failing back to the previous mode. XY radii use one 24-segment ring; 3D uses three perpendicular rings. Field glyphs sample actual receiver triangles through the generation evaluator; zero density remains visible. White boundaries intersect receiver geometry at its actual elevation. Selected contribution and combined occupancy share the same field logic. Ten populations retain the existing twenty-published-cache and 1,024-group limits. Retained CPU representations, field preparation, staged copies, buffers and old/new generations consume bounded reservations; diagnostic payload counts do not measure all driver/allocator overhead.

Main geometry, identification palette and inspection keys are separate. Display-only field settings do not enter placement keys. Manual field feedback follows current relevant inputs while published plants/radii and field metadata remain frozen; labels distinguish pending feedback from the last Update. A bounded weak dependency key observes receiver/Path notifications and validity without extracting geometry during unchanged refresh. Uncached source-dependent representations verify published source revisions before consuming geometry. Failed display staging restores all cache references, keys and labels.

Steady redraw traverses cached controller/display records, without resolving layer entries, checking full recipes or walking the scene. Relevant input, membership, visibility, display, publication and scene-lifecycle events invalidate the records. A compact unique Analyzer revision watch preserves its separate update contract. Held interaction defers synchronization until release. Cold realization and relevant edits still do work.

Controller icons draw separately from the registered Scatter nodes, including new empty controllers during a held sizing gesture. They must not depend on a published placement record. Icon paths cache by size; no placement evaluation is required. Delete prunes the shared node registry, while scene restoration and Undo/Redo restore it. The [0.79.5 creation fix](Terrace_Workflow_0.79.5_2026-10-11/CREATION_FIX.md) records the regression and host evidence.

Display reconstruction resolves each current layer against `procPublishedOwners`, using that owner's published rows, sources and radii. New unpublished Manual layers have empty output; deleting/reordering layers cannot borrow another owner's snapshot. All successor previews are staged before installation. Manual dirty refresh can rebuild presentation, including Undo/Redo, but placement evaluation remains gated by explicit Update. Radius visibility is excluded from placement preparation keys.

In 0.79.5 each preview also retains a layer display key: publication epoch, owner, colors and display settings. Display refresh enters root evaluation once and prepares only changed layer snapshots. All changed snapshots stage before any installation; a failed successor preserves the complete old publication. Successful recovery clears errors on reused siblings without consuming pending Manual settings. Exact unchanged native snapshot/group/style matches share ready SDK buffer and material handles through new generation-owned render items. Failed or unrealized resources are not reused. Memory admission remains conservative; this is reuse between display publications, not incremental placement solving or color-only vertex updates inside a changed layer.

Explicit Update enters root evaluation once: that evaluation stages and installs every layer atomically. Installed previews remember their Analyzer publication revision. Scatter validates enabled Analyzer dependencies before a successor solve and preserves its last complete publication on stale-input failure. An unchanged cached read continues to consume the published guides even when the Manual Analyzer has pending edits. Analyzer stores publication freshness, linked input references, a settings/transform signature and the published time-validity interval; a drainable source-event queue invalidates the saved freshness flag. Validation, Analyze and save drain pending geometry notifications; delayed notification still schedules Live work after mouse release. Parameter replay during scene loading/merging must not overwrite the saved flag. Older guides without a freshness record require explicit Analyze.

## Cached feedback

The 0.86.6.2 custom Mesh display remains identification-only: Model/Layer/Bands
colors are shaded by `mesh_display.inc`, with alpha 1. `PreviewGeometry` retains
positions/instances, not material UV or texture descriptors. The original-material
and opacity-aware viewport requested in B34 therefore requires a native display
extension, not a color-dropdown rename or another material conversion. Keep its
future material/UV/texture invalidation separate from unchanged placements and
existing geometry reuse. [Current source findings and implementation boundaries](plans/preset-gallery-improvements/INDIVIDUAL_LIBRARY_08662_HANDOFF.md#5-b34-original-material-textures-and-cutout-opacity-in-mesh-preview)
describe requested behavior, not an implemented feature.

The 0.81.8 presentation reads existing owner/result snapshots. A completed
calculation epoch distinguishes a result from an empty preview staged for a new
Manual layer. The cached dirty flag is labelled Marked for Update; the passive
reader does not compute input hashes. Named-owner feedback distinguishes accepted
placements from representation-specific prepared counts. Generated page binding
releases every component event guard after the successful parent bind. The main
status callback only relayouts Statistics when its displayed text changes. See
[Phase 1 evidence](plans/eleven-phase-roadmap/P01.md) for runtime results and the
remaining visual acceptance.

## Panel lifecycle and diagnostics (0.82.6)

The full Scatter editor uses twelve lightweight native slots. Each section creates
its controls on first opening and retains them while Max keeps the Modify panel
mounted. Rebinding changes the explicit setup/layer owner; it does not apply
pending Manual edits. Unmounting ends that control lifetime. Unchanged list rows
and managed styling are retained; wrapped text measurements are cached by
control, text and width. Layout converts logical control coordinates to physical
rollout heights and uses the visible slot width to avoid clipping.

The opt-in recorder adds 15 bounded inclusive stage totals and edit action IDs.
Disabled timers avoid clocks, allocations and locks; recording-generation tokens
reject completions from older sessions. Cached status export does not evaluate
geometry or placements. Timing totals are nested scopes, not additive wall time
or presented FPS. See the [0.82.6 handoff](plans/panel-performance-0826/PROGRESS.md)
for exact sources, measured improvement and remaining physical-display limits.

## Source map

Source rectangles in 0.81.5 instantiate only their compact properties rollout.
The controller owns the full Scatter editor. Presentation-only label updates do
not recapture movement hierarchies; full ownership reconciliation still validates
movement inputs. Point preparation validates all placement rows but copies only
the bounded displayed samples into its immutable snapshot.

The Particle Flow bridge freezes evaluated source geometry before normalizing
its node frame, matching pivot-local native preview and instance output. It
reuses one transient prototype per distinct source and preserves original source
objects. Proxy geometry is resolved before snapshotting. This corrects the extra
source-node scaling previously applied by Shape Instance; third-party geometry
and renderer coverage retain their explicit acceptance limits.

| Area | Maintained source |
| --- | --- |
| Controller, ownership, scheduling, publication, render bridge | [unified-core.ms](../AminScatter/tools/ui/templates/unified-core.ms) |
| UI generation and shared layouts | [generate.cjs](../AminScatter/tools/ui/generate.cjs), [approved-layout.cjs](../AminScatter/tools/ui/approved-layout.cjs), [approved-layout-rows.cjs](../AminScatter/tools/ui/approved-layout-rows.cjs) |
| Lazy panel lifetime and scaling | [lazy-pages.cjs](../AminScatter/tools/ui/lazy-pages.cjs), [approved-main-ui.ms](../AminScatter/tools/ui/templates/approved-main-ui.ms), [colored-lists.cjs](../AminScatter/tools/ui/colored-lists.cjs), [rollout_flow.cpp](../AminScatter/src/rollout_flow.cpp) |
| Bounded stage diagnostics | [diagnostics.h](../AminScatter/include/diagnostics.h), [diagnostics.cpp](../AminScatter/src/diagnostics.cpp), [diagnostics_bridge.cpp](../AminScatter/src/diagnostics_bridge.cpp) |
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

## Distance storage and publication failures

Schema 57 stores source radii/Z offsets, Band ranges, edge distances, six movement bounds and pair gaps in typed world-unit fields. Area falloff flags/curves retain their current string format, but widths live in three aligned world-unit tabs. Per-instance absolute radii have a distance tab; multipliers stay dimensionless. Obsolete untyped parameters and schema update handlers are removed. Native Paint/Edit geometry bindings remain guarded under rescale; see [F10 and F11](ENGINEERING_FOUNDATION.md).

The script stages preview input timestamps/Analyzer revisions and retains complete root/leaf publication snapshots until the native Edit transaction commits. A failed install restores every owner and cache, then rolls back native Edit maps. Post-commit observers are guarded separately. Native PointDisplay prepares a successor generation and CPU point/mesh items while the old generation is alive; it disables and swaps the old ownership only after staging succeeds. Admission includes temporary coexistence. This is bounded CPU publication recovery, not blanket GPU/device-loss atomicity; see [the tested failure sites](Foundation_0.79.6_2026-10-12/README.md).

## Independent boundaries

MCP 0.73/Plan 0.73 is a restricted authoring subset, not access to every local control. Full Brush/container/Edit authoring and render jobs remain unavailable. The offline Design Lab is experimental and grants no host authority. Licensing is independent of scene ownership. Scatter 0.79/0.79.1 team candidates enable owner-issued 30-day licenses; saved-scene rendering remains available after expiry. The foundation is default-off in builds that do not opt into team licensing. See the component guides for those contracts; do not infer new capabilities from historical plans.

### Point row identity (0.79.1)

`sourceRowIDs` identify source rows independently of scene nodes. Visual names/colors and explicit Band selections use these identities, including Point and Empty rows. Duplicate node-based Band membership storage has been removed. Source removal preserves dormant Band memberships for Undo; Point replacement keeps the row ID. Layer copy includes independent Band arrays, Path references and display settings. Containers admit Point/Empty rows independently of spatial membership; real source nodes retain their collection policy. Source-row IDs, receiver/candidate identities and published native source correspondence are distinct namespaces.

Band scale profiles add authored per-Band mode, sampled Custom trace and graph
handles. Stable Band IDs govern editor writes across reorder/copy/view changes.
All three arrays participate in copy/remove/reorder/current-schema validation;
numeric mode/samples enter preparation and publication keys, while graph-only
metadata does not. The host resolves Off/Follow Density/Custom into one effective
trace in the 15-field Band record (native interface 9). The immutable numeric field
validates it and multiplies the separately keyed random scale after selecting its
owner. Published transform/radius computation therefore consumes the factor once.

## Static authored recipes (0.82.5)

`recipes.cpp` implements a separate bounded, closed, data-only format (version 1); `recipe_fields.inc` accounts for 228 typed controller settings, while topology/identity/Paint/relationship fields have explicit handling. `recipes_bridge.cpp` validates JSON and exposes transport trees; `recipes.ms` captures authored state, proposes external bindings and stages fresh owners inside one native Undo hold. Complete save rejects unsupported Edit/radius overrides or nonstatic parameter controllers. No placement arrays, host handles or executable MAXScript are serialized.

Canonical native Paint bytes are immutable sidecars with SHA-256/size checks. Brush export does not poll, prepare or commit; bound import validates system units, frame and geometry before commit. Orphan coverage retains exact bytes and a known frame, including an additive native scene chunk; unknown old frames are not invented. Import preserves Manual publication, delegates Live to existing invalidation/publication and disables imported field overlays. New-file saves publish attachments before the manifest; relative reads must remain within the package directory. The 0.82.6.1 browser uses a separate bounded file-only worker, 10,000-entry/estimated 32-MiB metadata index, 128-entry pages and explicit refresh with content hashing. Search uses copied indexed metadata; thumbnail decoding is limited to the selected entry and disposed on change/close. Optional presentation sidecars bind to the authored manifest SHA without changing recipe format 1. Max shutdown cancels and joins the worker before module unload. See the [library contract](plans/improvement-program/LIBRARY.md) and [scoped qualification](plans/improvement-program/I03_08261.md). This is not scene-asset packaging or a new MCP write API. See [the qualification/limits](plans/recipes-0825/PROGRESS.md).

## Orientation stage (0.83.0)

Canonical receiver candidates retain random local transforms and an immutable copied geometric-normal snapshot from the same evaluated mesh read. A separate orientation stage applies Random, World direction or target-pivot heading after movement/Relax/Paint and before source transforms/Edit/final radii/acceptance. Direction and angular normal edits reuse candidates and normals. Exact numeric keys preserve small representable vector changes; target validity uses transform/controller data without evaluating target shape. Active target/ancestor notifications rearm transform validity even if the current pivot is unchanged, allowing newly authored animation without needless current-frame work. Orientation timestamps participate in stage/install/rollback; scene retirement releases retained snapshots. Recipe/settings format 2 and the appended schema-58 parameter block are specified in [the I04 contract](plans/improvement-program/I04_ORIENTATION.md) and [wire-format successor](plans/improvement-program/FORMAT_2.md).

## Variation domains (0.84.0)

Receiver correspondence and receiver randomness are now distinct. The appended schema-58 `variationSettings` block stores `procReceiverVariationIDs`; an empty scene array resolves to existing receiver IDs, preserving preceding output. Copy/import remap correspondence and independently retain or regenerate variation. Sampler, mesh-density and slope/altitude stochastic filters consume the same effective domain. Cache keys invalidate only affected receivers; nondefault domains enter the receiver binding value, so stale authored overrides fail while default bindings retain their exact preceding representation. See [format 3](plans/improvement-program/FORMAT_3.md) and [qualification](plans/improvement-program/I05_0840.md). Native Paint remains receiver-bound. Numeric settings format stays 2. B26 tracks observed heavy MAXScript heap growth clearing Undo; this delivery does not close the allocation problem.

## Regular placement generators (0.85.0)

Layer-owned grid settings append a schema-58 block. A bounded world-XY lattice projects onto the highest hit of each evaluated receiver through a copied-data triangle hierarchy. The immutable GC-owned snapshot holds geometry and anchored candidates without node pointers. Existing assignment, transformation, Paint, mask, orientation, Edit and final-spacing stages consume those anchors. New positive 64-bit cell IDs are disjoint from unchanged random ordinals; every receiver transport/filter/orientation/Edit consumer preserves their full local key. Signed lattice coordinates keep common identities independent of the receiver bounds.

Snapshot keys use evaluated geometry, exact grid settings, required UV mapping, seed and receiver variation. Root admission counts enumerated cells, including holes, across all layers. Invalid successors retain prior publication. Inactive grid settings in Surface random and inactive Count/Density/refill settings in grids do not expire candidate validity. Recipe/numeric formats are now 4/3; see [format 4](plans/improvement-program/FORMAT_4.md). Limits, measured geometry extraction, collection behavior and still-open I09/I10/I11 work are documented in [I06](plans/improvement-program/I06_0850.md).

## Ready preset loading

The separate 0.86.6.2 **individual model** catalog is not a Ready recipe. It
describes 96 prepared single-source MAX files and rendered JPEGs. The managed
gallery reads bounded metadata/preview files; explicit Merge/Add verifies and
imports only the selected model. A verified external Content payload installs
alongside the versioned runtime. B33 records artist-observed automatic thumbnail
progress stalling until selection; the selected-first worker queue, UI completion
pump and visibility calculations need a causal reproduction. The prior 12-visible-
preview check did not qualify large-window scrolling. See the
[full handoff](plans/preset-gallery-improvements/INDIVIDUAL_LIBRARY_08662_HANDOFF.md).

The 0.86.2 loader uses `preset-loading.ms` over the recipes/assets templates. Browsing remains metadata/image work only. Explicit Load captures one selected terrain and an unambiguous destination, validates required numeric/UV channels, Paint compatibility, frames, assets and paths, then stages supported models/materials/paths and adds layers in one authored hold. A new setup is created only when required. Existing layers and Manual/Live mode remain. First calculation and display preparation run inside that hold; failure rolls back staged content and retains the preceding complete publication/history. A native publication restorer retains immutable generations for one Undo/Redo without package reads or solves. Post-Undo presentation restores display from the complete publication.

Ready Save captures exact role references, supported assets, evaluated receiver/static spline context, image bytes/mapping/frame/provenance and complete Paint in a content-bound data package. It does not save arbitrary scene scripts, modifier producers or procedural graphs. A compatible projected 2D map can be explicitly baked into a linear 16-bit PNG scalar snapshot; receiver-aware maps reject context-free baking. Local image frames rebase against the destination setup without moving existing layers. In the 0.86.5 reliability baseline (original receipts labeled 0.87.0), complete terrain presets fit Paint contours and spline positions between referenced local-XY footprints. Physical distances convert units, original Paint remains immutable and unsupported folded/stacked projection rejects before scene mutation. Exact settings-only Paint retains geometry/frame/unit guards. See [format 7](plans/preset-gallery-improvements/FORMAT_7.md).

## Density fields and mask visualization (0.86.2)

The 0.86.5 reliability baseline (originally labeled 0.87.0) adds synchronous host-thread receiver-map contexts owning
evaluated TriObjects through RAII. Graphs are limited to 64 maps/32 levels and
32 million node-samples; each call admits at most one million samples. Retained
mesh arrays, including unused channels, share a 256 MiB operation/overlay budget.
Host texture caches and SDK internal allocations are outside this accounting.
Filtering may additionally allocate a 4-byte index per admitted candidate while
the old complete publication remains live. Contexts do not retain SDK pointers
after the call. Placement and overlay share the same scalar evaluator. Surface
density capability 2 adds referenced-vertex relative local elevation; empty
sources short-circuit receiver work and publish valid empty native views.

Layer-owned image/pattern and numeric mesh-channel masks are independent. Max evaluates/copies host data on its thread. Native C++ owns the immutable scalar tile, bilinear Repeat/Clamp sampler, placement-sized application and copied overlay triangles. World XY and Scatter local XY use physical distances; advanced receiver UV mode explicitly requires UVs. Invert precedes response. Placement and Relax use the same sampler. Relevant settings/map/time validity changes prepare a bounded tile; Count-only changes reuse it.

Transient mask visibility and captured owner are separate from cached data. Relevant edits coalesce through a one-shot timer, stopped when settled/hidden. Manual fields can update without publishing plants. Same-owner failure retains a marked stale field; owner-switch failure cannot display another owner's field. Redraw submits copied cached vertices through immediate Max graphics calls, without host sampling, placement solves or unchanged Scatter instance uploads. Detail, receiver/Paint/query work and payloads are bounded; this is not a retained GPU overlay. Exact performance/lifecycle limits and the three bundled starter patterns are recorded in [the delivery report](plans/preset-gallery-improvements/DELIVERY_0862.md). The later UI follow-up supersedes the initial QA-only pattern decision.


## Surface Paint — 0.86.6

`brush_atlas.cpp` owns copied topology, full transformed metric and geodesic work.
The existing terrain codec remains unchanged. An additive payload discriminator
stores sparse per-face barycentric vector contours/full-face markers; geometry
identity prevents silent remeshing. Paint/Erase uses bounded native polygon
Booleans; no persistent stroke history or raster replaces the vector model.
Feather sources derive from canonical borders with internal face edges removed.
Derived atlases/fields are reused across idle redraws and invalidated on relevant
geometry/transform/coverage changes. Native reservations retain OS commit headroom;
failed successors retain preceding coverage and publication. Curved spline
snapshots carry exact coverage guarded by knot/frame/receiver identity; edited
curves reconstruct coverage on the surface. Complete curved preset transfer uses
matching indexed topology and physical-unit conversion. See the delivery report
for measured scope, approximation limits and explicit unsupported geometry.

## Source clearance (0.86.8)

`source_clearance.cpp` consumes copied native samples with validated source ordinals and sparse authored policies. The bridge verifies correspondence against the immutable source cohort; authored row UUIDs and native correspondence IDs remain distinct. Policies inherit independently for own copies, other models in the layer and other layers. Effective rules determine component scheduling, so equivalent explicit/default settings preserve inherited cleanup/order behavior.

Changed components use candidate-order Count admission followed by protected/preferred/layer/candidate conflict ordering, XY and 3D spatial indexes, union cleanup and bounded replay. Only accepted placements reserve space. Missing target UUIDs are inactive. Limits remain ten populations, one million prepared candidates, sixteen rounds and fifty million neighbor visits; policies allow 512 active source rows per population. Native admission adds a conservative 384 bytes per candidate for solver coexistence. No host calls or placement-sized script arrays are introduced.

The first delivery conservatively settles the complete setup after a changed calculation key. Candidate preparation is reused for policy-only edits; disconnected output remains deterministic. It does not cache compiled components or guarantee zero acceptance work for unrelated layers. Equivalent keys avoid calculation during browsing and unrelated animation. No new worker scheduler or asynchronous cancellation contract is introduced.

Schema 59 appends one authored parameter block. Sparse rows are keyed by source UUID, copied/imported identities remap together, and recipes use format 8. Schema 58 requires an explicit Undoable upgrade. Publication capability 4 extends the bounded bridge payload with source policies; native placement capability stays 2. Failed successors retain the preceding full publication. MAXScript owns authoring/UI and bounded orchestration; C++ owns matching, acceptance and work-sized memory.
