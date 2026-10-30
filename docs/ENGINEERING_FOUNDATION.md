# Cyrus Scatter engineering foundation

The [0.87.5.6 responsive-bending delivery](plans/drag-response-08756-20261028/DELIVERY_08756.md) and [performance baseline](PERFORMANCE_BASELINE.md) record the current artist-endorsed interaction direction and scoped Max 2027 evidence. The [0.87.5.1 Library delivery](plans/scene-presets-08751/DELIVERY_08751.md) retains separate qualification. Required contracts, implementation and executed acceptance remain distinct.

Maintained contracts established 12 October 2026; current interaction routing reconciled on 28 October with Scatter 0.87.5.6 / scene 65 / Interactions 15. **Required behavior is not implementation compliance or release acceptance.** Earlier native, memory, Library, Interactions and compatibility receipts retain their exact builds, hosts and limits. Current Max 2027 viewport checks do not extend an older renderer, physical-input or compatibility pass to this build. Preserve original scenes across schema migration and keep internal registration identities intact.

The [architecture](ARCHITECTURE.md) owns implementation detail, the [backlog](BACKLOG.md) owns unresolved work, and the [workflow](AGENT_WORKFLOW.md) owns execution and host isolation. Read relevant sections without recursively loading history. F01–F12 retain their defined boundaries; historical qualifiers belong with their evidence.

## Decision and evidence vocabulary

**Established** means required by existing maintained product guidance; it does not invent a new human approval. **Proposed** means a recommendation awaiting a product choice. Verification is independent: **source inspected**, **offline tested**, **historical host witness**, **reproduced failure**, or **pending**. Historical passes cover their recorded inputs and loaded builds only. Artist acceptance, renderer qualification and long-session reliability are separate gates.

Prefer preservation of authored work, predictable edits and bounded computation. Extend existing ownership and pipelines with the smallest sufficient design. A node framework, GPU solver or compatibility layer needs a demonstrated problem and comparison with the simpler option. Competitor similarity is not a rationale or proof.

## Native foundation and language boundaries

**Engineering direction:** Cyrus Scatter uses native C++ for bulk data, with MAXScript and managed UI for bounded authored work. Choose each implementation boundary according to data volume, ownership and measured cost. The agent owns this technical recommendation; do not require the artist to choose a programming language. This direction governs new designs and migration reviews. It does not claim the existing pipeline already satisfies every target or authorize a rewrite.

| Work | Preferred owner and reason |
| --- | --- |
| Placement generation, per-instance masks/transforms, spacing, spatial indexes and bulk result buffers | Native C++ with compact typed storage; avoid placement-sized script objects and repeated native/script conversion |
| Receiver/source snapshots, dependency revisions and publication | Native host boundary with explicit lifetimes; Max evaluates its scene on the host thread, numerical workers consume owned data |
| Large Edit/result history and resource accounting | Native ownership with appropriate immutable sharing, changed blocks or command deltas; measure retained allocations and history release rather than assuming C++ copies are cheap |
| UI, small authored commands, automation and test drivers | MAXScript or the existing managed UI when appropriate; passive views read cached summaries and captured valid owners |
| Authored settings and scene/recipe persistence | Preserve the current supported ownership and serialization until a separately justified change; moving every parameter block to C++ is not a prerequisite for native computation |

The delivered 0.86.0 [N01–N09 migration](plans/native-placement/IMPLEMENTATION.md) keeps bulk placement generation, storage, acceptance and preview preparation native. MAXScript retains authored parameter blocks, UI and bounded coordination; explicit inspection, Bake and PFlow have the documented output boundaries. The older 0.85.4 compact schedules/radii were an intermediate correction, not the current bulk-storage boundary. Script-driven tests can exercise native implementations; testability does not justify leaving bulk work in MAXScript.

For any feature or migration, trace **authored inputs → evaluated snapshot → candidate/attribute work → acceptance → complete publication → preview/render/export**. Declare the authoritative owner, stable identity, units/frame, dependencies, temporary copies, memory peak, failure result and Undo lifetime at each affected boundary. A native pointer or solver handle is not a saved identity. Preserve existing numerical rounding/order where output parity is required.

