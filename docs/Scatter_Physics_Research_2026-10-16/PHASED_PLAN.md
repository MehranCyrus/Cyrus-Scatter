# Scatter Physics phased development plan

16 October 2026. **Original planning status: experiments and implementation were NOT STARTED when this plan was written.** The user subsequently authorized building and testing a separate Max 2027 node, without integrating it into Scatter and without Computer Use. [IMPLEMENTATION.md](IMPLEMENTATION.md) tracks that execution. The original plan and its unchecked checklist remain a planning baseline, not a current completion receipt. A later request supplies its own scope; this document does not require repeated approval for routine work already authorized within it.

The objective is an artist-controlled tool for spraying rigid leaves, stones and debris, letting them collide and settle, and retaining the result as efficient instances. Start with a controlled **Jolt CPU versus PhysX CPU comparison and real Max 2027 brush tests**. Select the engine and host scheduling approach from those results before product integration.

## Basis, scope and reading order

This plan operationalizes [the proposed architecture](PROPOSED_DESIGN.md) and [experiment matrix](VALIDATION.md). It relies on [current Cyrus source findings](CYRUS_SOURCE.md), [tyFlow evidence and limits](TYFLOW.md), [Houdini workflow research](HOUDINI.md), and [pinned upstream engine sources](ENGINES.md). Vendor examples inform experiments; they do not establish Cyrus performance or functionality.

At planning time, the branch is `codex/workflow-0.75`, HEAD `9f8cc157279b6e257f1f4a0eb6280fc75b0ea58c`, with substantial existing tracked and untracked work. The README-linked qualified baseline is [0.85.0/schema 58](../plans/improvement-program/I06_0850.md); the earlier research observed in-progress 0.85.1/recipe-format-5 source. Re-audit actual source, package and loaded identities at execution time. No version is reserved by this plan.

A new full-source knowledge check and identifier search returned `stale_evidence`; the status checked 38 enrolled parents and verified 15 in generation `44bb57523e1286764c655754ce79ed3e4299bce12c0c71b7c49b212258dfa0d3`. Direct maintained documents and the research were used. The index was not refreshed. Original [EVIDENCE.json](EVIDENCE.json) and [KNOWLEDGE_STATUS.json](KNOWLEDGE_STATUS.json) remain historical research receipts, not fingerprints of this new plan or proof of future execution.

The recommended first product scope is Physics Brush, followed by Physics Area using the same solve/result path. Static scene colliders and completed gestures act as fixed obstacles. New births interact dynamically with each other. Full-layer rebuilding is explicit. Animated collider playback, deformable leaves, physically accurate wind, two-way movement of scene nodes, GPU physics and local contact-island re-settling are later candidates.

## Phase map and dependencies

| Phase | Deliverable | Required before proceeding |
| --- | --- | --- |
| 1A | Jolt/PhysX quality, cost and failure comparison | Frozen fixtures, pinned builds, measured tolerances |
| 1B | Existing Cyrus brush and optional tyFlow reference tests in Max 2027 | Owned profile, matched loaded pair, actual UI/input witnesses |
| 2 | Engine decision, Max scheduling proof and reviewed data contract | Both Phase 1 tracks; measured feasibility |
| 3 | Bounded native geometry, emission and committed-result foundation | Phase 2 decisions; later implementation request |
| 4 | End-to-end Physics Brush with provisional preview and atomic commit | Phase 3 foundation and failure tests |
| 5 | Durable editing, Undo, scene persistence and recipe rules | Phase 4 interaction; save contract designed in Phase 2 |
| 6 | Procedural Physics Area | Same stable solver, publication and persistence path |
| 7 | Performance qualification and artist workflow refinement | Core Brush/Area behavior complete |
| 8 | Exact-pair Max 2027 qualification and runnable MZP delivery | Acceptance matrix complete for declared scope |

Phase 1A and 1B are independent investigation tracks. Their results can be collected in either order; mutations in one Max process must be serialized. Phase 2 is their joint decision point. Geometry, persistence and failure contracts are designed early and validated progressively rather than postponed until release. Phase labels are local to this feature and do not replace the existing improvement-program ledger.

