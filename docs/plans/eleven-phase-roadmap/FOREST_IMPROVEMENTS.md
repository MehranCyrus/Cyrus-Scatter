# Forest-informed Cyrus improvement plan

**Execution update, 16 October 2026:** I01/I02 were delivered in 0.82.6.
The [active user goal](../improvement-program/OBJECTIVE.md) authorizes I03–I18
and resumes P06. I03 is implemented and scoped-tested as [0.82.6.1](../improvement-program/I03_08261.md); see the [current ledger](../improvement-program/PROGRESS.md).
The plan's original pause and authorization statements below remain historical
context, not the active execution boundary.

15 October 2026. **Original plan; I01/I02 subsequently implemented as 0.82.6. Phase 6 remains paused.** See the [implementation and scoped qualification](../panel-performance-0826/PROGRESS.md); I03 onward remain planning only. No implementation, Max testing, build, version change, installation or Git publication is authorized by this document. The user requested a detailed comparison-based plan, ordered from easiest to hardest, with performance and testing for every step.

This is a research supplement to the [existing eleven-phase roadmap](README.md), not a replacement execution program. Its **I01–I18 identifiers are difficulty ranks**, not product phases or versions. The existing [TODO](TODO.md) remains the phase execution ledger; [BACKLOG](../../BACKLOG.md) remains the defect/acceptance ledger. The step specifications below preserve the original proposal. **I01/I02 are now implemented in 0.82.6; I03-I18 remain proposed.** Starting one later requires an implementation scope; listing P06 here does not resume it.

## Original planning baseline and evidence

- Cyrus: **0.82.5 / scene schema 58 / CyrusUnified1**, recipe format/capability 1. Branch `codex/workflow-0.75`, HEAD `a4af303b0902886e975c96b6900f047f37198a92`. The [recipe handoff](../recipes-0825/PROGRESS.md) and [implemented format](../recipes-0825/FORMAT.md) describe the current delivery and its limits.
- Forest research: sibling project `F:/Cursor/_Cyrus_Apps/Forest Reverse`, pinned **Forest Pack Lite 9.4.3, native 9,4,3,766, Max 2027**. Its eight analysis ledgers contain 310 distinct selected function entries across the core and Qt companions. This is examination scope, not a completeness percentage or proof of Pro behavior.
- The library continuation's final validation receipt now exists. Its 79 documents and 54 scripts were rehashed for this planning task: **133/133 matched**. This closes the missing-receipt observation in the preceding review. The receipt records offline evidence checks and SDK compilation, not a live vendor preset round trip.
- Current Cyrus source was inspected directly in the preceding comparison and rechecked at the same HEAD for this plan. Important boundaries are linked below. Knowledge generation `44bb57523e1286764c655754ce79ed3e4299bce12c0c71b7c49b212258dfa0d3` is stale: full verification found 15/38 enrolled parents current, and F08 retrieval rejected changed evidence. No index refresh was performed.
- Pre-existing work was preserved: the landscape-presentation change in `docs/README.md`, plus untracked artwork, landing references, presentation work and website prototypes. Historical test results remain historical; no new host/performance results are claimed here.

Evidence labels used below: **native trace** means inspected vendor instructions/call paths; **documented** means a public feature described in the research; **proposal** means a Cyrus design decision. Neither a native trace nor a mathematical witness establishes runtime performance or every host lifecycle consequence.

## What we already have and should retain

| Current Cyrus capability | Source/evidence | Implication for this plan |
| --- | --- | --- |
| Ordered layers; receiver-bound vector Paint Areas; overlap uses maximum coverage within one population | [Controller template](../../../AminScatter/tools/ui/templates/unified-core.ms), [ownership contracts](../../ENGINEERING_FOUNDATION.md) | Preserve ownership and overlap rules. Do not recreate model-owning paint sets or independent populations for overlapping Paint Areas. |
| Receiver-keyed candidate identities and independent placement/source/scale/density channels | [Sampler](../../../AminScatter/src/scatter.cpp), [receiver planning](../../../AminScatter/src/receiver_plan.cpp) | Preserve stable candidates where F02 applies. Accepted membership can change through quotas, Relax, masks, sizes and collisions. |
| Ordered collision scopes, protected edits, final-transform Auto Radius and bounded neighbor work | [Procedural pipeline](../../../AminScatter/src/procedural.cpp), [spacing](../../../AminScatter/src/group_spacing.cpp) | Forest's larger-radius-first policy is a different product choice. Do not silently substitute it. |
| Normal alignment toggle, slope/altitude fades, UV channel/resolution selection, numeric mesh-channel masks | [P03](P03.md), [P04](P04.md), [mesh mask delivery](MESH_MASK_0824.md) | These are implemented foundations. New work extends orientation and map targets; it does not add the same basic controls again. |
| Paint/spline conversion, holes and independent density/scale fades | [P05](P05.md), [Brush](../../../AminScatter/src/brush.cpp) | Improve transfer and usability only where a demonstrated gap exists. Arbitrary curved/folded painting remains unsupported. |
| Static multi-layer recipes including active/disabled/empty/orphan Paint, explicit roles and one-Undo import | [Recipe codec](../../../AminScatter/src/recipes.cpp), [capture/import UI](../../../AminScatter/tools/ui/templates/recipes.ms) | Extend the existing recipe service. No separate executable or replacement serializer is needed. |
| Retained Mesh/Point/Proxy previews, adaptive limits, scoped idle fixes and atomic publication | [Publication](../../../AminScatter/src/point_publication.inc), [0.82.3 correction](PERFORMANCE_0823.md), [viewport baseline](../terrace-0815/VIEWPORT_0817.md) | Measure remaining cold/UI costs separately. GPU drawing is not GPU scattering; stable pixels alone do not prove reuse. |

