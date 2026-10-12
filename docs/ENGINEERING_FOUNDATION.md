# Cyrus Scatter engineering foundation

Maintained contracts, established 12 October 2026 and updated for source 0.79.6/schema 56. **Required behavior is not implementation compliance or release acceptance.** The [portable correction handoff](Foundation_0.79.6_2026-10-12/README.md) records bounded Max 2026/2027 publication and units evidence. Earlier failures remain in the [local audit receipt](../_local/foundation-audit/20261012-3f4f69a4/AUDIT.md); that ignored receipt is not supplied by a source-only clone.

The [architecture](ARCHITECTURE.md) owns implementation detail, the [backlog](BACKLOG.md) owns unresolved work, and the [workflow](AGENT_WORKFLOW.md) owns execution and host isolation. After required startup, read relevant sections without recursively loading history. F01–F09 retain their original meanings; F10–F12 make units, persistence and Analyzer boundaries explicit.

## Decision and evidence vocabulary

**Established** means required by existing maintained product guidance; it does not invent a new human approval. **Proposed** means a recommendation awaiting a product choice. Verification is independent: **source inspected**, **offline tested**, **historical host witness**, **reproduced failure**, or **pending**. Historical passes cover their recorded inputs and loaded builds only. Artist acceptance, renderer qualification and long-session reliability are separate gates.

Prefer preservation of authored work, predictable edits and bounded computation. Extend existing ownership and pipelines with the smallest sufficient design. A node framework, GPU solver or compatibility layer needs a demonstrated problem and comparison with the simpler option. Competitor similarity is not a rationale or proof.

## Contract and evidence map

**U** is the authoritative [controller template](../AminScatter/tools/ui/templates/unified-core.ms); symbols are search anchors, not whole-file verification. **N** is the fresh offline native build (15 suites), **P** the 10 focused MCP publication tests, and **W** the isolated audit probes. Their identities/results are pinned in the local receipt. None launches Max.

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

Editing independent B preserves A's IDs/transforms. Coverage affects eligibility, not a second quota. Pair distance rules are symmetric; ordinary winners follow evaluation order, but later protected edits reserve space. This preserves explicit artist edits as well as predictable priority.

**Limits:** Independence concerns results, not zero controller work: shared admission may reject a whole successor. Overlaps use max density; strongest area controls scale, ties use area order. Implicit collision across independent layers or an area creating its own quota falsifies the rule. Fresh host independence remains pending.

**Implementation:** U: procCoverageKey, procApplyPaint, procPair; [acceptance](../AminScatter/src/procedural.cpp): pairRule, protected blockers; [Brush filter](../AminScatter/src/brush_host.cpp).

**Evidence:** N: procedural exhaustive compares 240 cases with an independent oracle; targetAndOrdering, refill. W: append protected point to independent B, reorder, enable/disable pair and compare A by ID/position.

### F04 Manual updates and relevant live dependencies

**Contract:** F04 Evaluation — Established

Warm Manual edits wait for explicit calculation: Update scatter, Refresh preview and Refresh areas / preview. Cached reads, browsing, selection and display-only edits must not consume them. Live follows relevant dependencies/animation. Artists control when costly changes take effect.

**Limits:** 0.79.6 fault/recovery verifies pending Manual rows/epoch under display-only changes in both hosts; other physical callbacks remain pending. Cold missing-publication reconstruction and held-interaction deferral are explicit exceptions. Changed publication rows/epoch after an unrelated action with a warm pending recipe falsify the rule.

**Implementation:** U: procRefreshPreview, evaluateProcedural, AminScatterLiveTime, AminScatterLayerUndo; [input validity](../AminScatter/src/input_validity.cpp).

**Evidence:** P: [cached publication inspection](../CyrusMCP/tests/test_publication.py) rejects evaluation in a mock host. [0.79.2 Manual/Undo witness](Layer_Navigation_0.79.2_2026-10-11/README.md), B15/B18, is historical.

### F05 Atomic publication and failure recovery

**Contract:** F05 Publication — Established; bounded correction tested

Publish compatible rows, sources, radii, statistics and display/output together, or retain the last complete result and report failure. Failed preparation/admission must not destroy artist work.

**Limits:** CPU generation/item staging and six commit sites/occurrences plus display rollback are tested. GPU/device-loss and exceptional SDK notifications remain unqualified. A failed install exposing mixed owner epochs or losing the prior complete result falsifies this rule.

**Implementation:** U: evaluateProcedural, procStagePreview, procRestoreResult, procEnsureDisplay; [native publication](../AminScatter/src/point_publication.inc); [Edit rollback](../AminScatter/src/cyrus_edit_stack.inc).

**Evidence:** [0.79.6 evidence](Foundation_0.79.6_2026-10-12/README.md): direct production-body allocation/item faults; 42 actual script assertions in each Max year; native admission/reuse scenario. Edit commits last, after all owner/root installs.