No calendar estimate is committed before Phase 1 identifies proxy quality, cancellation and host costs. At the Phase 2 gate, estimate the remaining work using measured complexity and list the assumptions. Do not start building both engines into the product to avoid making the decision.

## Phase 1A — compare Jolt and PhysX before integrating either

**Question:** Can either CPU engine produce convincing rigid-leaf contact within practical resource and interaction budgets?

### Preparation and fair comparison

1. Start from the exact commits in [ENGINES.md](ENGINES.md). Check build prerequisites and documented features for those revisions; if a different revision is needed, record the reason and new commit before collecting results. Do not assume the inspected PhysX commit matches the separately cited 5.5 documentation.
2. Plan a disposable numeric harness, outside production targets, with a small shared fixture/birth-file format and separate engine drivers. This is future experimental code, not work performed by the present planning task. Keep the production engine interface undecided until the comparison is complete.
3. Freeze source/proxy meshes, static collider meshes, source frames, physical units, gravity, masses/inertia policy, scale, initial velocities, spawn schedule and random seeds. Fingerprint inputs. Engines must receive the same authored births and physical geometry; different internal cooked hulls must be inspected and recorded.
4. Use CPU-only builds with explicit compiler/runtime, instruction-set, floating-point, worker-count and optimization options. Record CPU, RAM, OS, power configuration and competing workload. Validate single-thread behavior first, then a fixed worker budget applicable to Max.
5. Compare a common baseline and then each engine's documented tuning at matched quality. Identical iteration counts, sleep settings or CCD names are not necessarily equivalent algorithms. Record actual substeps, offsets, margins and tolerances rather than comparing only UI labels.
6. Count executed fixed steps explicitly. A starting experiment is 1/60 second with 1/120 and 1/240 sweeps for difficult thin/fast cases; these are test settings, not chosen production defaults. Emission follows step IDs, independent of display or wall-clock delays.

### Frozen fixture set

Use simple generated or permitted assets first so every result can be reproduced without artist files. Name each scene, source and proxy revision.

| ID | Fixture and variations | Evidence to capture |
| --- | --- | --- |
| E01 | One box and one thickened flat leaf dropped onto an analytic plane | Contact height, orientation, energy decay, settled time, numerical sanity |
| E02 | Flat, curled and irregular leaves; convex outline versus bounded compound hull | Visible float gap, penetration, contact footprint and proxy cooking cost |
| E03 | Thin/fast drops; height, velocity, thickness, contact margin, step and CCD sweeps | Fall-through/tunnelling count, worst penetration and step cost; retain failed combinations |
| E04 | Street curb, gutter, bench legs, pavement gaps and concave static geometry | Collision against the correct surfaces; no accidental bridging caused by oversimplified colliders |
| E05 | Mixed leaves/stones at several scales; dense overlapping piles | Pairwise penetration, drift, plausible overlap, stability after the quiet criterion |
| E06 | Slopes and several friction values; deliberately never-settling case | Slide behavior and truthful timeout; no forced success from a maximum-step limit |
| E07 | Birth inside an obstacle and overcrowded brush footprint | Bounded placement retries, explicit underfill, controlled rejection of invalid initial state |
| E08 | Metres/centimetres, large world offset, displaced pivot, nonuniform/mirrored input | Equivalent physical setup and correct source-to-proxy-to-render transform mapping |
| E09 | Separate body, pair, contact, scratch, hull and memory exhaustion | Reliable error detection, no accepted output with omitted contacts, bounded cleanup |
| E10 | Repeated identical birth files; varied display rate and worker budget | Identity/source-choice equality, full-transform differences and stated repeatability scope |

Start with one body, then 100, 1,000 and 10,000 simple bodies only while the preceding tier passes. Add a higher tier only if a declared product scenario needs it. These tiers are experiment sizes, not supported capacity promises. Dense piles and sparse street coverage need separate results because contact load differs sharply.

### Measurement protocol