Current recipe limits matter: actual authored Edit deltas, per-instance radius overrides and nonstatic/unknown controllers block complete save; assets remain external; bound Paint needs compatible geometry/frame and saved system units. General source animation, new layouts/maps, library packaging and effects are not made complete by the 0.82.5 recipe delivery.

## Difficulty order and relationship to the existing program

Difficulty is relative engineering risk, not a duration estimate. Adjacent ranks overlap; host API qualification can change the order. Dependencies take precedence over ease. A step may need several small, separately qualified deliveries.

| Rank | Improvement | Difficulty | Main prerequisite | Existing program relationship |
| --- | --- | --- | --- | --- |
| I01 | Passive diagnostics and repeatable performance baseline | Small | Current source/loaded identity | P01/P11 support; B01/B11/B21/B25 |
| I02 | Faster panel binding and interaction cleanup | Small–medium | I01 measurements | P01/P11; B21/B25 |
| I03 | Recipe browser and completeness feedback | Small–medium | Existing 0.82.5 service | P10 follow-up |
| I04 | Direction controls and controlled normal blending | Medium | Existing final-transform/radius contract | P07; ranking does not reorder P06/P07 execution |
| I05 | Explicit variation policy for copy/import | Medium, high semantic risk | Identity/persistence audit | P10 follow-up; F02/F11 |
| I06 | Rectangular, staggered and hexagonal layouts | Medium | Stable domain IDs and projection contract | **P06 — paused** |
| I07 | Path spacing, sequences and reference placement | Medium–large | I04/I06 shared services where actually needed | P08 |
| I08 | Scale/rotation maps and map-driven model selection | Medium–large | Map snapshot contract; final transforms | P09 |
| I09 | Shared evaluated terrain snapshots | Large, high performance value | I01 proves extraction cost | Cross-cutting performance; P11 support |
| I10 | Finer reuse of candidates, filters, attributes and acceptance | Large | I01; I09 when snapshots are shared | Cross-cutting performance; F02–F08 |
| I11 | Complete adaptive preview and resource lifecycle | Large | I01; stable publication/snapshot ownership | P11 remaining scope |
| I12 | True UV pattern placement and explicit surface projection | Large | Geometry/map snapshots; domain IDs | Beyond current eleven-phase scope |
| I13 | Authored Edit/radius recipe transfer | Large | I05; existing Edit/binding contracts | Broader P10 follow-up |
| I14 | Typed, bounded effects without an expression language | Large | I08/I10 final stage/dependency rules | Additional feature, outside P01–P11 |
| I15 | Asset packages and transactional library application | Very large | I03/I05; supported payload adapters | Broader P10/library expansion |
| I16 | Source animation sampling and geometry LOD | Very large | I09/I11; explicit time/source identity | Additional feature |
| I17 | Renderer adapters and separately qualified edge trimming | Very large | Stable output; asset/material contracts | Additional renderer work |
| I18 | Expression effects, editor and execution limits | Very large | I14 proven in production-like fixtures | Additional feature; hardest general-purpose extension |

Recommended priorities after a future implementation authorization: establish I01, fix measured I02 costs, then bring I09/I10 forward when their profiling trigger is met. Continue the original product phases only when their pause/order is explicitly addressed. Easier browser work can proceed independently when scoped. I12–I18 are not prerequisites for completing the original eleven phases.

## I01 — passive diagnostics and a trusted baseline

**Current gap and research:** Cyrus has useful counters and a scoped 0.82.5 idle witness, but cold preparation, UI binding, extraction and upload costs are scattered across receipts. Forest's cache/notification traces show why these costs need separate measurement; they do not provide a comparative speed result. See research 10 and current B01/B11/B21/B25.

**Deliver:** consolidate existing diagnostics before adding instrumentation. Report requested/accepted/shown counts, pending/publication state, and bounded counters/timers for input extraction, candidate generation, masks, attributes/radii, spacing, publication, preview preparation and uploads. Keep diagnostics opt-in and passive; reading them must not hash geometry or solve. Give each artist action one correlation ID and its actual invalidation reason.

**Performance gate:** in a warm static scene, 60 seconds idle plus repeated panel browsing and unrelated animation produce zero additional Cyrus extraction, map bake, solve, preview preparation and unchanged-buffer upload work. Relevant edits still work. Measure instrumentation overhead with logging disabled/enabled; do not accept an observer that causes the activity being measured.

**Tests:** use the fixture/protocol section below; verify counter changes with one deliberately relevant operation, then unchanged reads, pending Manual edits, Live changes and failed publication. Distinguish cold reconstruction from idle work. Reuse existing diagnostic services and private host harnesses; no always-running profiler or service.

**Exit:** a reproducible baseline and cost breakdown, with unsupported metrics marked unavailable. Contracts F04–F08. Touchpoints: controller, native publication, `input_validity.cpp`, existing performance harnesses.

## I02 — faster panel binding and interaction cleanup

**Current gap and research:** B25's idle correction is scoped; B21 still records full-controller construction cost. Forest's retained state and display-only notification branches support separating interaction from generation, but do not establish a superior UI implementation.

**Deliver:** profile construction, owner binding, list population and layout independently. Reuse unchanged controls/list rows; construct expensive secondary panels only when needed; refresh only changed displayed values. Preserve a valid owner identity across callbacks that rebuild controls. Consolidate duplicated notification-driven refreshes only after tracing their cause.

**Performance gate:** no scene extraction/solve/upload on warm owner selection or opening/closing panels. Measure cold and warm handler completion and physical response separately; predeclare a reduction target from I01's dominant cost and variability. Avoid constant timer polling as a shortcut. Cache size must remain bounded across repeated owner switches.

**Tests:** 100 open/close/owner-switch cycles; remove/Undo the selected owner; switch main/floating/container views; edit a pending Manual setting; invoke actual generated controls and subsequent callbacks. Exercise docking, keyboard focus and DPI physically when available. A direct function call alone does not certify the UI.

