# Cyrus Arrange — implementation goal and acceptance

The active user goal is the complete fourteen-item geometry-driven redesign
plus the single Modify-panel UI. Its requirements and acceptance status are in
[the 0.3.2 ledger](GEOMETRY_WORKFLOW_0.3.2.md). Earlier completed milestones below
remain historical and do not complete the new goal.

Build a usable interior arrangement system for Max 2027 with a C++ core and MAXScript UI. Work stays in this project; artist sessions/profiles and unrelated products are preserved. Computer use is prohibited; isolated SDK/script tests are authorized.

## Practical completion standard

An artist can select receiving geometry, add the props to repeat, set quantity and optional scale, then Generate from one Modify panel. The result must use valid physical sizes, support refinement and save/reopen, and reproduce a saved seed. Furniture categories do not restrict eligibility. Validate requested versus achievable targets, complete placements, performance and understandable controls. Research uncertain behavior through primary Autodesk, SideFX/Houdini and C++ sources, then test this implementation. Focused Markdown documents explain architecture, calculations, controls, examples, measurements, reproducibility and limits. A passing fixture does not promise zero defects on arbitrary inputs.

The qualified **0.3.1** successor and its native modifier, viewport icon and real
prepared-model scene are tracked in [the current acceptance record](REAL_WORLD_0.3.1.md).
The prior qualified **0.3.0** scope is recorded in its
[release ledger](RELEASE_VALIDATION_0.3.0.md). The numerical requirement ledger
below preserves the earlier 0.1.3 milestone and does not qualify later source
or binary changes.

The practical 0.1.3 workflow and exact installer qualification are complete. The matching source/examples receipt records the final delivery snapshot. Broader recipes and renderers below are explicit extensions, not claims of universal correctness.

## Requirement ledger — final native46

| Requirement | Current matching evidence | Documented boundary |
| --- | --- | --- |
| Furniture analysis | Inspector 69/0 plus five independent JSON exports; regions 83/0, obstacles 78/0; original imported cabinet/shelf probe 432/0 and workflow/render 612/0 | Sampled discovery; explicit categories/compartment intent; arbitrary proxies unqualified |
| Categories and rules | Workflow 162/0; regions 83/0; five-category gallery 49/0; actual Apply-button instructions | Regional exclusions constrain anchors; use obstacle volumes for physical keep-clear |
| Asset library | Library 6/0; appearance/WSM 156/0; original five imported models and six relocated maps | Portable libraries contain geometry/metadata; scene sources supply appearance |
| Seeded arrangement | Twelve native executables / 117 cases, unchanged valid goldens, complete pose/group equivalence and independent contact/bounds checks | Conservative upright bounds, bounded search and truthful underfill |
| Composition and refinement | Composition 52/0; row lifecycle 71/0; fresh book gallery 35/0 with six images; locks/selective regeneration and imported rerolls | Bounded row-height heuristic; relational dining/leaning/physics and general aesthetic judgment deferred |
| Scene integration and performance | Lifecycle 89/0, Preview 38/0, migration 60/0; cache 685/0, callbacks 233/0, boundaries 1182/0; two opposite-order performance runs 1109/0 each | Same-time numerical reuse, fresh source capture/solve; translated clones require unlock/Generate; background load uncontrolled |
| Artist delivery | Current quickstart, technical/API/calculation docs, portable imported scenes and fresh book scenes; exact package status in release ledger | Renderer evidence is Standard diffuse/Scanline; installation into the artist profile remains the artist's action |

The sixteen functional suites total 3,034 assertions; native, JSON, imported, render, performance and installer scopes are reported separately. [The 0.1.3 release ledger](RELEASE_VALIDATION_0.1.3.md) binds current identities and actual delivery status. [The technical overview](TECHNICAL_OVERVIEW.md), [imported examples](IMPORTED_EXAMPLES.md), [book examples](BOOK_ROW_EXAMPLES_0.1.3.md) and [measurements](PERFORMANCE.md) make the workflow reviewable. Previous milestones and their then-pending statements below are preserved history.