- Use an independent analytic distance check for plane cases and a documented geometry oracle or offline inspection for complex contacts. Do not judge penetration solely from engine debug flags. Report both proxy penetration and the visible render gap; collision thickness, margin and render surface are distinct.
- Define physical length/angular/velocity tolerances per fixture before comparing engines. Normalize them to leaf dimensions and units, and keep the same acceptance tolerance for both engines. Threshold changes require a new run and an explanation.
- Measure geometry conversion, proxy/collider cooking, world construction, each simulation step, total settling, transform extraction and teardown separately. Report wall time, peak memory, active/sleeping counts, pair/contact load where available, and errors. Include retained old/new results in a separate integration memory budget.
- Use at least five repeated timing runs per representative configuration, distinguishing cold and warm preparation. Increase repetitions when noise obscures the decision. Report distributions and worst observed values, not only averages. Do not calculate meaningful p95 claims from five total end-to-end runs; use enough per-step samples or report the raw run range.
- Define settling as a sustained quiet interval plus engine sleep/activation checks. Run an additional observation interval to detect residual drift. Record max-step exits separately. Failed-quality and exhausted-capacity runs cannot win the speed comparison.
- Compare identical inputs within each engine separately from cross-engine output. Equal final transforms between Jolt and PhysX are not required. Same-build repeatability must be measured; stable saved results cannot depend on cross-version bit equality.

### Engine decision rule

First apply mandatory gates: acceptable thin-body contact, usable proxy preparation, observable resource failures, bounded operation/lifetime behavior, correct transforms/units, and a compatible build/distribution strategy. An engine failing a mandatory gate remains unsuitable regardless of speed.

For candidates that pass, report a proposed scorecard: contact/visual quality 35%, Max integration and cancellation risk 25%, performance/memory 20%, repeatability/diagnostics 10%, and maintenance/build/distribution 10%. Publish the raw measurements and rationale behind each score; weights do not override a correctness failure. Resolve close results by the simpler reliable integration and lower measured worst-case cost. If neither passes, investigate the specific proxy/contact problem before expanding to Bullet. Do not add GPU work automatically.

**Deliverables:** an engine comparison report, machine-readable run table, exact build/input manifests, reference images and selected quality/performance envelope. Suggested future filenames are `results/ENGINE_COMPARISON.md` and `results/ENGINE_RUNS.csv`; they do not exist yet. Put binaries, scenes and raw traces in a fresh ignored `build/scatter-physics-<run>/` directory and link their identities from the report.

**Exit:** a provisional engine choice or a concrete no-go reason. The final choice waits for Phase 2's in-Max probe.

## Phase 1B — test the existing brush in Max 2027

**Question:** Which parts of the current Painter integration can support the proposed gesture, and what is their measured responsiveness and failure behavior?

### Establish the host baseline

Use Max **2027 only**, a fresh owned profile and disposable scenes. Pin the actual executable/SDK, script hash, native hashes, loaded paths, display mode, screen scaling and fixture assets. Choose either an intact qualified package or an explicitly built experimental pair; never mix delivered 0.85.0 binaries with dirty 0.85.1 scripts. Preserve the artist session, profiles, `Test Scene/` and existing licensing work.

Begin with the current, unmodified Cyrus coverage brush. It does not emit physics bodies. Its tests establish input/session/Undo behavior and expose integration constraints. Any private diagnostic probe added later needs an explicit experiment scope and a separate build identity; it stays out of product packages.

| ID | Action through actual UI | Required observation |
| --- | --- | --- |
| H01 | Start the brush from its real generated button, allow status ticks, draw and release | Valid session remains active; complete lifecycle reaches the expected owner |
| H02 | Slow/fast drags, stationary hold, quick clicks, off-surface travel and re-entry | Actual sampling/callback sequence and hit validity; distinguish existing coverage behavior from future emission policy |
| H03 | Resize brush, change viewport/camera, switch panel or layer during a gesture | Defined session termination or continuation; no stale owner/control access |
| H04 | Cancel and Stop; then Undo/Redo with earlier unrelated Undo entries | Exact pre/post document and independent-layer fingerprints; history remains usable |
| H05 | Relevant receiver change, deletion, scene reset/load and host close | Session cleanup, no orphan feedback or callback after owner destruction |
| H06 | Flat/tilted terrain, transformed receiver, hole, stacked/vertical/closed surface | Supported hits and clear current coverage rejection; do not treat projection restrictions as a limitation of all 3D picking |
| H07 | Warm idle, navigation and unrelated animation with Manual edits pending | Stable committed rows and solve/preparation/upload counters; pending edits stay pending |
| H08 | Repeated strokes with heavier source display and controlled low heap headroom | Feedback/commit cost, peak memory and Undo survival; retain B26 failures as failures |