**Exit:** measured latency reduction with unchanged authored state/publication and no stale-owner callbacks. Contracts F01/F04/F08. Scope stays in authoritative templates/generator and their existing binding paths.

## I03 — recipe browser and completeness feedback

**Current gap and research:** 0.82.5 supplies paged browsing, explicit refresh and roles; search/tags/thumbnails and shared category navigation remain open. Forest has separate settings, effect and asset-library formats; presenting them as one interchangeable save operation would be misleading.

**Deliver:** show recipe type, selected layers, included Paint and external assets clearly. Add search/tags over a bounded metadata index, incremental visible-page loading and optional precomputed thumbnails. Share navigation with category presets without changing their formats. Add an owner-specific preflight explanation for unsupported Edit/controller data. Keep Add layers and New setup distinct. Do not introduce lossy save behavior under Save Everything.

**Performance gate:** list/search/preview produces zero scene calculations, mesh reads or asset imports; normal browsing does not hydrate every Paint attachment. Compare 128, 2,000 and 10,000-entry local libraries with bounded memory and visible-page work. Network roots require explicit refresh, bounded requests and responsive cancellation; metadata caching needs a documented same-path-change policy.

**Tests:** corrupt/unsupported entries, missing sidecars, Unicode names, duplicate names, read-only folders, offline roots, metadata changes, destination deletion while dialog is open and pending Manual values. Full import still verifies attachment hashes. Reuse `recipe_tests.cpp`, `test_recipe_contract.py` and `tools/recipes_0825/` before inventing another harness.

**Exit:** discoverability improves without changing save fidelity or idle behavior. P10 follow-up; F01/F04/F08/F11. I15 owns asset packaging.

## I04 — direction controls and normal blending

**Current gap and research:** normal alignment already has an on/off control. P07 still proposes target/direction orientation; the current orientation uses geometric face normals. Forest's transform/effect traces illustrate the dependency from orientation/scale to final collision proxies.

**Deliver:** explicit world direction or target-facing mode, declared local forward/up axes, and a controlled upright-to-surface-normal blend. Define composition with random yaw/tilt, source transforms and movement. Keep geometric normals as the established mode; smooth/interpolated normals require a separate qualified input option, including smoothing groups and hard edges. Do not use an orientation normal change to silently redefine slope filtering.

**Performance gate:** direction edits reuse candidate positions and unrelated random choices. Recompute final bases and affected radii/acceptance; do not reuse stale Auto Radius. Target animation invalidates only dependent populations. Normal data is prepared once per applicable snapshot, not obtained through a host call per instance.

**Tests:** flat/tilted/vertical faces, opposed normals, zero-length target vector, coincident/deleted target, nonuniform/mirrored transforms, axis conventions, 0/1 blend endpoints and animated target versus unrelated animation. Check complete matrices, finite orthogonal orientation where intended, final radii, Undo and reopen.

**Exit:** orientation follows the declared convention and leaves unrelated sampling stable. P07 remains planned; difficulty ranking is not permission to skip paused P06. F02/F03/F07/F09/F10.

## I05 — explicit variation policy for copy and import

**Current gap and research:** Cyrus separates candidate channels, but recipe import creates fresh scene owner/source/receiver identities. Forest keeps the target root seed in its inspected library style path; scene clone, custom-item duplication and effect templates follow different rules. A saved seed is not the complete variation contract.

**Deliver:** audit every copy/import route and distinguish ownership ID, random-domain identity, source ID and item ID. Specify Keep target variation, Copy saved variation and New variation for operations where those meanings exist; show no meaningless choice on a new empty target. Record chosen entropy once so Redo does not reseed. Preserve existing scene behavior by default; any identity/algorithm change needs an explicit data/version decision under current-only schema policy.

**Performance gate:** variation derivation is bounded per candidate; no reseeding or hashing on redraw. Source list reordering is a separate contract: do not promise reorder invariance merely because candidates have IDs. Consider stable-ID source selection only after benchmarking; the Forest research's rendezvous proposal is not Forest's recovered CDF algorithm.

**Tests:** copy/new setup/Add, same versus different receiver bindings, receiver insertion, source reorder/add/remove, zero weights, fixed-total quota changes, Relax, Undo/Redo and reopen. For compatible identical domains compare full transforms/source choices; for changed domains assert only the documented conditional stability. Verify independent channel edits and thread-count reproducibility.

**Exit:** artists can predict variation policy without borrowed ownership or false exact-copy promises. F01/F02/F11; `receiver_plan.cpp`, sampler, recipe capture/import and existing Edit identity paths.

## I06 — regular layouts: Phase 6 remains paused

**Current gap and research:** Bands describe planting strips; they do not provide rectangular/staggered/hexagonal lattice rules. Forest's selected Image path is a repeating map-aligned lattice, whereas current Cyrus samples surface area.

**Deliver after explicit resumption:** rectangular, staggered and hexagonal modes with physical spacing, origin, rotation and bounded jitter. Define domain coordinate space and candidate identity from lattice coordinates and receiver/domain identity. Specify seam/duplicate ownership, negative cells and projection onto supported terrain. Amount becomes a declared cap/count policy, not an unexplained replacement for spacing. Integrate masks, Paint, slope, Bands where supported, and existing collision scopes.

**Performance gate:** enumerate only bounded intersecting cells/tiles; never allocate a dense grid across enormous empty bounds. Candidate and attempt admission remains enforced. Mask/viewport changes do not shift lattice identities. Record projection and filtering cost separately.

**Tests:** analytic coordinate/count oracle for all layouts; shifted/rotated/negative origins; known row offsets; clipped borders/holes; terrain transforms; overlapping receivers; unit conversion; stable surviving cells after domain expansion; zero/tiny spacing rejection; candidate-limit failure preserves old output.

**Exit:** P06's existing acceptance and generated UI/recipe field accounting pass. No implementation starts under this plan. F02/F05/F06/F09/F10.

## I07 — path spacing, repeating sequences and reference placement