### F06 Bounded work, memory admission and underfill

**Contract:** F06 Bounds — Established

Admit finite work and report underfill/failure. Candidate pools, attempts, cleanup visits, geometry and retained resources have separate bounds. Protected zero-quota edits still consume admission.

**Limits:** 100,000 candidates/population, ten populations/root admission 1,000,000, attempt factor up to 32 and rounds up to 16 are not peak RAM/VRAM or latency guarantees. Shared exhaustion can reject independent edits while retaining old output. Nontermination, hidden shortfall or partial publication on rejection falsifies this rule. Extreme geometry/allocation remain gates.

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

**Limits:** 0.79.6 actual native admission/recovery and two-group upload/sibling reuse passed in both hosts. Cold realization, failed resources and changed geometry need work; F05 applies. No presented-FPS measurement. Increased solve/preparation/upload counters on unchanged warm browsing falsify reuse even if pixels match. Physical callbacks/owner switching remain acceptance gates.

**Implementation:** U: procDisplayLayerKey, procEnsureDisplay, CyrusViewportRecords; [Point](../AminScatter/src/point_display.cpp) / [Mesh](../AminScatter/src/mesh_display.inc): reusable, generation-owned items.

**Evidence:** [0.79.5 color/reuse](Terrace_Workflow_0.79.5_2026-10-11/README.md), [creation correction](Terrace_Workflow_0.79.5_2026-10-11/CREATION_FIX.md): historical measured counters with distinct script identities.

### F09 Geometry bindings and vector painting support

**Contract:** F09 Geometry — Established bounded support

Face+barycentric locators are not identities across arbitrary remeshing. General scattering supports curved receivers; vector painting requires single-valued receiver-local XY terrain. Reject unsupported projection while preserving authored borders.

**Limits:** Source/offline support; arbitrary topology restoration and extreme scales remain unqualified. 0.0001 local-unit quantization is not a universal physical tolerance. Silently reusing stale bindings or accepting ambiguous projected sheets falsifies the rule.

**Implementation:** [Brush surface](../AminScatter/src/brush_surface.cpp), [metric/projection](../AminScatter/src/brush.cpp): validateProjection, Metric; receiver mergeBinding.

**Evidence:** N: [Brush tests](../AminScatter/tests/brush_tests.cpp) reject folded/stacked surfaces, use a box-distance oracle, test transformed world radius/terrain border; receiver binding rejects changed geometry.

### F10 Physical units and dimensionless settings

**Contract:** F10 Units — Established; typed distance correction tested

Distances and density retain physical meaning across supported conversions; dimensionless weights/scales do not change. Name storage units, coordinate space and conversion boundary.

**Limits:** Old six-digit Area precision is unrecoverable. Native Paint/Edit geometry bindings still guard unsupported rescaling; saved-unit reopen recovers the tested result. Extreme vector scales remain B07. Physical-distance/density drift within the qualified conversion scope falsifies this requirement.

**Implementation:** U: migrateDistanceSettings55, world-unit fields/tabs, typed Area widths, procRadiusDistances, procRadii; procPlanReceivers converts density by squared units-per-meter.

**Evidence:** [0.79.6 host evidence](Foundation_0.79.6_2026-10-12/README.md): Max 2026/2027 load, merge, save/reopen, rescale, animation and density/physical placement checks. The historical B14 raw-string failure motivated the repair.

### F11 Saved state and schema migration

**Contract:** F11 Persistence — Established

Save authored identities/coverage/settings; distinguish derived candidates, transient caches and published receipts. Incompatible schema/missing dependencies need explicit recovery, not guessed correspondence. Preserve original files.

**Limits:** Only immediately preceding schema 55 migrates; retired stroke/model-set formats remain rejected. Physical cold Undo B05, arbitrary duplicate repair and native-document rescaling are separate gates. Silent same-name replacement or wrong-owner restored data falsifies this rule.

**Implementation:** U: migrateDistanceSettings55, procAssertSchema, procEnsureSources, procBindingName; Brush encode/decode; receiver mergeBinding.

**Evidence:** Native canonical vector roundtrip/malformed rejection; [0.79.6 migration](Foundation_0.79.6_2026-10-12/README.md) preserves same-unit edited and painted results from schema 55 and tests load/merge/roundtrip.

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

Research only unresolved decision-critical questions. Reuse the bounded [surface studies](Vendor_Surface_Paint_Research_2026-10-09/README.md) and [native studies](Vendor_Native_Deep_Research_2026-10-09/README.md) when relevant; uncertain API facts require primary vendor sources with version/scope. Distinguish documentation, observation, inference and chosen design. No external API uncertainty required new vendor research in this audit.

Read contract rows with their exceptions and verification cells. New documents/skills are not automatically indexed. Direct guidance is available now; post-enrollment retrieval and fresh-session effectiveness remain pending. Architecture quality, test counts and documentation volume do not establish production readiness.