Use physical mouse input for final gesture evidence. Scripted handler/native-callback tests supplement it. Tablet pressure is an optional separate witness only if it will be supported. Test 100% and 150% UI scaling; record other displays/DPI combinations as untested rather than extrapolating.

Measure event-to-feedback and release-to-commit latency, p50/p95 frame intervals where presentation can actually be observed, longest callback, cancel response and retained memory. A 16 ms feedback timer or 33 ms status timer is not a latency result. If presented frames cannot be measured, label the timing available and keep physical responsiveness acceptance open.

**Provisional targets for the later physics prototype:** on a named reference workstation and an admitted workload, aim for p95 cursor/brush feedback within 50 ms, no routine main-thread work slice over 16 ms, and visible cancel acknowledgement within 100 ms with safe session retirement within 250 ms. These are proposed engineering targets, not measured results or promises. Count uninterruptible cooking/steps when measuring retirement. Confirm or revise the targets with the baseline before feature implementation; record any change rather than lowering thresholds after a failed run.

### Bounded vendor reference checks

If tyFlow is available in the owned profile, build a disposable Birth Paint + PhysX Shape + PhysX Collision example. Test continuous versus mouse-release updates, held gestures at fixed timeline time, preview removal, Undo/Redo and whether prior strokes replay. Record exact binary/configuration and real behavior. This answers gaps in [TYFLOW.md](TYFLOW.md); neither its callback stub nor its Undo imports prove the whole runtime workflow.

If an available Houdini installation can answer a remaining procedural question, execute the small [reference network](HOUDINI.md): stroke/mask, stable births, render/proxy pairing, emitted RBD pieces, static colliders, cached final transforms. Verify actual node/version behavior. An unavailable vendor installation is an explicit evidence gap, not a reason to install software or block Cyrus tests that already resolve the decision. No new reverse engineering is needed unless a named unresolved question changes our design.

**Deliverables:** `results/MAX2027_BRUSH_BASELINE.md`, input/timing traces, scene and loaded-build manifests, short captures, and a reuse/gap table for picking, callbacks, Undo, timers and display. Vendor observations belong in a separate clearly scoped section.

**Exit:** physical brush lifecycle is understood, failure cases are reproducible, and the host responsiveness budget is specified. Existing brush success alone does not qualify a physics brush.

## Phase 2 — select the engine, prove scheduling and freeze contracts

**Entry:** both Phase 1 reports. **Purpose:** resolve high-cost integration decisions before production development.

1. Run a small isolated Max 2027 probe with the provisional engine: copied static geometry, a fixed saved birth stream, bounded moving-transform preview, cancellation and shutdown. Compare time-sliced stepping with an owned numeric worker only as needed to resolve callback cost and cancellation. Do not implement both as permanent modes.
2. Audit compilation and packaging: CRT/allocator ownership, CPU instruction requirements, floating-point state, symbol/library isolation, dependency loading and coexistence with installed physics plugins. An engine's presence inside Max or tyFlow is not a supported public API for Cyrus. Measure the proposed embedding itself.
3. Prove Max geometry capture/publication stays on the host thread. Test owner deletion, load/reset, cancellation during cook/step/result transfer and shutdown. A worker cannot retain live node pointers; the existing synchronous `forRanges` helper is not an asynchronous lifetime service.
4. Choose the engine/scheduler from the measured contact envelope and in-Max result. Document limitations and rejected alternatives. If an operation cannot meet cancellation bounds, cap inputs, prepare earlier or change the design before moving on.
5. Freeze the following contract decisions and their falsifying tests. Use the defaults below unless the evidence demonstrates a reason to change them.