**Current gap and research:** existing spline Bands and Analyzer rows are not a general direct path-placement mode. Forest documents path/reference modes; the research does not recover their complete private algorithms.

**Deliver:** arc-length spacing with start/end offsets, closed-loop seam policy, tangent orientation and repeating stable source-role sequences, including explicit gaps. Define multi-spline order and behavior when reversing a path. Reference placement uses explicit node identities/transforms. Preview and final output consume one placement result. Preserve current Band semantics rather than forcing them into the new path mode.

**Performance gate:** build adaptive arc-length tables once per spline revision under an error/work bound; reuse them for source/style-only edits. No linear search of every spline segment for every plant. Relevant animated paths update; unrelated animation does not. Bound reference lists and zero-length segments.

**Tests:** straight line, circle and known polyline oracles; tolerance under strong curvature; closed seams; reversed paths; transformed splines; sequence gaps; source deletion; reference reorder/copy/delete/Undo; changed spacing; Manual/Live; recipes and units. Compare orientation and final collision radii, not only counts.

**Exit:** P08 with documented sequence/domain stability. Depends on shared orientation/domain services only where needed; the original phase order remains controlling. F01–F07/F09–F11.

## I08 — transform maps and model-assignment maps

**Current gap and research:** Cyrus already supports sampled texture density and numeric mesh-channel density. Forest's source-selection research traces weighted/color/cluster routes and effect input contexts; it does not justify treating every map as the same density control.

**Deliver:** introduce typed map targets incrementally: uniform scale, supported axis scales, rotation, then model assignment. Each input declares texture or mesh-channel source, component, coordinate space, remap curve, range, inversion and invalid-data behavior. Define color-space/distance/tie rules for model assignment and use stable source roles. Preserve explicit density multiplication and independent random gates. Do not multiply density twice or interpret viewport diagnostic colors as stored channel values.

**Performance gate:** reuse map snapshots by actual dependencies, time validity, coordinate context and sampling settings. Perform host map evaluation/preparation on the host thread; workers sample copied values. A curve edit should reuse the underlying sample data when valid. Scale/model changes must invalidate affected radii and collisions; tint-only future changes should not.

**Tests:** constant/ramp/checker and exact color regions; barycentric channel seams; invalid/missing channel; channel 0 versus numbered channels; UV clamp/tile policy; nonfinite ranges; neutral map parity; scale/source/radius coupling; map animation; same-time channel edits; mesh mask × texture × Paint × slope × Bands; persistence and recipe declaration coverage.

**Exit:** P09's supported targets and map semantics are explicit and qualified. Do not claim arbitrary procedural/3D-map support from a 2D bake. F02–F11; map bridge, sampler, mesh density and recipe field inventory.

## I09 — shared evaluated terrain snapshots

**Current gap and research:** Forest's native trace shows shared prepared receiver data. Cyrus reuses receiver-local rows, but `meshOf`/`surfaceMeshes` in `max_bridge.cpp` read/copy geometry during generation; several layers can need the same evaluated terrain. This is a profiling hypothesis until I01 quantifies it.

**Deliver:** one immutable Cyrus snapshot per valid receiver/dependency revision, shared by consuming layers. Separate base mesh/topology, transforms and requested channel data where this avoids material duplication. Keys include robust node lifetime identity, geometry/topology/transform revisions, requested channels and valid time interval; time alone is insufficient. Unknown modifier validity stays conservative. Max evaluates and copies on the host thread; workers never retain scene pointers. Use bounded strong ownership while in use and bounded cache residency afterward.

**Performance gate:** with 1/3/10 layers sharing one unchanged terrain, count one Cyrus extraction per distinct required snapshot key per build opportunity; cache hits avoid repeated copies and unchanged derived acceleration builds. This does not promise Max itself evaluates only once internally. Record extraction bytes/time, hits/misses, retained/peak memory and eviction rebuilds. An independent layer's source/density edit must not invalidate terrain. Do not implement if measured gain is negligible relative to lifetime/memory cost.

**Tests:** shared versus distinct receivers; UV/channel-only edits; Data Channel changes at the same time; transforms; topology edits; animated modifiers; deletion/replacement/Undo/reopen; same-name nodes; concurrent readers over copied data; forced eviction and allocation failure. Compare all output fields against the uncached reference, including Paint/Edit bindings. Failures retain the previous complete publication and release only owned temporary data.

**Exit:** proven avoided extraction plus bounded memory and exact supported output parity. F01/F04–F11. Keep the existing source-metadata cache conceptually separate from terrain snapshots.

## I10 — reuse intermediate results and optimize acceptance without changing policy

**Current gap and research:** independent random channels already exist, but some edits still take broad generation paths. Forest separates preparation and evaluation and replays work after effect changes. Copying its replay mechanics would add complexity; Cyrus needs explicit dependencies.

**Deliver:** split only measured expensive boundaries: raw candidate/anchor data, sampled fields, source/transform attributes, final radii, acceptance and display. Record revisions per stage. Start with high-frequency edits such as mask curves, source weights and orientation. Preserve ordered layer acceptance, protected edits, refill and cleanup semantics. Benchmark CDF preparation/binary lookup for large source lists and a sparse/outlier-aware spacing strategy if those dominate; retain a small brute-force collision oracle. Do not silently adopt radius-first ordering or rendezvous selection.

**Performance gate:** mask-curve edits reuse valid raw candidates/field samples; display-only edits skip placement/acceptance; source changes reuse terrain and candidate coordinates where current contracts permit. Shared collision changes still propagate to dependent owners. Cache memory includes old publication plus successor staging; reduced CPU time cannot hide unbounded retained copies. Set per-edit improvement targets from I01 and require no unexplained regression outside measured noise.

**Tests:** reference-versus-reuse full-row comparison; randomized edit sequences; zero/all-zero weights; boundaries/tangency; huge/small/off-center sources; XY/3D scopes; candidate target/refill; Relax; protected edits; neighboring-layer dependencies; cache eviction; cancellation/failure; Undo/reopen. Changing accepted membership is allowed only when the actual changed input warrants it.