Prefer one coherent typed pipeline and bounded inspection access. Do not ship duplicate placement engines, restore retired development compatibility or build a generic graph/GPU layer merely for possible future features. Exceptions to the preferred language boundary need a concrete cost/lifetime explanation and relevant measurement, recorded in the existing implementation plan.

## Performance and recovery requirements

These requirements apply through F02–F08 and F11; they are not claims of universal current compliance.

- **Avoid work before accelerating it.** Warm idle, selection, panel opening, library browsing and unrelated timeline changes must not solve static placements or upload unchanged buffers. Relevant edits invalidate only the affected dependencies and downstream work. Cold realization and resource recovery are explicit, measured exceptions.
- **Separate validity from time.** Include time only for time-dependent inputs; do not treat every frame tick as a reason to rebuild static terrain/planting. A relevant same-frame mesh/channel change still requires a new revision. Invalidating output alone does not prove that the receiver snapshot was refreshed.
- **Account for real peak memory.** Distinguish authored records, reusable snapshots, candidate/prepared/published buffers, old/new generations during commit, scratch, Undo/Redo retention, render copies and GPU resources. Count shared allocations once; account for retention of a large base buffer by a small view. A count cap, free script heap or process RAM alone is not an exact memory budget.
- **Preserve artist recovery.** Ordinary parameter Undo, explicit Edit commands and transactional preset loading have different history requirements. Do not clear Undo, silently lower the requested Count or drop authored data to hide a resource problem. Stage a complete successor, publish atomically and retain the previous complete result on failure, with a useful diagnosis.
- **Keep interaction bounded.** Coalesce relevant changes during expensive interaction where appropriate, while keeping final settings exact. Measure actual wheel/drag/spinner/brush input, panel mount, DPI and callback lifetimes separately from direct function timing. A C++ call or time slice can still block Max.

The [interactive performance baseline](PERFORMANCE_BASELINE.md) applies these requirements to artistic Bend/Trim. Keep detailed validation optional, scope pose updates to relevant dependencies and compare actual presented results while input is held. Future improvements may replace the current algorithm after measurement; a smaller calculation timer alone cannot establish better artist response.

## Physics and animation extension contract

**Required design constraints for future integration; not delivered Scatter capabilities.** The independently versioned [Physics Lab](../CyrusPhysicsLab/README.md) has experimental implementation and its own evidence. It does not qualify integration into Scatter. The [physics design](Scatter_Physics_Research_2026-10-16/PROPOSED_DESIGN.md) remains the integration proposal; the [execution ledger](Scatter_Physics_Research_2026-10-16/README.md) distinguishes later lab work from the original research. Further roadmap implementation requires a current user instruction; completed P06 grids and P07 orientation remain implemented.

1. Separate static scattering, animated evaluation and stateful simulation. Animated transforms, deforming receiver/proxy geometry, animated masks and solver state have different invalidation costs. Completed static planting and settled results remain reusable while unrelated objects animate.
2. Keep authored emission/coverage, stable body IDs, solver state, completed transforms and display buffers distinct. Solver handles, point-array order and viewport timing cannot define persistent identity. Stable IDs do not guarantee unchanged transforms when physically coupled bodies interact.
3. Declare time semantics before implementation: start/reset state, fixed simulation steps/substeps, frame rate and units, birth schedule, forward/backward seeking, checkpoints, missing-cache behavior and subframe render evaluation. Resuming simulation may require velocities/contact or solver state; final transforms alone do not establish resumability. Do not silently recook a whole simulation during a preview/render read.
4. Separate render meshes, collision proxies, receivers and colliders. Validate source-pivot/center-of-mass mapping and scale once. Cache proxy preparation by relevant geometry/settings revisions. Physically settled results need a dedicated publication inlet; ordinary projection/alignment/spacing cleanup must not move or delete their support afterward without an explicit policy.
5. Keep workers isolated from Max. Any future asynchronous scheduler needs owned snapshots, session/revision checks, bounded progress, cancellation and join/retirement on owner deletion, scene reset/load and shutdown. The present synchronous executor does not supply that guarantee. A cancelled or stale solve cannot publish late or hold an ordinary Undo transaction open indefinitely.
6. Bound bodies, contact pairs, proxy geometry, scratch, history, checkpoints and render caches separately. Show incomplete/stale results honestly. Scene save/load, missing assets, engine-version changes and recipe portability need explicit contracts; solver memory dumps are not portable recipes.