| Decision | Recommended initial contract | Required test/implication |
| --- | --- | --- |
| Ownership | Dedicated Physics layer; explicit receiver and collider bindings | Wrong-owner switching/copy cannot borrow another result |
| Identity | Persistent layer/gesture/emission IDs; temporary engine body handles separate | Undo, erase and reorder preserve surviving identities |
| Emission | Distance-resampled brush; optional time spray is separately scheduled | Saved birth stream independent of redraw; off-surface gaps do not bridge |
| Existing strokes | Frozen blockers by default; explicit full-layer rebuild | Appending preserves earlier transforms exactly; rebuilding may couple them |
| Collider time | Snapshot at gesture start; relevant changes cancel the tentative successor | No stale result accepted after dependency change |
| Transform authority | Solver final transform with explicit proxy/COM/source mapping | No later surface alignment, spacing, refill or support-removing cleanup |
| Scheduling | Fixed steps, bounded queue, revision-tagged snapshots | No silently dropped births, skipped steps or stale completion |
| Update modes | Physics solves require an explicit gesture/Settle/Rebuild action in v1 | Manual pending siblings stay pending; unsupported automatic Physics replay is clearly stated |
| Completion | Quiet interval plus sleep checks, with finite steps | Timeout is not settled; explicit Keep Current, if exposed, records incomplete-settle status |
| Publication | Stage result and Undo, then one coherent host-thread commit | Faults before and after mutation retain the previous complete result |
| Persistence | Final transforms authoritative; bounded birth recipe and input/config fingerprints retained | Reopen renders without solving; changed engine does not replay implicitly |
| Editing scope | Erase/freeze plus explicit whole-layer rebuild | No implicit neighborhood re-simulation or promise of preserved physical support after erase |

Write a field/units/ownership schema, lifecycle state machine and operation table. Specify save-during-solve behavior: serialize the last committed result and declared authored state only; do not save a half-completed session or promise resumable velocities. Define source/proxy/collider changes as stale or invalid pending inputs without destroying the retained result. Audit integration against [F01–F11](../ENGINEERING_FOUNDATION.md).

**Deliverables:** engine decision record, selected scheduler probe results, contract/schema draft, operation/failure matrix, initial resource limits and phase estimates. No production version is selected merely to run a probe.

**Gate:** proceed to feature implementation only under a later user instruction covering it. The first implementation scope should be one engine, rigid convex/compound bodies, static colliders and the complete retained-result boundary. If Phase 1/2 fails, preserve the reports and revise the failed decision rather than beginning speculative integration.

## Phase 3 — build the bounded native foundation

**Entry:** Phase 2 decisions and implementation scope. **Artist outcome enabled:** trustworthy emission and geometry, ready to be connected to a brush.

- Add the selected engine with explicit build options and dependency notices. Keep the numerical core independent of Max scene evaluation. Do not add a product multi-engine abstraction.
- Implement source/proxy preparation: convex and bounded compound support, optional explicit custom proxy, invalid/open/degenerate shape policy, and separate static-collider preparation. Distinguish render geometry from physical geometry and show the source of proxy failure.
- Implement typed units, session-local origin, world-Z gravity, proxy center-of-mass/source-pivot mapping and exactly-once scale. Support or explicitly reject mirror/shear/nonuniform cases as decided in Phase 2. Cache keys include geometry, frame, scale, units, engine and cooking settings.
- Implement stable birth records and independent randomness channels. Keep original spawn anchors separate from settled transforms. Resample paths deterministically; bound samples, births, retries and admission without silently discarding user input.
- Implement fixed-step solve, completion/error detection, numeric-only snapshots, cancellation/lifetime ownership and budget accounting. Include pair/contact exhaustion, old/new snapshots and Undo memory, not just body count.
- Establish the dedicated committed Physics result inlet and minimal persistence representation now. Stage full rows/source correspondence/metadata; bypass ordinary post-solve projection and rejection. Keep preview and committed results distinct.

**Validation:** E01–E10 on the chosen engine; independent transform/unit oracles; invalid proxy and resource errors; replay with saved births; identical unrelated-layer fingerprints; fault injection through staging and result installation. Test failure recovery with valid inputs immediately afterward. No engine update error may be downgraded to a successful partially collided result.

**Exit:** numeric tests and bounded Max integration pass on the frozen pair; geometry/identity/commit contracts are usable without UI special cases. Known unsupported geometry has actionable rejection, not silent fallback. B08 geometry stress remains open beyond the exercised matrix.

## Phase 4 — implement the complete Physics Brush gesture

**Entry:** Phase 3. **Artist workflow:** pick sources and collision surfaces, press Start Brush, drag to spray, release to settle, keep the committed result.