**Exit:** measured skipped work with unchanged declared behavior. F02–F08/F11. A general field graph or async scheduler is not an automatic prerequisite.

## I11 — complete adaptive preview and resource lifecycle

**Current gap and research:** retained representations, navigating/idle caps and fallback exist. B11 cold realization, long sessions, actual presented frame times and device/resource boundaries remain open. Forest's ready-buffer gates support retained drawing but are not a GPU placement design.

**Deliver:** complete deterministic shown-subset selection, representation transition reuse, resource admission and clear fallback feedback. Profile source preparation and first realization separately. Add optional camera clipping only with explicit shadow/reflection consequences; keep it distinct from viewport-only simplification. Geometry LOD is I16. Do not let adaptive display change accepted placements or exact output.

**Performance gate:** idle/navigation causes no placement solve or unchanged-data upload; representation changes perform only their necessary preparation. Test fixed shown geometry and viewport settings before comparing drawing. Capture presented frame-time distributions only with a valid collector; redraw duration alone is not FPS. Repeated mode/cap changes reach a bounded resource plateau. Record CPU retained bytes, peak process memory and VRAM only where actually measurable.

**Tests:** Point/Mesh/Proxy transitions; zero/unlimited caps with admission; dense sources; two owners sharing a source; pending Manual edits; hidden/disabled layers; 100 mode cycles; supported allocation/buffer-failure injection; recovery; fresh-process cold scene; representative long session. Explicit camera tests include off-camera shadow/reflection contributors.

**Exit:** remaining P11 promises have matched host evidence and a declared renderer/physical-input limit. F04–F08; native display/publication and existing viewport-policy tests.

## I12 — true UV patterns and explicit surface projection

**Current gap and research:** current World Density with UV Mask is not pattern generation in UV coordinates. Forest's UV affine preparation is traced, but the selected Lite worker does not establish the complete accepted-instance pipeline. Its global UV size estimator is not a reliable per-face world-distance metric to copy blindly.

**Deliver:** a separate UV Pattern mode with map-face/geometry-face correspondence, UV triangle acceleration, containment/barycentric attachment, overlap-sheet ownership and tangent handedness. Keep World Density with UV Mask unchanged. Define whether spacing is UV units or world units; implement one mode first. General ray projection is a separate query with explicit direction, hit range and stacked-surface policy. Do not infer that UV attachment makes current vector Paint valid on arbitrary surfaces.

**Performance gate:** reuse per-snapshot UV acceleration; avoid candidate × all-faces scans. Bound degenerate and overlapping-sheet work. Geometry deformation and UV-only edits invalidate different prepared data when safe. Record memory and cost under many UV islands and high overlap; cap pathological cases with actionable diagnostics.

**Tests:** analytic triangle barycentrics, seams/shared edges, overlapping and mirrored UVs, degenerate UVs, out-of-range coordinates, negative/nonuniform transforms, hard/smooth normals as supported, unit conversions, same-time UV edits and deformation. Verify exactly one or explicitly multiple placements according to sheet policy and full publication/Undo/recipe behavior.

**Exit:** complete generation-to-output fixtures, not just a prepared UV grid. F02/F05–F11. Additional scope beyond P01–P11.

## I13 — authored Edit and per-instance radius recipe transfer

**Current gap and research:** 0.82.5 refuses unsupported authored Edit/radius data. Forest scene Save/Clone preserves custom records through separate paths; its library style helper shows no explicit source custom-record transfer. This makes mode and content transfer separate decisions.

**Deliver:** an explicit authored override payload using stable candidate/item/source correspondence, separate random identity, deletions/copies/transforms and radius records. Define compatible procedural-domain restoration before allowing transfer; keep incompatible data blocked or explicitly inactive with original bytes preserved. Add Append/Replace/Keep only for a declared owner scope. Mode conversion is a separate command. Avoid storing transient published buffers as authored truth.

**Performance gate:** capture must not regenerate placements merely to discover overrides. Bound record counts, payload sizes and matching work; use indexed identity maps. Recompute affected final transforms/radii/acceptance once after commit. Imported sources must not require quadratic name searches.

**Tests:** edited/moved/deleted/duplicated candidates, protected zero-quota edits, radius overrides, reordered/substituted sources, changed seed/domain/topology, missing receiver, Paint coexistence, inactive restore, one Undo/Redo and reopen. Compare complete authored records and final rows. Inject failure after staging several layers and before final publication.

**Exit:** Save Everything's supported domain expands honestly; unsupported controllers still reject. F01–F06/F09–F11; Edit storage/stack, recipe codec and host import.

## I14 — typed effects with explicit dependencies

**Current gap and research:** Forest exposes typed read/write attributes, changed-value tracking and guarded reevaluation. Scale/source changes recalculate its collision proxy indirectly. Cyrus currently offers dedicated controls rather than a general effect stack.

**Deliver:** start with a small ordered stack of declarative operations over prepared data: remap fields, adjust scale/orientation/position within a supported attachment policy, select source, or change visibility/tint where output supports it. Each operation declares reads, writes, coordinate units, random channel and work bound. Keep identity read-only. Recompute final proxy/acceptance from consolidated collision-relevant changes rather than replaying arbitrary operations until convergence. Persist definition separately from instance parameters and owner IDs.

**Performance gate:** disabled/identity operations have negligible measured overhead; parameter edits reuse unchanged compiled/prepared definitions. Tint-only operations skip collision work, while scale/source edits cannot. No Max host API calls per worker candidate. Bound stack length and temporary arrays; measure 0/1/8/32 supported operations on admitted populations before setting limits.

**Tests:** order-dependent compositions with independent expected results; neutral-operation parity; scale/source changes versus fresh rebuild; position reattachment; nonfinite output; failed operation; same definition ID with changed content; deterministic random channels; Manual/Live; clone/import/Undo/reopen. Unsupported cycles/feedback reject before mutation.