## Historical qualified 0.1.1 baseline evidence

The qualified baseline uses document schema 3: independent obstacle references/dependencies and an authored approach requirement supplement persistent regional policy. Furniture alone supplies regions and sampled clearance; the combined furniture/obstacle query enforces collision/access. Region semantics are the sole exclusion owner. The exact r3 archive passed isolated installation and startup; later source changes are not covered by those receipts.

| Matched evidence | Result and scope |
| --- | --- |
| `build/native-arrange-21/receipt.json` | Max 2027 SDK pair builds; all six CTest targets pass: 13 geometry, ten assets, 16 arrangement, 17 fit-query, four integrated and eight registry suites, **68 scoped native suites** |
| `build/host-final-21-inspect/receipt.json`, `json-validation.json` | **69 passes, zero failures**, plus independent strict JSON validation of five exported fixtures |
| `build/host-final-21-native/receipt.json` | **21 passes, zero failures** for native scene-owner/API integration |
| `build/host-final-21-workflow/receipt.json` | **147 passes, zero failures** for the complete recorded workflow and actual rollout handlers |
| `build/host-final-21-lifecycle/receipt.json` | **89 passes, zero failures** for dependencies, Manual/Live, native Undo/Redo, clone ownership, save/reopen and failure retention |
| `build/host-final-21-preview/receipt.json` | **38 passes, zero failures** for bounded transient previews, staleness/Live behavior and Preview/Commit identity/world-pose agreement |
| `build/host-final-21-regions/receipt.json` | **74 passes, zero failures** for persistent surface identities/metadata, regional policies, protected/selective behavior and surface-rollout handlers |
| `build/host-final-21-obstacles/receipt.json` | **78 passes, zero failures** for independent collision/front scope, protected retention, root/descendant references, Undo, Manual/Live, preview staleness, clones, persistence and collision-rollout handlers |
| `build/host-final-21-visual/receipt.json` | **83 passes, zero failures** with distinct authored normals at every face corner, mirrored/nonuniform transforms, both UV channels, material resolution, smoothing, explicit flags, source preservation and Undo/Redo/reopen |
| `build/host-final-21-library/receipt.json` | **Six passes, zero failures**: an independently encoded unsupported stack-top library rejects without changing catalog/revision/output nodes |
| `build/host-final-21-gallery/receipt.json` | **49 passes, zero failures** across five original furniture categories, deterministic IDs/complete poses, materials, authored quarter turns/full-size props, independent full-bounds fit/hole/contact oracles and scene staging/save |
| `build/host-final-21-render/receipt.json` | **Passed**: original saved five-category gallery, actual native Scanline overview and five detail images. This renderer-specific receipt does not qualify other renderers |

The ten final native21 functional host suites total **654 assertions**, all passing: 69 + 21 + 147 + 89 + 38 + 74 + 78 + 83 + 6 + 49. The 68 native suites, five independently validated JSON exports and six rendered images are separate evidence. The render run repeats the gallery's 49 generation checks; those are not counted twice.

The visual-03 normal fixture uses its recorded per-face normal values; equal corner normals could hide a mirrored normal-ID reassociation error. Strong visual04/native14 and diagnostic visual05/native16 each recorded **77 passes and six failures**, isolating a native mirrored-corner permutation while source/snapshot vertex orders agreed and nonmirrored components had no errors. Visual capture now maps saved normal IDs and specified bits through the geometry face's actual pre/post-flip vertex permutation. Strong visual06/native17 passes **83 / 0**, with all normal dots 1.0. Assertions were retained. The earlier failures remain preserved and do not indicate an inverse-transpose matrix error.

Gallery03/native16 passes after correcting the test-only child collection/conversion assumptions from gallery01 / 02. Its separately recorded Generate wall times are 36–353 ms initially and 45–309 ms on repeat for the five small gallery setups; Analyze takes 3–6 ms. The CSV also records Stopwatch timing and process-wide working-set/peak bytes before/after each operation. These include host capture, native solve, material/node publication and Undo in the already-running Max process; repeat generation still recaptures/reanalyzes and is not a cached-solver benchmark. Render01 produced one overview and five category detail PNGs using Scanline. Neither a timing sample nor generated images substitute for artist composition review or broader performance qualification.