1. Reuse the suitable Painter/picking pieces identified in Phase 1B. Author a separate Physics emission document; preserve ordinary Paint's coverage semantics and receiver-local projection limits. General 3D Physics picking needs its own visible-hit/backface/multiple-receiver policy.
2. Bind real UI controls to the Physics layer model: radius, spacing/flow, height, source weights/variation, essential physical controls, collider selection, proxy preview and Start/Stop/Cancel. Keep technical diagnostic settings out of routine artist controls.
3. Connect Preparing → Spraying → Settling → Committing → Idle, plus Cancel/Error paths. Provide clear progress, underfill and limit messages. Mid-gesture settings either use the captured settings snapshot or terminate the session explicitly.
4. Show bounded transient previews while the prior committed scene remains valid. The display cap affects visible instances only; it cannot silently remove simulated contacts. Read-only inspection and rendering consume the committed snapshot.
5. On release, finish the declared settle criterion and commit one gesture with one Undo record. No long-running Max Undo transaction spans arbitrary worker callbacks. Cancel, overload or invalidation retains all prior work.

**Validation:** repeat H01–H08 with the new tool and real physical input. Add different redraw rates/preview caps with the same saved births; immediate owner switching/deletion; rapid stop/start; invalid source/collider mid-solve; late old-session completion; allocation/commit-tail failure; exact Undo/Redo; minimal save/reopen. Test the current ordinary brush as an unaffected case.

**Exit:** the full gesture works with the agreed latency/cancel budget on admitted fixtures, no stale publication, and exact retention of prior strokes/independent layers. This is an internal development milestone, not permission to deliver an incomplete save/Undo implementation.

## Phase 5 — make results durable and editing predictable

**Entry:** working end-to-end brush and the earlier data contract. **Artist outcome:** a saved composition survives normal scene editing and recovery.

- Complete scene serialization of authoritative final transforms, persistent identities, source frames, bounded birth recipe, bindings and engine/config revision. Validate size/count/integrity before allocating. Reopen must not cook proxies or solve just to display the retained result.
- Cover save/reopen, clone/copy, merge, owner remapping and unit conversion. Preserve missing source/proxy/collider records and show their state; do not resolve them by matching display names. Unsupported saved schemas are rejected explicitly under the current project policy.
- Implement erase/freeze and explicit full-layer rebuild with preview/cancel and one Undo per operation. Erase preserves other frozen transforms and flags that physical support may need rebuilding. Local re-settle is deferred because its support island and boundary policy require separate evidence.
- Define settings-only and result-inclusive recipe behavior explicitly. If only one is in the delivery scope, label it and reject unsupported export rather than silently dropping physics data. Revisit the then-current closed recipe schema and asset packaging; the research's format-5 observation is not a permanent baseline.
- Define source/proxy geometry replacement and collider movement: retained output remains available, relevant inputs become stale, and explicit rebuild uses new inputs. Binding failure must not rewrite old scene files or discard a usable prior result.
- Exercise low-headroom Undo using the B26 reproduction pattern. Measure native and MAXScript transient/retained allocations. Preserve history or enforce a tested admission boundary before mutation; do not change the artist's heap preferences or treat native storage as proof of a fix.

**Validation:** full identity/transform/source-frame fingerprints after roundtrip, copy, merge and Undo/Redo; missing assets; malformed/oversize payload; unit changes; save during a solve; source deletion; failure on both sides of commit; repeated operations and recovery. Confirm read-only/export paths do not simulate.

**Exit:** durable state and history pass for the declared envelope. Rebuild reproducibility is reported separately from exact saved-transform restoration. B26 can remain a repository-wide open item while this feature has an explicit, tested safe boundary; it cannot remain an unbounded silent failure in the feature's supported range.

## Phase 6 — add procedural Physics Area

**Entry:** shared solver, publication, persistence and Undo pass. **Artist workflow:** paint coverage, choose a bounded amount/density, press Settle, then retain the result.