**Exit:** a bounded effects service and clear UI work without an expression compiler. F01–F11. Separate authorization outside P01–P11; I18 is optional later language work.

## I15 — complete asset packages and library application

**Current gap and research:** Cyrus recipes bind external assets. Forest's traced library path acquires scene assets through XRefs, optionally merges records, selectively assigns settings and then handles materials/hooks. Parameter transfer and asset ownership are separate graphs.

**Deliver in slices:** first manifest/dependency collection for supported Cyrus assets; then explicit import/reuse/share and duplicate-name rules; then a qualified Max scene/XRef adapter. Record content fingerprints, units, renderer/material variants and missing-file state. Separate complete setup import from Apply style to an existing target. Keep/Copy/New variation and Keep/Append/Replace authored items are independent policies. Effects and custom items are supported only when their adapters exist; otherwise preflight rejects. Keep assets external to the core installer.

**Performance gate:** browsing reads metadata/precomputed thumbnails only. Repeated identical apply should reuse unchanged asset/content state and perform no unnecessary solve. Stage each shared dependency once, bound graph depth/size and peak staging memory, and avoid a full asset-tree scan on idle. Same path/name is not a sufficient content-validity key.

**Tests:** shared models/materials, nested dependencies/XRefs, duplicate names, same-path changed content, missing textures/proxies, unsupported controllers/plugins, units, source remapping, cancellation and host import failure. Restore temporary SDK policies; clean only transaction-owned assets. Test one Undo/Redo, deletion with external dependents, save/reopen and reuse after source-file changes. Arbitrary library scripts are not implicitly executed.

**Exit:** supported packages are reproducible and ownership survives failure/lifecycle tests. F01/F04–F11. Forest-native scene conversion remains a distinct project, not implied compatibility.

## I16 — source animation and geometry LOD

**Current gap and research:** Forest's source cache traces time-valid samples, reference-aware bounded eviction and animation-related state. It is not proven strict LRU. Cyrus source metadata validity and live dependencies do not constitute a complete animated-source/LOD feature.

**Deliver in slices:** explicit source sample time modes and deterministic offsets; bounded reuse of copied geometry samples; then separate viewport/render LOD policy. Define whether LOD changes affect collision proxy or presentation only; default to stable physical placement. Distinguish moving/deforming receivers, animated sources, animated parameters and static unrelated scene animation. Velocity is not assumed available for all objects; any derivative service needs its own sampling/time-step contract.

**Performance gate:** static sources do not rebuild on unrelated time changes. Cache samples by source/content/time validity and share immutable data across instances; no evaluated mesh per plant. Bound total sample memory and eviction work. Use hysteresis where LOD switching would otherwise thrash; retain stable placement IDs.

**Tests:** constant/deforming/topology-changing sources, looping/clamped/reversed time offsets, subframes, repeated frames, timeline jumps, negative/nonuniform transforms, LOD thresholds, camera movement, render versus viewport, source deletion, eviction and reopen. Verify materials and animation sample identity, not just bounding boxes.

**Exit:** one explicitly supported source/time/LOD matrix is qualified before broad claims. F02–F11; renderer animation/motion blur needs I17 qualification.

## I17 — renderer adapters and clean edge trimming

**Current gap and research:** Forest companion modules/public features suggest renderer-specific adapters, but complete adapter internals are not recovered. Cyrus's current output/render evidence is narrower than arbitrary renderer/proxy/material compatibility. Density or scale fading does not physically trim geometry at a border.

**Deliver separately:** (A) declare supported renderer/version/source/material combinations and make efficient instance publication correct; (B) qualify interactive rendering, source changes and cleanup; (C) only then prototype edge trimming for one supported renderer/material/proxy path. Keep trimming separate from density/scale controls, and define which geometry/material operations implement it. Investigate the current official SDK for each chosen adapter before committing a design.

**Performance gate:** render setup should scale with accepted instances and unique source samples, without a giant combined mesh by default where the renderer supports instancing. Compare startup time, memory and render output using identical assets/settings. Repeated interactive updates must release retired resources. Trimming needs its own shader/geometry time and memory budget.

**Tests:** material IDs, UVs, normals, multi-materials, supported proxies, source pivots/mirrors, shadows/reflections, camera clipping, motion blur if supported, render cancel/restart, interactive edit, missing renderer and device/session failure. Edge fixtures include exact borders, holes, crossing blades and material variants; verify actual clipping rather than disappearance of whole instances.

**Exit:** a documented support matrix with visual and quantitative receipts for each slice. No universal Forest/Chaos renderer parity claim. F05–F11; additional work outside the eleven phases.

## I18 — expression effects and authoring tools

**Current gap and research:** Forest's effect model, attribute bridge and compilation wrappers are traced; its full grammar, bytecode, resource limits and failure-retention semantics are not recovered. A general language is a much larger commitment than typed operations.

**Deliver only after I14:** define a small versioned expression language over typed attributes and approved pure functions. Specify types/units, evaluation order, independent random inputs, diagnostics and execution budgets before implementation. Add an editor and parameter UI, definition/instance identity remapping, content-based compilation keys and defaults-versus-current-value import semantics. Keep scene access behind prepared inputs; exclude arbitrary MAXScript/native calls from the expression evaluator.

**Performance gate:** compile once per definition content/schema/compiler version, not per instance or redraw. Bound operations, stack/storage and execution time through deterministic fuel or equivalent limits; allocation and compilation caching remain bounded. A same-ID changed program must recompile. Compare common effects against equivalent typed operations.

**Tests:** parser/type/unit errors, malformed/deep expressions, budget exhaustion, nonfinite math, deterministic threading, changed code with retained IDs, failed compile/evaluation retaining prior complete output, parameter-only edits, presets, clone/import/Undo/reopen and useful artist diagnostics. Fuzz the parser/evaluator against its closed contract; tests must not just restate implementation formulas.