All ten final functional receipts and the separate final render receipt match native21 and verify their recorded script identity, actual loaded paths/hashes for both modules and the private profile. Artist profiles are unchanged; these runs performed no artist installation or computer use. The complete matched final-pair functional collection has passed. Actual isolated r3 installation/startup now passes 43 / 0 and 12 / 0; its external qualification receipt binds the unchanged archive. These results do not extend qualification to later source/script changes or other renderers/assets.

Historical schema-2 baseline: `build/native-arrange-10` passes 58 native suites and its exact pair passes workflow-06 **147 / 0**, lifecycle-03 **89 / 0** and preview-03 **38 / 0**. These cover actual rollout workflow, full-precision seeds, source provenance, asset metadata, category rules, selective generation, native Undo/Redo, dependencies, zero-offset clone remapping, save/reopen, failure retention and Preview/Commit world-pose agreement. Earlier schema-1 native-05/host-native-02 evidence remains historical, not qualification of schema 3.

Diagnostic failures remain preserved: lifecycle-02 exposed two clone-remapping failures; workflow-05 stopped after a material Undo crash traced to a freed temporary `Multi*`, with separate harness assumptions also recorded. Immutable clone bindings and suspended Undo during transient material staging pass their native10 successor tests. Regions-01 exposed real uint32 text-rounding; per-digit integer parsing passes regions-02. Visual-01 stopped on a test-only Matrix3 transpose call; visual-02 exposed the missing Edit Normals modifier context, corrected before visual-03. Distinct corner normals then exposed the actual native permutation defect repaired and qualified by visual-06. These distinctions prevent either discarded failure evidence or overclaiming a later release.

Historical gallery failures also remain preserved. `build/host-arrange-gallery-01/receipt.json` records one pass and one test-only `NodeChildrenArray`/`Array` conversion failure. Gallery05/native18 and gallery06/native19 each record 47 passes followed by one camera/title staging API failure; those runs did not qualify scene saving/rendering. The repaired native21 final gallery passes 49 / 0 and its separate render receipt passes all six images. Earlier successful scopes remain recorded: native13 visual03 80 / 0, native17 visual06 83 / 0, native12 regions02 74 / 0 and obstacles01 78 / 0, native11 library-validation01 6 / 0, and native16 gallery03 48 / 0/render01 six images.

## Open functionality and explicit limits

Qualified 0.1.2 provides category filtering, weighted sampling, local clusters, metadata-defined stacks, individually generated book rows and bounded regional row-height balancing. Its exact native28 functional, migration, render and installer scopes passed. The earlier qualified 0.1.1 baseline lacks the book-row/balance feature. Relational dining place settings and broader visual-hierarchy optimization are deferred recipe extensions and are not implemented. Artist composition acceptance remains open; a successful count/collision test cannot substitute for it.

Qualified 0.1.2 Generate recaptures/reanalyzes furniture and rebuilds the precise query. Working 0.1.3 implements optional same-time geometry/query reuse, passive retained requested-byte accounting and phase diagnostics, but its host invalidation/lifetime, paired performance and delivery remain under qualification. No 0.1.3 speedup is qualified. Historical native16 gallery timing measures small end-to-end host operations; process working-set/peak values do not attribute solver allocations or renderer/viewport FPS. See [the current candidate ledger](RELEASE_VALIDATION_0.1.3.md).

Documented scope limits are distinct from missing implementations: categories/compartment labels are authored; support identity is conservative at fixed sampling/quantization and arbitrary geometry edits may require unlocking/regeneration; fit uses full-bounds accessory OBBs and may overreject concave props; contact/stability is not a rigid-body simulation; only explicitly bound furniture/obstacles collide; portable `.cyalib` stores geometry/metadata without renderer materials/UVs. Production proxies, renderer combinations and large admitted scenes require separate qualification. Automatic mesh recognition, learned aesthetics and a rich portable renderer-asset format are not claimed by the qualified delivery or working candidate.