1. Consume existing receiver-bound Paint coverage through a separate area-emitter adapter. Coverage overlap unions eligibility once; it does not create duplicate populations. Reuse layer source ownership and existing supported coverage restrictions.
2. Generate identity-bearing births from the area recipe before solving. State count versus density, source choice, scale, initial height, frame, random seed and birth timing explicitly. Do not confuse density per area with births per second.
3. Offer explicit Settle/Rebuild, stale-input feedback and cancel. In Manual mode, mask/settings edits remain pending until that action. Ordinary layers retain their established Live behavior; automatic Physics replay remains out of v1 unless separately designed and tested.
4. Store the same committed-result structure as Brush. Keep direct-gesture history distinct from mask-derived births. Replacing coverage deliberately creates a new solve revision without pretending every physically coupled transform is locally stable.
5. Provide clear final-boundary semantics: the mask restricts births, while settled objects may roll outside it. A containment constraint is a separate explicit option, not an invisible clip after physics.

**Validation:** union/erase/feather masks, multiple receivers, holes and unsupported coverage; count/density unit equivalence; stable birth choices within the declared scope; explicit rebuild; missing receiver; unchanged sibling layers; cancel/failure retention; recipe and save roundtrip. Re-run Brush fixtures to verify the shared path remains correct.

**Exit:** Brush and Area feed one solver/result contract with distinct authoring semantics. An equivalent saved birth stream yields equivalent same-engine behavior regardless of inlet within the measured repeatability scope.

## Phase 7 — qualify performance and refine the artist workflow

**Entry:** functional Brush/Area and persistence. **Goal:** publish an honest supported workload and usable controls.

- Repeat the Phase 1 matrix on the integrated Max 2027 pair. Separate proxy/collider cooking, host extraction, solver, result transfer, publication, uploads, draw and presentation. Compare cold/warm caches and the same total body count when changing display caps.
- Establish supported body/contact/geometry/memory envelopes from dense and sparse scenes. Refuse unadmitted work with a useful reason; show underfill and unsettled states. Do not transplant the ordinary million-candidate limit into physics capacity claims.
- Exercise repeated append/erase/rebuild/Undo/save cycles, cancellation bursts and at least one declared sustained authoring session. Record duration, workload and memory trend; do not infer multi-hour stability from a short run. Retire old worlds, jobs, shapes, previews and Undo data according to ownership.
- Verify no solve/cook/preparation/re-upload work on unchanged warm browsing, selection, orbit or unrelated animation. Record counters as well as equality. Protect retained Mesh/Point Cloud behavior and all unaffected Manual/Live rules.
- Have the artist evaluate leaf overlap, visible contact gap, curb placement and control clarity using real assets in copied scenes. Gravity alone does not collect leaves against a curb on a flat street; use intentional emission and label any artistic force honestly.
- Refine only measured bottlenecks. If the envelope is insufficient, identify whether input extraction, cooking, contacts or display dominates before proposing extra abstraction or GPU work.

**Validation:** complete latency distributions against the agreed budget, peak memory including Undo, quality at capacity, resource failure/recovery, real input at supported DPI, and viewport/render/export source-frame parity for the declared renderers. Record untested renderer/hardware combinations explicitly.

**Exit:** artist-reviewed examples, supported limits and defaults, actionable failures, and no unresolved blocking correctness issue in the advertised scope. A lower body cap is acceptable if it is stated and enforced; silent contact loss is not.

## Phase 8 — qualify and package the exact Max 2027 delivery