**Exit:** useful supported effects, predictable cost and stable failure behavior. Additional scope, not required for the original eleven phases or I14 delivery.

## Common performance and validation protocol

Every step uses applicable [V01–V12 checks](VALIDATION.md), the [engineering contracts](../../ENGINEERING_FOUNDATION.md), and **Max 2027 only**. Retain current candidate/layer/resource limits until a separately measured change justifies revising them. None of the following fixtures or measurements has been run by this planning task.

### Fixtures and workload matrix

| Fixture | Purpose | Planned variations |
| --- | --- | --- |
| T1 Analytic plane/terrain | Known positions, slopes, fields, bounds and units | Plane, tilted plane, known triangles, mountain-like mesh; two UV channels; mesh channel 0/2; holes and hard edges |
| T2 Shared terrain | Extraction/cache sharing and independent owners | 1/3/10 layers sharing one terrain versus distinct terrains; 20k/200k requested candidates, then a separate admission-limit case |
| T3 Authored setup | Interactions and lifecycle | Three layers; Paint islands/hole/disabled/orphan areas; Bands; linked and independent collision scopes; Model/Point/Empty sources |
| T4 Sources and acceptance | Bounds, source choice, final transforms | Centered/off-center/tall/wide geometry; mixed radii; nonuniform/mirrored/sheared transforms; protected Edit data |
| T5 Library | Browsing, format and assets | 128/2,000/10,000 manifests; corrupt/missing files; duplicate names; shared and nested dependencies |
| T6 Production copies | Representative heavy behavior | Owned copies of mountain/terrace scenes and supported plant assets; hash originals and copy dependencies without changing originals |
| T7 Failure and lifetime | Retention, recovery and bounded work | Invalid channels/geometry, admission exhaustion, controlled allocation/publication failures, owner deletion, cancellation and reopen |
| T8 Time/render | Relevant dependencies and output | Static scene plus unrelated animation, animated receiver/source/map/target separately; one qualified renderer combination at a time |

The 1m root candidate limit includes retry/protected requirements; do not generate 1m candidates in every layer and call it a supported ten-layer fixture. Record requested, generated, accepted, shown and rendered counts separately.

### Measurement rules and completion gates

1. Freeze source commit/dirty scope, script/native hashes and loaded paths. Record Max/SDK, machine, renderer, scene/asset hashes, viewport, settings and background workload. A caption/version alone is insufficient.
2. Run paired baseline/candidate trials in equivalent scenes. Use at least five fresh-process cold observations and thirty warm observations for noisy performance claims where practical; report individual values and median/p95 with sample count. Reverse run order to expose warm-cache bias. Smaller samples are explicitly exploratory.
3. Separate host evaluation/extraction, numeric generation, masks, attributes/radii, spacing, publication, CPU preview preparation, uploads and drawing. Read-only inspection must not trigger these stages. Cache counters and full output comparisons are both required.
4. **Hard gate:** warm static idle/browsing/unrelated time produces no new Cyrus placement calculations or unchanged-buffer uploads. A 60-second observed window is the minimum regression fixture; it is not proof of indefinite zero activity. Relevant Live edits must still update; Manual pending edits must remain pending.
5. **Optimization gate:** compare identical behavior and output. Choose timing/memory improvement and regression thresholds from measured baseline variability before changing the implementation. A proposed speedup is accepted only with reduced relevant work and a measured benefit; do not invent a universal FPS or latency guarantee.
6. **Resource gate:** account for retained old output plus staged successor. Repeated edit/mode/import cycles reach a bounded plateau under the stated cache policy. Record CPU/process/GPU measures separately; missing VRAM/presented-FPS instrumentation leaves those claims open.
7. **Correctness gate:** compare all eight current placement-row fields, all twelve matrix values, source/identity/face/barycentric/Band/protection/version data, and applicable radii/authored payloads. Position/source-only fingerprints cannot certify complete equality. New modes use independent analytic oracles and declared tolerances.
8. **Failure gate:** exercise rejection before mutation, failure during staging/publication and recovery. Prior complete graph/output remains valid. One Undo/Redo, save/reopen, copy/merge, units and stale-owner callbacks are included when affected.
9. **Interaction gate:** scripted fixtures invoke actual generated handlers and subsequent callbacks. Physical drawing, docking, DPI, tablet and perceived responsiveness require actual observation; unavailable physical checks remain explicit acceptance limits.
10. **Long-session gate:** shared caches, assets, animated sources and render adapters need repeated lifecycle cycles plus a representative sustained session. Preserve meaningful telemetry and failure cases; a successful short run does not close device-loss or arbitrary-asset support.

Existing tests to extend include `receiver_tests.cpp`, `procedural_tests.cpp`, `group_spacing_tests.cpp`, `publication_tests.cpp`, `mesh_density_tests.cpp`, `surface_filter_tests.cpp`, `spline_band_tests.cpp`, `viewport_policy_tests.cpp`, `recipe_tests.cpp`, and `tools/recipes_0825/`. Inspect fixture assumptions first; historical launchers may use old schemas or versions. Use native mathematics/ownership tests, generated integration checks, then a matched private host. Do not write string-matching tests that merely mirror the implementation.

### Vendor comparison experiments

When separately authorized, use disposable Max 2027 scenes and the hash-pinned Forest installation. Start with shared-receiver extraction/relevant edits, source weights/scales and collision outcomes, then preset/library transfer and Undo/reopen. Compare only supported common behavior and equivalent geometry/shown counts; the Lite three-source restriction in an inspected path is not a Cyrus requirement. Runtime ownership, same-ID effect-code replacement, same-path library-content changes and custom-mode library application are especially valuable unresolved fixtures. Report different algorithms as different behavior rather than a failed parity test. Exact seeds need not match for an independently implemented feature.