## Historical 0.1.1 selection and engineering contract

The following records the original milestone choice and contract. It was later qualified as 0.1.1-r3; its former future tense is not a current pending-release status.

**0.1.0 -> 0.1.1**, selected before changing metadata. This independent product follows the next development step. Its impact is substantial: asset registration, a seeded placement engine and persistent native scene documents replace the inspector-only workflow. Scene document schema 3 and library format 1 are new independent domains. Old 0.1.0 receipts/packages remain immutable; no migration or compatibility promise is introduced. Other Cyrus products keep their versions.

Native scene documents own immutable authored settings, asset snapshots and placement records. SDK reference containers own furniture, asset-source and output dependencies; a custom attribute on an ordinary setup node owns the document. Numerical work consumes copied mm geometry, never host pointers. UI only issues bounded authored commands and reads bounded summaries.

Relevant source/setting changes mark the document dirty. Manual mode retains published output until an explicit update. Live schedules work on the host thread after notifications complete; selection/browsing must not solve. Complete staging precedes scene publication. Native restore objects and SDK references participate in one Undo transaction. Failed successors preserve the previous complete state/output and expose diagnostics. Save/reopen reconstructs native records and references; no session pointer is serialized.

Peak ownership includes previous/current document states, staged copied source geometry, polygon unions, solver proposals and staged output; admission bounds assets/triangles/cells/candidates/work and placements. Undo retains shared immutable states plus scene-owned nodes. Resource limits are not a measured process-RAM guarantee. Precise fit queries use 0.001 mm integer polygons and conservative oriented bounds, not just inspector cell centers. Full accessory meshes remain stored for output and future tighter collision refinement. Only explicitly selected furniture/obstacles belong to collision scope.

The development-only document first advanced from 1 to 2 for explicit asset source provenance, authored support flags, editable category rules and persistent surface registries, then to 3 for independent obstacle count/references and the authored approach requirement. Old internal schema-1 / 2 test scenes are not migrated; the qualified 0.1.0 inspector did not own these native documents. No released artist scene is rewritten.

Preview stores bounded native wire boxes plus an immutable staged surface registry; it does not create output nodes or change authored document revision. Commit requires unchanged dependencies and reuses the staged region identities. Preview disarms Live until explicit Generate/Commit. The cache admits eight previews, 80,000 boxes and two million canonical surface cells in total; preparing a successor can temporarily retain previous and next data.

## Acceptance sequence

1. Native asset/solver/query tests, including narrow holes, concavity, subcell obstacles, body interiors, containment, rotated bounds, stacking and deterministic regeneration.
2. Max SDK build and isolated host tests of registration, generation, failure retention, Manual/Live, locks, preview/commit, Undo/Redo, clone and save/reopen.
3. End-to-end UI tests and representative TV console/open shelf/table/counter scenes using original procedural accessories.
4. Independent source/native/script identity verification and an exact matching MZP; installer payload and isolated execution qualification. Artist installation is separate and is not performed automatically.

## Sources used for native fit queries