**Entry:** feature scope and acceptance matrix complete. Select a version from the actual delivery baseline and [current version policy](../Release_Versioning.md#choosing-the-next-version). Record the user-visible change, scene/recipe/native capability decisions and remaining limits. Do not assign 1.0 or change independently versioned products merely because this feature is substantial.

1. Freeze the candidate source and dependencies. Edit authoritative templates/generator modules, regenerate scripts, inspect the generated diff, and run the applicable checks in the [agent workflow](../AGENT_WORKFLOW.md). Use new run directories and Max 2027 SDK builds only. Native/offline checks do not replace host tests.
2. Run focused native geometry/identity/solver/publication/persistence tests, generated/UI consistency checks and the relevant existing procedural/MCP regressions. The capability catalog must not advertise unsupported physics writes. Public MCP mutation support is a separate scope; existing tools must reject unsupported cases clearly.
3. Qualify the exact script/native/dependency pair in fresh owned Max 2027 profiles: actual handlers and physical gestures, lifecycle/fault matrix, retained display, save/Undo, ordinary-layer independence, and relevant render/export parity. Preserve original failed receipts and identify the successful successor.
4. Build a runnable `.mzp` from that exact qualified pair, including required runtime dependencies and notices. Verify archive integrity, host/version guards, payload/dependency hashes and script/native matching. Exclude diagnostic transports and private research tools.
5. Update artist guides and navigation to proven behavior. If website source docs are updated, run their import/check/build workflow and distinguish built content from deployment. Provide small reproducible example scenes with actual-result images and asset provenance.
6. Deliver the package path, scope/evidence/limits and **Scripting > Run Script**, then restart Max 2027 instructions. The user installs and restarts unless they explicitly request us to do so. Commit, push, installation and deployment remain bounded by the later user request.

**Exit:** a complete qualified package and clear artist acceptance checklist. Packaging provenance is necessary, but its hash alone does not prove runtime or artist acceptance.

## Risks, fallbacks and evidence ownership

| Risk | First gate | Concrete response |
| --- | --- | --- |
| Leaf proxies float or tunnel | E02/E03 | Tune physical thickness/skin/CCD against the same visible tolerance; reduce supported scale/speed if needed |
| Dense contacts exceed buffers | E05/E09 | Detect error, reject tentative result, retain prior work; tune capacity within measured peak memory |
| Max input stalls during cook/step | H02 and Phase 2 | Measure uncancellable unit, pre-prepare/cache or reduce admission; reassess scheduler |
| Physics changes prior independent work | Phases 2–4 | Explicit collision membership and frozen append policy; compare complete prior fingerprints |
| Erase leaves unsupported bodies | Phase 5 | Declare frozen edit semantics and offer explicit rebuild; defer local re-settle |
| Undo lost under heap pressure | H08/Phase 5 | Test B26-style boundary, minimize transient script arrays and enforce admission before mutation |
| Engine or source update changes replay | Phases 2/5 | Retain authoritative transforms and revision metadata; never silently replay on open |
| Lifecycle permits late publication | Phases 2/4 | Session/revision validation, cancellation and join/retirement before dependent teardown |
| Vendor behavior remains uncertain | Phase 1B | Record gap; use our own controlled witness when it answers the design question |

Each executed report must identify: phase/test IDs; exact source/dirty scope and engine/config hashes; loaded Max pair; machine/profile/scene/asset identities; procedure and input; expected and actual results; raw evidence location; failures and exclusions; decision and remaining gate. Use **PASS**, **FAIL**, **NOT RUN** or **NOT APPLICABLE with reason**. A source reading, simulation harness pass and physical host pass are separate evidence types.

The contract coverage is F01/F03 ownership and collision dependencies; F02 conditional identity/repeatability; F04/F08 explicit updates and display reuse; F05/F06 atomic publication and bounds; F07 worker lifetime; F09/F10 geometry/units; F11 persistence. Preserve B04/B08/B26 qualifiers from the [backlog](../BACKLOG.md). Only new executed evidence can narrow those open items.

## Execution checklist and first bounded work package

All boxes below intentionally remain unchecked. Completing this document does not complete an experiment.

- [ ] 1A: freeze numeric fixtures, pin both engine builds, run E01–E10 and record comparison.
- [ ] 1B: verify an owned Max 2027 pair, run H01–H08 and record physical interaction/reference gaps.
- [ ] 2: select engine/scheduler, pass the Max probe, freeze contracts and estimate remaining work.
- [ ] 3: implement and validate the bounded native/result foundation within later authorized scope.
- [ ] 4: complete and validate Physics Brush gestures, cancellation and atomic Undo commit.
- [ ] 5: complete durable scene/edit/recipe behavior and low-headroom acceptance.
- [ ] 6: complete Physics Area through the shared solver/result path.
- [ ] 7: establish performance limits, sustained-use evidence and artist acceptance.
- [ ] 8: qualify the exact Max 2027 pair and deliver its verified MZP.

The recommended first future execution request is **Phase 1A + Phase 1B only**: comparison harnesses and owned Max 2027 brush experiments, with reports as the deliverable. Start with analytic single-body and small leaf fixtures plus the current brush lifecycle. Increase load only after those pass. Return the engine recommendation, host constraints and unresolved decisions; product implementation follows the Phase 2 contract gate under the user's subsequent scope.