## Additional research candidates, deliberately outside I01–I18

| Candidate | Why deferred / required decision | Performance and acceptance before adoption |
| --- | --- | --- |
| Particle-driven input | Existing particle/output workflows are not proof of a live particle-input adapter. Select a supported host API and item identity/lifetime contract first. | Bulk copied particle snapshots, no per-item host calls; birth/death/reorder/subframe identity, deterministic transforms, bounds, Undo/reopen and relevant time tests. |
| Paint on arbitrary curved/folded surfaces | Current vector Paint is a single-valued local-XY document. Changing its domain is a new authoring/serialization design. | Bound surface traversal/geodesic queries; seams, stacked sheets, holes, topology edits, brush latency, exact preservation and failed-transfer recovery. |
| Native curvature or velocity fields | Data Channel already supplies useful curvature input. Native fields require a demonstrated workflow/performance gap and defined units/neighborhood/time semantics. | Analytic plane/sphere/saddle or known-motion oracles, retessellation/noise sensitivity, same-time invalidation, shared snapshot reuse and bounded sampling memory. |
| Cooperative asynchronous jobs or GPU placement | Profile first; existing host-thread and synchronous worker lifetime rules are intentional. Neither is implied by Forest's GPU display. | Owned copied inputs, cancellation budgets, stale-result rejection, deterministic policy, peak staging/device transfer cost, failure recovery and real end-to-end benefit. |

## Delivery checklist for each later authorized step

- [ ] Select a bounded slice, preserve the Phase 6 pause unless explicitly resumed, and record intended behavior, unaffected behavior, owners and relevant F/V contracts.
- [ ] Pin current source/evidence; resolve semantic decisions and predeclare fixtures/performance thresholds before coding.
- [ ] Implement in native sources and authoritative templates/generator; account for new authored fields in presets/recipes, catalog and units. No generated-script-only fix.
- [ ] Pass focused native/generated checks and the applicable Max 2027 correctness, lifecycle, failure and performance gates. Expand regressions when shared paths change.
- [ ] Record measured results, failed iterations and remaining limits in the existing execution handoff/TODO/backlog. Update artist help only for proven behavior.
- [ ] Choose the next small-step delivery version under [version policy](../../Release_Versioning.md); this plan assigns no versions. Use the current [version policy](../../Release_Versioning.md) for provisional labels; the original planning baseline was 0.82.5 and the subsequent I01/I02 delivery is 0.82.6.
- [ ] For a version delivered for user testing, build a runnable Max 2027 `.mzp` from the exact qualified script/native pair; verify archive, guards and payload hashes. Provide **Scripting > Run Script** and restart instructions. The user installs it; do not install or restart their session without explicit authorization.
- [ ] Commit/push only within the authorized implementation scope, preserving unrelated work. Do not deploy a website or alter independently versioned products as a side effect.

## Research source map

These links point to local research evidence, which is outside the Cyrus Git repository. Preserve its original hashes and qualifications. A machine without the sibling folder needs that research separately; the product never depends on these paths at runtime.

| Evidence | Use in this plan |
| --- | --- |
| [Method and scope](<F:/Cursor/_Cyrus_Apps/Forest Reverse/docs/02_METHOD_AND_SCOPE.md>) | Lite/Pro, static/runtime and proposal distinctions |
| [Distribution](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/08_DISTRIBUTION_DEEP.md>) and [cache invalidation](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/10_CACHE_INVALIDATION_DEEP.md>) | I01/I02/I06/I09/I10 |
| [UV preparation](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/14_UV_PREPARATION_AND_METRIC.md>) and [publication limits](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/15_UV_GENERATION_AND_PUBLICATION.md>) | I12 |
| [Collision radius](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/18_COLLISION_RADIUS.md>), [source choice](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/19_SOURCE_SELECTION.md>) and [random seeds](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/20_RANDOM_SEEDS.md>) | I04/I05/I08/I10; preserve deliberate Cyrus differences |
| [Effects/replay](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/23_EFFECTS_AND_REPLAY.md>) and [custom editing](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/24_CUSTOM_ITEM_EDITING.md>) | I13/I14/I18 |
| [Cloning](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/29_CLONING_AND_REFERENCE_OWNERSHIP.md>) and [effect/seed persistence](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/30_EFFECTS_SEED_PERSISTENCE.md>) | I05/I13–I15 |
| [Parameter presets](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/33_PARAMETER_PRESET_SAVE_LOAD_APPLY.md>) and [effect/library boundaries](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/35_EFFECT_AND_LIBRARY_PRESET_BOUNDARIES.md>) | I03/I05/I13/I15 |
| [Library application](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/38_LIBRARY_MAX_IMPORT_APPLY.md>), [state transfer](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/39_LIBRARY_SEEDS_EFFECTS_CUSTOM_ITEMS.md>) and [asset lifecycle](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/40_LIBRARY_REFERENCES_AND_LIFECYCLE.md>) | I05/I13–I15 and runtime fixtures |
| [Feature evidence matrix](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/05_FEATURE_MATRIX.md>) | Documented broader animation/render/path capabilities; detailed later reports supersede older open-status rows |
| [Latest research validation](<F:/Cursor/_Cyrus_Apps/Forest Reverse/evidence/validation-library-20261015-08.json>) | Research artifact integrity; no vendor execution or performance parity |

For the existing Cyrus recipe architecture, retain the [research contract](../../Scatter_Data_Recipes_Research_2026-10-15/PRESET_CONTRACT.md) as broader design and the [0.82.5 format](../recipes-0825/FORMAT.md) as the implemented wire contract. For the original phase outcomes, retain [IMPLEMENTATION](IMPLEMENTATION.md) and [VALIDATION](VALIDATION.md). Planning is complete. I01/I02 implementation and scoped acceptance are recorded in the [0.82.6 handoff](../panel-performance-0826/PROGRESS.md); later steps and their acceptance gates remain pending. Phase 6 stays paused.