Primary reference lessons checked on 17 October 2026: SideFX documents separate render/proxy/collider inputs and simulation cache limits in [RBD Bullet Solver](https://www.sidefx.com/docs/houdini/nodes/sop/rbdbulletsolver.html), explicit saved-output reuse in [File Cache](https://www.sidefx.com/docs/houdini/nodes/sop/filecache.html), and changing point distributions on changing surfaces in [Scatter](https://www.sidefx.com/docs/houdini/nodes/sop/scatter.html). These are workflow references, not evidence of Cyrus behavior or a claim about Houdini's private implementation. Forest's [inspected memory paths](plans/native-placement/SOURCE_MAP.md) also show why native storage alone does not prove compact Undo or failure retention.

## Evolve through measured decisions

For consequential work, record the problem and expected artist behavior, current source path, simplest viable alternative, selected boundary, measurable acceptance and remaining uncertainty in the existing plan. Reuse applicable research; consult primary Autodesk/renderer/SideFX/engine documentation or bounded vendor observations for unresolved questions. Distinguish vendor documentation, inspected source/binary, executed observations and our chosen design. Do not copy a vendor's weakness to claim parity.

The [0.86.0 native delivery](plans/native-placement/DELIVERY_0860.md) is an example of this architecture evaluation: selected Forest observations motivated a native-storage hypothesis; Cyrus output parity, measured Update costs and history/lifetime tests qualified our own implementation. Forest's record size does not predict Cyrus's complete memory cost or prove its Undo behavior. Future Houdini/SideFX research should similarly produce a bounded design hypothesis and reproducible Cyrus tests, not an assumption that another application's architecture or performance transfers automatically.

Compare before/after on the same source/build identities and scene inputs: cold/warm latency, repeated Count edits, peak/retained memory, history growth/release, actual input responsiveness and solve/preparation/upload counts. Cover Manual/Live, unrelated edits/animation, owner switching, failure before/after commit, Undo/Redo and save/reopen. Physics adds timestep/replay/seek/cancel/collider tests; animation adds relevant deformation and subframe output. Use Max 2027 only. Numerical tests, host automation and physical input each establish different evidence.

After a completed improvement, update the maintained contract/architecture/backlog and its reproducible receipt; keep historical evidence unchanged. A later measured alternative may supersede a design without weakening ownership, recovery or authoring guarantees. Scope new tasks from the user's current request, not from an old roadmap command. Knowledge retrieval helps find evidence but does not replace source review; fresh hashes do not prove current behavioral truth.

## Contract and evidence map

**U** is the authoritative [controller template](../AminScatter/tools/ui/templates/unified-core.ms); symbols are search anchors, not whole-file verification. **N** is the original 12 October offline native build (15 suites), **P** its 10 focused MCP publication tests, and **W** its isolated audit probes. Their identities/results are pinned in the historical local receipt. These labels do not describe tests rerun for the 17 October documentation update. Versioned limits below retain their original evidence scope; consult the current handoff/backlog for later corrections. None of N/P/W launches Max.

### F01 Layer and Paint Area ownership

**Contract:** F01 Ownership — Established

Layers own receivers, sources and population; Paint Areas own receiver-bound coverage and share population. Supported rename/unlink/relink/copy operations preserve the intended owner's settings and identities. Candidate identity includes owner, saved receiver slot and local ordinal.

**Limits:** Source/offline support; fresh host lifecycle pending. UI sourceRowIDs, native procSourceSlots and output IDs are different namespaces. Arbitrary source-array permutation is not a supported reorder. Wrong-owner settings or borrowed publication after supported removal/reorder falsifies this rule.

**Implementation:** U: procEnsureSources, ensureSourceRows, procApplyPaint, procPublishedOwners; [receiver identity](../AminScatter/src/receiver_plan.cpp): identity, salt.

**Evidence:** N: [receiver tests](../AminScatter/tests/receiver_tests.cpp); [historical source-row witness](Point_Workflow_0.79.1_2026-10-11/README.md), B12.

### F02 Randomness and conditional point stability

**Contract:** F02 Randomness — Established conditional stability

Identical relevant numeric inputs repeat choices in the tested environment. Receiver-keyed candidate channels preserve unchanged samples under receiver insertion/filtering; scale edits must not consume placement randomness. Stable IDs do not promise unchanged accepted populations.

**Limits:** Uncapped Density rounds independently; Fixed Total/capped Density redistribute by largest remainder with saved-slot ties. Relax, geometry, source choices/weights, masks and acceptance may change output. Cross-version/platform bit equality is unqualified. A surviving unrelaxed candidate changing transform under only unrelated receiver insertion falsifies the scoped guarantee.

**Implementation:** [sampling](../AminScatter/src/scatter.cpp): Random::candidate, scatter; [quotas](../AminScatter/src/receiver_plan.cpp): plan, apportion; U: procPlanReceivers.

**Evidence:** N: receiver matrix/source comparisons and [procedural](../AminScatter/tests/procedural_tests.cpp) stableSampler, stableThreadsAndDensity, stablePatternAndRelax. W: rational quotas, channel isolation, actual Relax sensitivity. [0.76 host witness](Receiver_Stability_0.76_2026-10-10/README.md) is historical.

### F03 Independent layer edits and collision dependencies

**Contract:** F03 Dependencies — Established

Editing independent B preserves A's IDs/transforms. Coverage affects eligibility, not a second quota. Pair distance rules are symmetric. In 0.86.8, each source independently inherits or overrides its own-copy, same-layer and cross-layer scopes. Protected edits reserve space first; eligible preferred sources win conflicts before normal sources; equal-priority winners follow layer and stable candidate order. Count admission precedes conflict preference. Equivalent effective rules retain equivalent scheduling. See the [source-clearance contract](plans/source-clearance/IMPLEMENTATION_PLAN.md).

**Limits:** Independence concerns results, not zero controller work: shared admission may reject a whole successor. Overlaps use max density; strongest area controls scale, ties use area order. Implicit collision across independent layers or an area creating its own quota falsifies the rule. Fresh host independence remains pending.

**Implementation:** U: procCoverageKey, procApplyPaint, procPair, procClearanceSpecs; [source-aware acceptance](../AminScatter/src/source_clearance.cpp); [acceptance](../AminScatter/src/procedural.cpp): pairRule, protected blockers; [Brush filter](../AminScatter/src/brush_host.cpp).

**Evidence:** N: procedural exhaustive compares 240 cases with an independent oracle; targetAndOrdering, refill. W: append protected point to independent B, reorder, enable/disable pair and compare A by ID/position.

### F04 Manual updates and relevant live dependencies

**Contract:** F04 Evaluation — Established

Warm Manual placement edits wait for explicit calculation: Update scatter, Refresh preview and Refresh areas / preview. Cached reads, browsing, selection and display-only edits must not consume them. An explicitly enabled Band field view can follow authored changes and relevant animation while plants/radii remain frozen; it must say **Pending field; plants from last Update** when its field inputs differ. Live follows relevant dependencies/animation. Artists control when costly placement changes take effect.

**Limits:** 0.79.6 fault/recovery verifies pending Manual rows/epoch under display-only changes in both hosts; other physical callbacks remain pending. Cold missing-publication reconstruction and held-interaction deferral are explicit exceptions. Changed publication rows/epoch after an unrelated action with a warm pending recipe falsify the rule.

**Implementation:** U: procRefreshPreview, evaluateProcedural, AminScatterLiveTime, AminScatterLayerUndo; [input validity](../AminScatter/src/input_validity.cpp).

**Evidence:** P: [cached publication inspection](../CyrusMCP/tests/test_publication.py) rejects evaluation in a mock host. [0.79.2 Manual/Undo witness](Layer_Navigation_0.79.2_2026-10-11/README.md), B15/B18, is historical.

### F05 Atomic publication and failure recovery

**Contract:** F05 Publication — Established; bounded correction tested

Publish compatible rows, sources, radii, statistics and display/output together, or retain the last complete result and report failure. Failed preparation/admission must not destroy artist work.

**Limits:** CPU generation/item staging, script commit sites and display rollback are tested. Scoped private Max 2027 fault probes also cover later-group shader/buffer failure, complete fallback, retained generations and recovery; this does not qualify true device loss or exceptional SDK notifications. A failed install exposing mixed owner epochs or losing the prior complete result falsifies this rule.

**Implementation:** U: evaluateProcedural, procStagePreview, procRestoreResult, procEnsureDisplay; [native publication](../AminScatter/src/point_publication.inc); [Edit rollback](../AminScatter/src/cyrus_edit_stack.inc).

**Evidence:** [Current 0.80.0 evidence](plans/spline-bands/PROGRESS.md) records the exact native/script identities and bounded GPU, publication and retained-display scenarios. [0.79.6 evidence](Foundation_0.79.6_2026-10-12/README.md) preserves the original production-body allocation/item faults and 42 script assertions per Max year. Edit commits last, after all owner/root installs.

### F06 Bounded work, memory admission and underfill

**Contract:** F06 Bounds — Established

Admit finite work and report underfill/failure. Candidate pools, attempts, cleanup visits, geometry and retained resources have separate bounds. Protected zero-quota edits still consume admission.

**Limits:** 0.81.5 admits up to 1,000,000 candidates/population, with ten populations and a shared root admission of 1,000,000 including retry/protected requirements. Attempt factor up to 32 and rounds up to 16 are not peak RAM/VRAM or latency guarantees. Shared exhaustion can reject independent edits while retaining old output. Nontermination, hidden shortfall or partial publication on rejection falsifies this rule. Extreme geometry/allocation remain gates. See [current capacity evidence](plans/terrace-0815/PROGRESS.md); the preceding population ceiling was 100,000.

**Implementation:** [receiver plan](../AminScatter/src/receiver_plan.cpp), [procedural validation](../AminScatter/src/procedural.cpp), [Brush](../AminScatter/src/brush.cpp), native display; U: procValidate.

**Evidence:** N: protected over-limit/invalid inputs, cleanupWorkLimit, targetAndOrdering, Brush rejection.

### F07 Host thread and worker lifetime

**Contract:** F07 Threads/lifetimes — Established

Host API access/publication stay on the host thread; workers consume owned numeric inputs and finish before inputs/results escape. This avoids stale scene references and partial work.

**Limits:** Executor is synchronous and joins; no general asynchronous solve cancellation guarantee. Launch fallback reruns the whole numeric function, requiring overwrite-safe work. Every SDK call and thread-creation failure were not qualified. Worker access to mutable host data or use after return falsifies this rule.

**Implementation:** [executor](../AminScatter/include/execution.h): forRanges; sampling; [host bridge](../AminScatter/src/max_bridge.cpp).

**Evidence:** N: [threading tests](../AminScatter/tests/threading_tests.cpp) compare ordered transforms, numeric environment, ordered exceptions and joins; procedural serial/parallel comparisons.

### F08 Viewport reuse and shared UI state

**Contract:** F08 Presentation/reuse — Established

Shared views bind owner records. Unchanged warm display reuses placement/preparation and ready buffers. Display edits may rebuild changed layers without applying Manual recipes. Measure avoided work separately from output equality.

Edit gesture feedback derives from the current authored delta and proven
committed input. It must not consume pending Manual changes or let an older
retained presentation clear a newer gesture. The [0.86.9.1 evidence](plans/edit-instances/DELIVERY_08691.md)
qualified live handles with release-time geometry. The [0.87.6.7 successor](plans/edit-preparation-08767-20261029/DELIVERY.md)
adds bounded selected Mesh/Proxy transform patches over retained geometry,
published through the complete display/feedback transaction. Point Cloud and
larger selections retain their preceding update path. These scoped Max 2027
checks establish neither physical input latency nor production FPS.

The 0.87.5.6 contact path separately presents ready poses during held input. Its bounded per-ticket redraw requests do not consume pending placements or restage geometry. [Scoped held-input ticket measurements](plans/drag-response-08756-20261028/QUALIFICATION_08756.json) establish that path; they do not establish physical gesture latency or general FPS.

**Limits:** 0.79.6 actual native admission/recovery and two-group upload/sibling reuse passed in both hosts. Cold realization, failed resources and changed geometry need work; F05 applies. No presented-FPS measurement. Increased solve/preparation/upload counters on unchanged warm browsing falsify reuse even if pixels match. Physical callbacks/owner switching remain acceptance gates.

**Implementation:** U: procDisplayLayerKey, procEnsureDisplay, CyrusViewportRecords; [Point](../AminScatter/src/point_display.cpp) / [Mesh](../AminScatter/src/mesh_display.inc): reusable, generation-owned items.

**Evidence:** [0.79.5 color/reuse](Terrace_Workflow_0.79.5_2026-10-11/README.md), [creation correction](Terrace_Workflow_0.79.5_2026-10-11/CREATION_FIX.md): historical measured counters with distinct script identities.

### F09 Geometry bindings and vector painting support

**Contract:** F09 Geometry — Established bounded support

Face+barycentric locators are not identities across arbitrary remeshing. General scattering and vector painting support manifold curved receivers. Preserve existing local-XY terrain coverage; curved coverage is attached to indexed receiver faces. Surface-distance strokes and feathering must not leak through closed objects or disconnected sheets. Reject degenerate/nonmanifold geometry or changed geometry identity while preserving authored borders and the previous complete result. The 0.86.6 extension supersedes the earlier terrain-only restriction; its delivery report owns scoped acceptance.

**Limits:** Source/offline support; arbitrary topology restoration and extreme scales remain unqualified. 0.0001 local-unit quantization is not a universal physical tolerance. Silently reusing stale bindings or accepting ambiguous projected sheets falsifies the rule.

**Implementation:** [Brush surface](../AminScatter/src/brush_surface.cpp), [metric/projection](../AminScatter/src/brush.cpp): validateProjection, Metric; receiver mergeBinding.

**Evidence:** N: [Brush tests](../AminScatter/tests/brush_tests.cpp) reject folded/stacked surfaces, use a box-distance oracle, test transformed world radius/terrain border; receiver binding rejects changed geometry.

### F10 Physical units and dimensionless settings

**Contract:** F10 Units — Established; typed distance correction tested

Distances and density retain physical meaning across supported conversions; dimensionless weights/scales do not change. Name storage units, coordinate space and conversion boundary.

**Limits:** Old six-digit Area precision is unrecoverable. Native Paint/Edit geometry bindings still guard unsupported rescaling; saved-unit reopen recovers the tested result. Extreme vector scales remain B07. Physical-distance/density drift within the qualified conversion scope falsifies this requirement.

**Implementation:** U: world-unit fields/tabs, typed Area widths and Band ranges, procRadiusDistances, procRadii; procPlanReceivers converts density by squared units-per-meter. Schema-55/56 migration and obsolete untyped fields have been removed.

**Evidence:** [0.79.6 host evidence](Foundation_0.79.6_2026-10-12/README.md): Max 2026/2027 load, merge, save/reopen, rescale, animation and density/physical placement checks. The historical B14 raw-string failure motivated the repair.

### F11 Saved state and schema boundaries

**Contract:** F11 Persistence — Established

Save authored identities/coverage/settings; distinguish derived candidates, transient caches and published receipts. Incompatible schema/missing dependencies need explicit recovery, not guessed correspondence. Preserve original files.

**Limits:** Current schema 60; schema 59 opens with Interactions off and schema 58 requires the explicit Undoable clearance upgrade. Save upgraded copies. Earlier development scenes, including retired schema-54 model-set/stroke setups, are rejected without modifying their contents. This does not prohibit migration of separately supported recipe-file versions. Current-schema roundtrip, copy, merge and Undo remain requirements. Physical cold Undo B05, arbitrary duplicate repair and native-document rescaling are separate gates. Silent same-name replacement or wrong-owner restored data falsifies this rule.

**Implementation:** U: procAssertSchema, procEnsureSources, syncStrokes, copyLogicalLayer, procBindingName; Brush encode/decode; receiver mergeBinding. No implicit membership or old-placement conversion is permitted.

**Evidence:** Native canonical vector roundtrip/malformed rejection; [current implementation evidence](plans/spline-bands/PROGRESS.md) retains historical schema-57 save/reopen/copy/merge and native Undo events; schema-58 save/reopen/copy, captured-owner and native Undo checks are recorded separately. Schema-57 rejection preserves the original witness bytes. Historical 0.79.6 migration tests do not authorize restoring that code path.

**Current Edit boundary:** [0.86.9](plans/edit-instances/DELIVERY_0869.md) adds source-aware native Edit storage 2 independently of schema 59. Supported older Edit data requires its original compatible generation for hydration; incompatible data remains preserved. Save upgraded copies because older plugins reject the new format. Focused current-scene, genuine 0.86.8.7 migration, Undo and ordinary single-Edit Copy checks passed. Full-object Copy of an upper Edit's references to lower Edit clones, and layer radius overrides targeting clones, still need coordinated ID remapping ([B37](BACKLOG.md#edit-instance-findings--0869)). These limits do not relax the required preservation contract or qualify untested Copy/merge combinations.

### F12 Analyzer ownership and freshness

**Contract:** F12 Analyzer — Established separate owner

Consume published Analyzer guides. Cached reads may use them; a successor rejects stale enabled dependencies and retains Scatter's old result. Updating Scatter must not silently Analyze.

**Limits:** Current script inspected; Analyzer native build/fresh host lifecycle not run. Revision alone is insufficient: input references/settings/time validity matter. A stale successor accepted or cached read triggering Analyze falsifies the rule.

**Implementation:** U: requireCurrentAnalyzers, procValidate, cached-key return; [Analyzer script](../CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms): analysisCurrent, publication state, CyrusAnalyzerFlush, restore/save callbacks.

**Evidence:** [0.75 freshness/save/merge witness](Courtyard_Fixes_0.75_2026-10-10/README.md), reused historical 0.79.5 scenarios.


## Why the conditions matter

- **Locality versus total count:** adding receiver area while preserving a fixed total necessarily changes quotas. Prefix-stable sampling preserves surviving base choices, not cardinality. Relax depends on neighborhoods; requiring unchanged positions after every population edit conflicts with its purpose.
- **Order versus protection:** pair endpoints are symmetric; winner priority is not. Earlier ordinary placements win, but later protected reservations can block them. A one-way relationship would be a new product decision.
- **Coverage versus population:** overlaps union eligibility once per candidate. Curves affect acceptance/transforms, not quotas. Accepted-target refill may consume later stable candidates within its finite budget.
- **Manual versus freshness:** published and pending authored states may intentionally differ. Cold reconstruction, explicit calculation controls and Analyzer validation must be named separately. Read-only inspection must not silently repair state.
- **Atomicity versus resources:** staging costs memory, but failure retention needs old ownership until successor construction succeeds. Native allocation and script commit-tail injection remain concrete acceptance work; preparation tests do not establish it.

Typed distance representation and bounded publication recovery are implemented and tested in 0.79.6. Broader topology correspondence, native-document rescaling, cross-platform reproducibility and physical release acceptance remain outside those passes. Keep unresolved work in the existing backlog.

## Economical use and decision records

Select IDs, trace owner → dependencies → preparation → acceptance → publication, and inspect relevant source/tests. Reuse evidence already read; escalate when it conflicts, is stale or misses the boundary. For consequential choices, record expected/unchanged behavior, rationale/alternative, identities/units, failure/recovery, actual verification and remaining acceptance in the existing maintained location.

Research only unresolved decision-critical questions. Reuse the bounded [surface studies](Vendor_Surface_Paint_Research_2026-10-09/README.md) and [native studies](Vendor_Native_Deep_Research_2026-10-09/README.md) when relevant; uncertain API facts require primary vendor sources with version/scope. Distinguish documentation, observation, inference and chosen design. The original 12 October audit required no new vendor research; the 17 October extension review checked the SideFX pages linked above.

Read contract rows with their exceptions and verification cells. New documents/skills are not automatically indexed. Direct guidance is available now; post-enrollment retrieval and fresh-session effectiveness remain pending. Architecture quality, test counts and documentation volume do not establish production readiness.