- [Clipper2 official overview](https://angusj.com/clipper2/Docs/Overview.htm): integer polygon Boolean operations.
- [Clipper2 official offset documentation](https://www.angusj.com/clipper2/Docs/Units/Clipper.Offset/Classes/ClipperOffset/_Body.htm): union contours before offsetting.
- [Autodesk Max 2027 CustAttrib API](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_cust_attrib.html): native attribute ownership.

Clipper2 is vendored from the existing licensed repository copy at pinned upstream commit `f9c5eb6e14a59f6f5d65fbfb3564519a561cf4fd`; original upstream checksums and the Boost license accompany the code. The 0.1.3 development branch adds three narrow exception-ownership repairs recorded separately in [LOCAL_PATCHES.md](../third_party/clipper2/LOCAL_PATCHES.md). No artist assets were downloaded.

## Historical 0.1.1 installer successor evidence

The first actual MZP run (`build/installer-qualification-01/receipt.json`) failed before configuration publication because a .NET directory result had converted to a MAXScript array and did not support `.Length`. The failed archive at `dist/CyrusArrange-0.1.1` remains preserved unqualified. The revised installer used `.count`, explicit failure-stage assertions and missing-parent cleanup tests, preserving the frozen native21 functional runtime. Deployment-only changes followed [qualification scopes](QUALIFICATION_SCOPES.md) and required fresh installer/startup evidence; the successful r3 result is recorded below.

The second installer run (`build/installer-qualification-02`) failed to compile before execution because a rollback catch contained an argument-bearing throw. Its `dist/CyrusArrange-0.1.1-r2` archive remains unqualified. The r3 successor recorded the retained-directory failure directly, with the same frozen native21 functional runtime, and passed 43 actual installer and 12 automatic-startup checks. Its external `dist/CyrusArrange-0.1.1-r3/qualification-receipt.json` binds that immutable archive; it does not qualify later source.

## Historical selection of 0.1.2 — now qualified

This selection record and the integration history below precede the final native28 delivery. Pending statements describe those earlier stages; current delivered status is recorded in the final section and [release report](RELEASE_VALIDATION_0.1.2.md).

Selected before changing version metadata: **0.1.1 -> 0.1.2**, the next development step for this independently versioned product. Add individually generated upright book rows for TV consoles/open shelves and a bounded optional row-height-balance pass. This is a substantial composition change despite the small version step: native relationships, whole-row locks/removal, new asset intent, controls and persistence are required. Keep Placement records, existing public array shapes, registry schema 1, native class IDs and reference slots stable.

Document writes advance from schema 3 to 4 and portable library writes from 1 to 2. Explicit readers preserve the delivered schema-3/library-1 baseline in memory with rows disabled, empty groups and absent row profiles. Loading does not generate, bump authored revisions, arm Live or overwrite old files; an explicit save writes the current format. Internal document schemas 1 / 2 and unknown future schemas still reject. This is a narrowly justified supported-baseline reader, not restoration of retired internal formats.

Authoritative ownership, bounded memory/work, invalidation, atomic failure retention and Undo follow [COMPOSITION_DESIGN.md](COMPOSITION_DESIGN.md) and foundation contracts F02/F05/F06/F07/F08. Root owns bridge/UI/publication; parallel agents own numerical composition/query checks, asset/library codec, and native document persistence/lifecycle. Fresh native, migration, Max/UI/lifecycle/render and exact-package evidence is required. The qualified 0.1.1 MZP, source archive, scenes and receipts remain immutable. Geometry/query reuse is a subsequent performance milestone; no cache speedup is claimed.

### Historical 0.1.2 integration progress — native22 to native25

`build/native-arrange-22/receipt.json` passes the full Max 2027 SDK build and nine CTest targets, containing 90 reported suites. The added scopes include ten composition suites, a golden suite with six immutable 0.1.1 scenarios, and eight portable document-codec suites. The balance tests witness legal row translation and independently measure the defined height profile; a review-discovered cell-order dependence was fixed using a canonical minimum support height.

`build/host-migration-01/receipt.json` passed 60 / 0 on native22: exact old gallery/library loading, preserved five setups/35 props, default-disabled metadata, current-format SaveAs/reopen, repeated old pose records and unchanged source bytes. `build/host-composition-01` recorded a test-only 0 / 1 failure before its first fixture: future fileIn-defined helpers were not explicitly declared global. The declarations were corrected. At that stage, successor row workflow/lifecycle and installer qualification were pending; the later native28 release completed those separate gates.

Subsequent scoped runs are tracked in [0.1.2 release evidence](RELEASE_VALIDATION_0.1.2.md): native23 row lifecycle passes 71 / 0, native24 row/UI workflow passes 52 / 0 after correcting group-helper measurement oracles, and native25 gallery passes 35 / 0 with actual scenes/renders and a measured balance translation. Native25 inspector passes 69 / 0 plus five strict JSON exports. These exact runs remain preserved; they are not final qualification of later source.

An independent procedural review reproduced an ordinary-cluster region-policy defect against native24 and identified post-allocation round-offset admission. At that stage, narrow C++ corrections and independent regressions were in progress, with final-pair, serial performance and installer gates pending. Some old permissive-query golden scenarios contain invalid out-of-region anchors; their immutable data remains evidence rather than a demand to preserve the defect. The subsequent repairs retained exact unaffected checks and explicitly recorded legitimate correction differences, as described below.

### Historical correctness and benchmark follow-up — native26 to native27

Native26 passes the full SDK build and nine CTest targets / 92 reported suites with both narrow numerical repairs. Its actual regional host run passes 83 / 0, including 64 excluded/masked-neighbor seed cases and unchanged locked successors; the exact old gallery/library migration passes 60 / 0. The immutable old golden remains unchanged, with explicit corrected-invalid-output expectations and exact checks on all unaffected poses.

`build/host-performance-01` completed all 86 commands and passed 291 in-host equivalence/physical/UI assertions. Independent inspection found a CSV formatter defect: .NET selected a narrow numeric overload for MAXScript Integer IDs, corrupting recorded process ID and some node handles. The files and passed host receipt remain scoped evidence; the run is **not accepted as complete benchmark evidence**. Native27 added explicit integral formatting, a large-ID regression and independent validator rejection of invalid PID/handles. Its successor measurements and final functional collection were pending then and were later completed by native28. Other projects had Max processes open during the first measurement; no idle-machine or cache-speedup claim applies.


## Qualified 0.1.2 and selected next milestone: 0.1.3

The exact native28 0.1.2 archive is qualified at `dist/CyrusArrange-0.1.2`: nine native CTest targets / 92 cases, thirteen final functional Max suites / 846 assertions, five independent JSON exports, 292 separate performance assertions, 35 separate book-row gallery checks, six actual Scanline images and private installer/startup checks 43 / 12. These are distinct scopes, not one pooled test count. One earlier final lifecycle startup exited before assertions with undetermined cause; its same-source retry passed. See [the final release report](RELEASE_VALIDATION_0.1.2.md). The MZP and matching 89-input source/examples archive are immutable; the full-system goal remains active.

**Selected before any version metadata change: 0.1.2 -> 0.1.3.** This independently versioned performance/reliability milestone adds same-time reuse of owned furniture inspection and immutable fit-query data, exact dependency validation, bounded native retention and phase diagnostics. Preserve all placement/recipe behavior, document4/library2/registry1, public existing array shapes, class identities and reference slots. Geometry-only reuse never authorizes stale support, skips current asset/region-policy validation, publishes a partial result or rearms Preview-disarmed Live.

Working 0.1.3 source now contains passive query accounting, the native cache service, input-observation/lifetime handling and phase diagnostics. Qualification must still prove cold/reused complete poses, groups, stats, full geometry and Preview/Commit on the exact source. Invalidation includes newly added descendants, object offsets, topology, WSM evaluation, time/units, Undo/Redo, load/merge/clone and owner deletion. Mandatory native observation is separate from optional numeric retention; stale successors must cancel before transaction acceptance. Cache failure must leave a valid cold path. Preparation versus whole-command effects and retained requested bytes versus Max/history memory require separate measurement; implementation alone is not evidence of speedup.

Root owns bridge/version/build/host orchestration; geometry agent owns passive query accounting/tests; SDK agent owns cache/document epochs, lifetime and pure tests; test agent owns a bounded Max equivalence/invalidation suite. Work follows [the cache implementation plan](CACHE_IMPLEMENTATION_PLAN.md), primary SDK/SideFX evidence and actual host validation. No 0.1.3 speedup or delivery is qualified yet.

Early 0.1.3 diagnostic history: native29 passed eleven targets / 110 reported cases, but its first real Max cache-prerequisite and existing-workflow runs rejected unchanged input during analysis/capture. Optional reuse remained disabled at that stage. Failed receipts remain preserved with bounded notification and exact-key diagnosis. Later fixes and their current qualification status are recorded in [the candidate ledger](RELEASE_VALIDATION_0.1.3.md); a native test pass alone does not qualify this host candidate.
