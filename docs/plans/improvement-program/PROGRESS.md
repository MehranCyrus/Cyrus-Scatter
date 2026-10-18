# Remaining improvement program â€” execution ledger

Active program objective: [complete user objective, activated 17 October 2026](OBJECTIVE.md). It resumes the native migration and all named remaining roadmap areas. The earlier 15 October objective remains in that document as history.
Baseline: `b23ed93f97af347b98b92b355660bdc3eeb0ef19`, branch `codex/workflow-0.75`, delivered Scatter 0.82.6. The user explicitly resumed Phase 6 for this program. Work begins with presets; no later feature is complete by enrollment.

## Current delivery

18 October 2026: finish the **0.86.0 native migration**, test in private Max 2027
profiles and supply MZP/EXE installers without installing. The native-only
controller, compact CS Edit history, native system-commit admission and bounded
output consumers are implemented. No later roadmap feature is being added.

The [delivery report](../native-placement/DELIVERY_0860.md) is the current
acceptance authority. Frozen pair 11 passed the final matrix and mixed-history
soak (3602.9 seconds / 60 complete cycles). Exact-pair MZP/EXE installers are ready for user testing;
neither has been installed. N01–N09 is complete within the report's stated scope.
The [execution history](../native-placement/EXECUTION_0860.md) preserves earlier
tests and the cache/Undo defects they exposed; they are not final-pair receipts.

The [active objective](OBJECTIVE.md) authorizes the remaining roadmap after this
coherent delivery. P01–P07 and supported P10 work are already implemented. N01–N09
identify the native migration, not nine additional artist features. 0.85.4 is
the preceding delivered pair; 0.86.0 changes ownership/transport/history while
preserving schema 58, registration identities and slope/altitude behavior.

## Original phase status

P numbers identify the original eleven product outcomes. I numbers identify the
Forest-informed improvement items; PG numbers identify gallery work. They are
independent of release numbers. **P06 is complete for its declared scope.**

| Original phase | Implemented delivery | Remaining scope |
| --- | --- | --- |
| P01–P05 | Workflow/feedback 0.81.8; settings presets 0.81.9; slope/altitude 0.82.0; density-map channel/resolution 0.82.1; Paint/spline conversion 0.82.2 | Original receipts retain their tested scope; general artist acceptance remains separate |
| P06 / I06 — regular grids | [0.85.0](I06_0850.md): Rectangular, Staggered and Hexagonal | Broad production acceptance remains separate from scoped qualification |
| P07 / I04 — orientation | [0.83.0](I04_0830.md): direction/target controls and normal blending | Broad production acceptance remains separate |
| P08 / I07 — direct paths | Pending | Arc-length spacing, repeating sequences/gaps and reference placement; existing Spline Bands remain a separate implemented feature |
| P09 / I08 — transform/assignment maps | Pending | Scale/rotation maps and map-driven model choice; existing density masks/maps remain implemented |
| P10 — recipes/library | Static core 0.82.5, browser 0.82.6.1, variation 0.84.0, grid/orientation fields, gallery/assets 0.85.1 and ready loading 0.85.3 | Future P08/P09 fields, PG09 broader adapters, PG10 authored Edit/effects and final production acceptance |
| P11 — adaptive viewport/performance | Existing 0.81.6/0.81.7 adaptive limits/reuse, 0.82.3/0.82.6 responsiveness and 0.85.4 Count-memory improvements | Full final-layout/map/asset performance and lifecycle matrix |

I03–I06 have delivered checkpoints. I15/PG01–PG08 have a supported static-asset
subset; PG09 is partial and PG10 depends on I13/I14. I07/P08 is the next pending
roadmap feature after native foundation qualification. N01–N09 implementation
is now authorized by the [active objective](OBJECTIVE.md); the separate Physics
Lab still does not establish integrated Scatter physics.

Historical implementation checkpoints I03 `f030fb3`, I04 `a814513`, I05 `f2bc8dd`
and I06 `9f8cc15` were recorded as pushed in their original receipts. Current
documentation/knowledge checkpoint is `c1290d0`; reviewed plugin implementation
checkpoint is `7379ea3`, pushed with the remote ref verified. Unrelated local
work remains preserved. Read actual Git state before further edits.

Contracts: F01, F04-F08, F09-F11. Native library scans operate on copied filesystem paths and metadata only, never Max scene objects. Explicit Refresh rereads content, even for same-size/same-time file replacement. Browsing never hydrates Paint. Search/page operations use the bounded in-memory index; no filesystem polling while idle. Thumbnail loading is explicit for the selected entry with byte/pixel bounds and resource disposal.

First version rationale: user-selected four-part development label 0.82.6.1 for the preset/browser follow-up. Scene schema/evaluation contract stay unchanged unless a reviewed authored-data change requires otherwise. Native capability and recipe-format decisions are recorded with implementation. Analyzer/MCP remain independently versioned.

## Required outcome ledger

| Item | State / next evidence |
| --- | --- |
| I03 browser/search/tags/thumbnails and clear preflight | Implemented and scoped Max 2027 qualification passed; see I03 handoff; physical artist acceptance remains |
| At least eight usable presets and accurate thumbnails | Eight delivered and exact-pair round-trip tested through 0.85.4: original six plus Four garden rooms and Valley moss and rocky crests; see current memory/preset receipts. A direct path example remains dependent on I07 |
| I04/P07 direction and normal blending | Implemented and scoped Max 2027 qualification passed; 0.83.0 package ready and commit `a814513` pushed; physical artist acceptance separate |
| I05 copy/import variation policy | Scoped-qualified and MZP ready in [0.84.0](I05_0840.md); commit `f2bc8dd` pushed and remote verified; B26 heavy Undo remains open |
| I06/P06 rectangular/staggered/hex grids | Scoped-qualified and MZP ready as [0.85.0](I06_0850.md); `9f8cc15` pushed and remote verified |
| Preset/gallery PG01–PG10 supplement | [Detailed plan](../preset-gallery-improvements/README.md), [performance/Max 2027 acceptance](../preset-gallery-improvements/VALIDATION.md) and [TODO](../preset-gallery-improvements/TODO.md) implemented for PG01–PG08’s declared subset in 0.85.1, with ready loading in 0.85.3; PG09 partial and PG10 gated; see the [historical candidate ledger](../preset-gallery-improvements/PROGRESS_0851.md) |
| I07/P08 paths/sequences/references | Pending; arc-length and seam/identity contract |
| I08/P09 transform and assignment maps | Pending; shared samples and final-radius acceptance |
| I09 shared terrain snapshots | Pending profiling trigger; record decision and extraction/memory evidence |
| I10 finer intermediate-result reuse | Pending profiling and dependencies; preserve masks/spacing/publication |
| I11/P11 adaptive viewport/lifecycle | Pending final feature matrix, heavy assets, memory and actual host evidence |
| I12 UV patterns/projection | Pending; domain/seams/overlap policy and numeric oracle |
| I13 authored Edit/radius recipes | Pending; exact authored correspondence and transactional transfer |
| I14 typed effects | Pending; bounded ordered operations and dependency rules |
| I15 asset packages | 0.85.1 implements/tests a closed static mesh/Standard/PNG adapter, dependency manifest, transaction/rollback and explicit scene reuse. Arbitrary proxies/shaders, XRefs and nested variants remain open |
| I16 source animation/LOD | Pending; copied samples, time validity, bounded cache and renderer scope |
| I17 renderer adapters/edge trimming | Pending; explicit supported renderer/version/material/source matrix |
| I18 bounded expressions | Pending I14; grammar/types/units/fuel and failure retention |
| Max 2027 MZP for every delivered version | 0.82.6.1, 0.83.0, 0.84.0 and 0.85.0 archives verified; not installed; continue for subsequent deliveries |
| Final EXE with presets/thumbnails/demo content | 0.85.4 unsigned EXE and MZP are compiled and payload-verified with eight example sets; preceding owned 0.85.1 installer lifecycle witnesses retain their original scope. Artist/fresh-recipient acceptance and full-disk/ACL/network limits remain |
| Final docs, Git remote, supported matrix and user checklist | Pending complete program; per-delivery checkpoints required |

## Preservation and qualification

Unrelated pending work: landscape row in docs/README.md, LOGO.psd, Landing Page Design/, docs/plans/landscape-presentation/, presentation-studio/, website/prototypes/. Preserve these. Artist scenes/profile/installed modules are untouched. Use owned Max 2027 profiles only; no Max 2026, website deployment or external distribution.

At program enrollment the knowledge index was stale. The [17 October repair](../../../tools/rag/KNOWLEDGE_REPAIR_2026-10-17.md) subsequently activated a fresh reviewed successor; check current status rather than reusing that historical stale observation. Original 0.82.6 hashes and receipts remain historical. At enrollment no new host/native pass was claimed. Subsequent I03 progress is recorded below.

## Resume here

Read the current delivery and phase table above, the actual Git state and the
user's current instruction. The active goal resumes N01–N09 first, then I07/P08
paths and every remaining original/advanced area in OBJECTIVE.md. Follow the
native execution handoff for the next dependency-ready work. Preserve completed
P01–P07, historical receipts, unrelated files and B26's open
limits. The dated execution entries below record past tasks and intermediate
failures; they are not current authorization or current qualification.

## I03 implementation evidence â€” 16 October 2026, active candidate

- Added native file-only Library worker with bounded 10,000 recipe / 100,000 directory-entry / estimated 32 MiB metadata admission, 128-row pages, Unicode-aware case folding, explicit refresh and cooperative cancellation (Windows synchronous-I/O cancellation request). Search/page reads use copied metadata; no Max APIs or Paint sidecar reads occur in the worker.
- Optional `.csrecipe.json.library.json` presentation sidecars bind to exact manifest SHA-256. Recipe format 1, scene schema 58 and Paint codec remain unchanged. Category/tags/description are bounded; selected PNG thumbnails use hash/byte and 1024-pixel/2-MiB bounds. Damaged or stale optional metadata warns without silently replacing authored recipe data.
- Native build `build/library-08261-20261016-01/native-01`: configure/build passed; **34/34 suites passed**, including new recipe_library_tests. Tests exercise passive metadata, tag/category search, page limits, cancellation, stale tokens, byte limits, corrupt thumbnail records and unchanged-size/time file replacement.
- Generated candidate checks passed (281 semantic controls); **165 Python tests passed**, including four-part package version parsing. Interpreted browser template then received an error-message-only compile repair; final script qualification remains pending.
- First owned profile `foundation-roadmap-library08261-20261016-01` rejected a custom `throw` inside a MAXScript catch expression. Fixed by retaining the error and throwing outside catch. Verified PID 20080 belonged to that profile before stopping it. Fresh profile `foundation-roadmap-library08261-20261016-02` launched as PID 54668; inspect launch/readiness and active request before continuing. Artist Max remains untouched.
- Current authoritative UI template has search, categories, thumbnail preview, content/role summaries, explicit Refresh/Cancel and shared access to existing Amount/Transform settings presets. Actual host UI, large-library performance, preset demos, packaging and Git delivery are still pending. No delivery/completion claim yet.

### Successor evidence and current continuation

- Native successor `build/library-08261-20261016-01/native-02`: **34/34 suites passed** (11.52 s). Adds explicit Max shutdown / LibShutdown worker teardown before DLL unloading and case-insensitive recipe filename suffixes. Native inputs have not changed since that build. Scripts subsequently received presentation-only fixes; launch receipts pin each actual pair separately.
- Main campaign `foundation-roadmap-library08261-final100-20261016-04` passed actual Save, search, Add, thumbnail decoding/reuse/corrupt-image fallback, cancellation/close/reopen, unsupported-controller owner explanation, missing-role rejection and deleted-owner guarding. Complete placement fingerprints and receiver-cache, solve, map, preparation and upload counters stayed unchanged during browsing.
- Local library measurements (30 searches each): 128 entries median/p95 **4.42/22.50 ms**; 2,000 **41.95/78.77 ms**; 10,000 **50.07/81.21 ms**. Explicit scan-start handlers were 16.84/4.45/18.34 ms respectively. These are local fixture measurements, not presented FPS or network guarantees. The 10,000 admission cap reports the limit; a later invalid file can be outside admission.
- Four procedural examples are generated in that host's `bundled/`: meadow (2,600/140/350), woodland (90/340/1,500), mountain (454/3,230), and painted spline borders (1,740/218 accepted rows by layer). Each has a matching editable `.max`, complete recipe and actual accepted-placement thumbnail. All four passed exact full-row scene reopen and exact authored-document recapture through the Save Everything UI, including Paint bytes.
- All four passed native MAXScript New setup / Undo / Redo / explicit Update. The initial Python Undo attempt ran inside an undo-off preparation context and is not an Undo witness. Its failed receipt is retained. Native `demo_apply.ms` begins outside an enclosing hold; the later border rerun starts with hold=false and passes without fixture recovery. A private-only recovery/reload path is explicit when Python preparation left a hold active. Product import code was not changed to bypass its hold guard.
- Shutdown while an actual 10,000-file worker was active completed in **5.28 s** in the main owned host. `shutdown-result.json` records observed process exit; OS exit-code retrieval returned null, so no numeric exit-code claim is made. The fixture uses Autodesk's [documented quitMAX](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Miscellaneous-Functions/GUID-92E4150E-0AD4-430C-A852-783A45276D23.html). Artist and unrelated Max processes were preserved.
- Native ComboBox test events must include committed `CBN_SELENDOK`; the earlier single-entry category check did not establish filtering. A mixed four-category library now passes actual committed selection and restoring All categories. Bundled browsing preserves work counters; passive listing succeeds with a damaged Paint attachment while explicit full read rejects it.
- `AminScatter/library/` now stages four examples and their hash-pinned inventory. `.max` files remain ignored and must be regenerated/staged from qualified receipts in a clean checkout. Packaging is being extended to include only the inventory's permitted files, in immutable `Library-<version>` folders. My recipes remains separate. This is not yet a delivered package or installer-execution pass.
- At 150% Max UI scale, measured bounds and overlap checks passed. Visual inspection prompted a wrapped, scrollable summary and Windows line endings. The current final-script candidate is **580d3446773c85d91fd276a70d8e10e2e0c5de1bcc95b1deb056bc82c62be56b**. `generated-final` passed; **166 Python tests passed** (12.12 s), including bundle inventory/hash/path guards. Physical 4K/mixed-monitor DPI remains unqualified.
- Active host: `foundation-roadmap-library08261-final150-20261016-04`, PID **44208**, native-02 and the final script above. Recheck the latest correlated request before continuing. Prior owned hosts were stopped after identity verification or exited; failed startup/compile receipts remain. Do not touch artist PID 15780 or the unrelated camera task's host.

### I03 final checkpoint

The preceding next-action paragraph is superseded: final script passed fresh 100% and 150% layout checks, actual Save/Add, bundled selection/category filtering, Unicode, offline cancellation, denied-write preservation, sixty Live open/scan/decode/close cycles and 30.75 seconds idle. GDI/USER counts stayed flat over the final fifty cycles; private memory rose 7.42 MiB after collection. The final-script Paint-bearing scene passed exact authored recapture and New setup/Undo/Redo. The fixture's private Python-hold recovery remains explicit; product hold guards are unchanged.

The exact 2,700,903-byte MZP is `dist/CyrusScatter-0.82.6.1-20261016/CyrusScatter-0.82.6.1-Max2027.mzp`, SHA-256 `5a53a468b324d4f5aaff0e5e9a807700846cfea85fbb72e1d0af7cd5282fee0a`. Installer syntax compiled in Max without invoking it; archive guards, inventory and payload hashes passed. No installation/restart of the artist host occurred. See the frozen I03 handoff for the complete scope and limits.

Artist guide, installation/build instructions, architecture, current navigation/backlog and curated website content now describe I03. Website docs:sync, docs:check and local build passed (existing large-chunk advisory retained); nothing was deployed. Commit `f030fb3` is pushed and verified. Final owned hosts 44208/49052 exited after guarded quitMAX; close markers exist. Their request waiters time out because process exit precedes a completion reply; observed exit, not timeout, establishes closure. Only artist PID 15780 and unrelated camera-task PID 42536 remained at verification. I04â€“I18/P06â€“P11, the remaining examples and final EXE remain incomplete.


## I04 integration â€” 16 October 2026, not delivered

- Added native Random/World direction/Look at target frames and 0â€“100% spherical normal blending. Canonical random rows and immutable geometric-normal snapshots are cached per receiver. Orientation follows movement/Relax and precedes source transforms/Edit/radius/acceptance. Default core comparisons cover 1,500 full transforms; final-face alignment after Relax is an intentional correction.
- New lazy Transforms controls and captured-owner handlers are generated from authoritative sources. Scene schema 58 gains an appended parameter block. Recipe/settings formats and capabilities advance to 2; strict, narrow format-1 reads supply the previous orientation defaults. Complete recipes store the target as an external role; numeric presets preserve the destination target. Historical data/receipts remain unchanged.
- `native-core-02` passed tests but its receipt was rejected because source inputs changed during the build. `native-core-03` passed the corrected native core. Integrated `build/orientation-0830-20261016-01/native-integration-04` passed **35/35 suites in 10.67 s**. Generated checks cover 288 controls; **166 Python tests passed in 12.65 s**. Subsequent script-only publication repair still needs final checks and a final exact-pair receipt.
- Owned host `foundation-roadmap-orientation0830-20261016-01` (PID 56292, now closed via guarded script; process absence verified) passed two-receiver mathematical oracles, direction/blend/target candidate reuse, full save/reopen and recipe round trip. Missing-target/zero-vector tests initially expected an exception; Update intentionally retains rows and reports preview status. The corrected fixture verifies that status, unchanged epoch and full row hash. UI fixture initially attempted the dropdown's `selected` property as a callable; the corrected fixture commits actual ComboBox notifications. Actual controls, Manual pending publication and owner switching passed.
- Animated target Live publication reused candidates/normals, but the idle check exposed repeated candidate-validity queries. The new orientation timestamp was not included in leaf publication state. Added it to staged install and rollback snapshots; also release the new normal/candidate caches when the scene retires. Successor host `foundation-roadmap-orientation0830-20261016-02` (PID 29796) loads the repaired script with unchanged qualified native modules; its launch receipt records both build-time and loaded script hashes. Core qualification passed again. Continue actual UI/animation/idle checks here.
- Required open acceptance: animated-frame idle after repair, target parent/deletion/inactive references, normal/heading animation, native Undo/Redo, existing schema-58 examples and format-1 reads, complete orientation recipe import, final radii/spacing, heavy terrain timing/memory, 100%/150% layout, final checks/docs/MZP/Git. No 0.83.0 installer or delivery claim yet.


### I04 final successor â€” qualified and packaged, Git checkpoint pending

- Native `native-integration-05` passed 35/35 suites (9.27 s). Final generated script `8ed01163ebd88909bb7ce34aaffd24ff10232d13705a0c60dfa32468e8b32eb1` passed 288-control generation; 166 Python tests passed (12.00 s), with 12 focused catalog/package tests after documentation updates. Exact loaded final pairs: `foundation-roadmap-orientation0830-final100-20261016-06` (PID 54944) and `foundation-roadmap-orientation0830-final150-20261016-07` (PID 25900). Verify lifecycle/process state before further host actions.
- Successor target classification excludes target geometry and pivot-preserving rotation from placement work. Exact numeric orientation keys avoid MAXScript string-rounding collisions. Relevant target notifications also rearm time validity even when the current pivot does not change, so newly added animation keys take effect. Earlier native05/script host03 exposed that missing rearm; final hosts pass it. Orientation timestamp installation prevents repeated animated-idle candidate-validity queries.
- Final target/parent/normal animation and inactive/unrelated cases passed; Live target deletion retains complete publication. Animated target idle 34.00 s and normal-blend idle 47.85 s showed no scatter/preparation/upload work. Actual UI Manual/Update/owner switching, native Undo/Redo and format-2 import passed. Four existing schema-58 scenes and v1 recipes recaptured every authored field and Paint byte without rewriting original recipe files.
- Heavy two-layer fixture: 60,000 rows / 180,000 faces, eight warm blend edits median 1105.22 ms, maximum 1396.83 ms (nearest-rank p95 of only eight samples). Candidates/normals and full unchanged-layer rows are reused. Two normal snapshots retain 8,640,000 bytes and release after reset/GC. Converted mesh Auto Radius and independent pairwise spacing checks passed; the earlier Pyramid-class fixture correctly failed the existing unsupported-source guard.
- Thirty settled Live Transforms open/close cycles with 60,000 rows: median/p95 65.88/106.94 ms; complete row hashes, calculations, preparation and uploads unchanged. The 34.19 s subsequent idle check passed. First idle fixture included a deferred Live activation update; its failed receipt is retained. The corrected gate begins after activation and excludes redraw counts only.
- Final 100%/150% bounds, overlaps, text wrapping, enabled states and owned-window visual captures passed. Nested Qt ancestor scrolling exposed the actual lower Transforms controls for inspection; blank/offscreen earlier captures are not claimed as visual passes. Physical 4K/mixed-monitor/picker-input qualification remains separate.
- MZP: `dist/CyrusScatter-0.83.0-20261016/CyrusScatter-0.83.0-Max2027.mzp`, 2,723,264 bytes, SHA-256 `8bc617ce27704aaed63e0299de4c7ca54de55f02bbbc55d04906899e8539e375`. Archive integrity, guard/payload/inventory hashes and actual Max compilation of an uncalled installer passed. It is not installed. Team licensing remains intact. Thirty-seven frozen evidence records are in QUALIFICATION_0830.json.
- Current artist/architecture/version/roadmap/capability docs and curated website content were updated. Website docs:sync/docs:check/local build passed, with the existing large-chunk advisory. Nothing was published. The gallery's historical 0.78.3 workflow provenance is retained separately from development version 0.83.0.
- Earlier owned orientation hosts 56292, 29796, 42840 and 45300 are closed. Guarded quit request waiters time out because exit precedes transport acknowledgement; process absence establishes closure. Artist PID 15780 and unrelated camera-task PID 42536 remain untouched.

### I04 Git and host closure checkpoint

Implementation `a814513b3cb1d99640fe5b5c9886dcfc95c73a77` is pushed and verified remotely. Final owned orientation PIDs 54944 and 25900 exited after guarded quit; closure markers exist and process absence was observed. Only artist PID 15780 and unrelated camera-task PID 42536 remained. The package/qualified pair is frozen. I05 source audit has started; no I05 product code or 0.84.0 package exists yet. The knowledge search for `procSamplingSalt` returned no hits in the old generation, so current original source is the evidence.

### I05 candidate implementation â€” not delivered

- [Contract and baseline](I05_VARIATION.md): owned 0.83.0 Max Copy/Instance observation confirmed independent copies and intentional instances. Native cloning retains owner-local IDs in independent graphs; no clone callback change is justified. Named layer copies get fresh owner/Edit/correspondence IDs while retaining or regenerating separate receiver random domains.
- Candidate 0.84.0 appends `procReceiverVariationIDs` without changing existing schema-58 parameter IDs. Same variation is the named-copy default; New variation is the recipe-import default. Numeric Amount presets expose Saved / Current / New seed, accurately distinguished from complete receiver variation. Copy now preserves the Paint Area settings previously omitted by its manual subset and uses an explicit held transaction.
- Complete recipe format/capability 3 adds the domain field (235 settings). Strict v1/v2 reads derive domains from original receiver IDs before ownership remapping. Numeric settings format remains 2. Save enrolls bounded correspondence metadata without intentionally evaluating terrain. Actual host work counters must confirm that boundary.
- `build/variation-0840-20261016-01/native-01`: **35/35 native suites passed**, 9.26 s. Generated check: 289 semantic controls. Python: **166 passed**, 12.57 s. Layout generator tests passed from `AminScatter/`; an earlier wrong-working-directory invocation failed before testing. These are offline passes, not host qualification.
- Host core-02 rejected a chained .NET method call during MAXScript compilation; split into a stored GUID and `GetHashCode`. Host core-03 then exposed Max's `copy #()` returning `OK`; use the already-copied parameter array directly. Core fixture indexing syntax was corrected separately. All failed receipts are retained. Native bytes remain unchanged; subsequent launch receipts pin each actual script/native pair.
- Baseline PID 52640 and core-03 PID 44248 closed by guarded quit; core-02 PID 4464 stopped only after checking its failed owned startup command. Core-04 PID 51076 exited during startup without readiness or diagnostic; this is not a pass. Current retry core-05 PID 22924 is launching the corrected script. Artist PID 15780 and unrelated PID 42536 were preserved. No 0.84.0 MZP, commit or delivery exists yet.

### I05 host progress and outstanding memory boundary

- Core-05 passed Same/New copy, fresh identities, all eight placement fields, exact Paint bytes and additional Area settings, native Undo/Redo without rerolling, Add/New setup, numeric seed policy, failure retention and save/reopen. The first older-example check then caught Save initializing unrelated root correspondence/curve defaults. Split bounded correspondence enrollment from curve initialization and restrict capture enrollment to actual placement layers. Core-06 reran the full matrix successfully.
- Core-06 passed saving before the first Update: future domains are frozen with no new receiver sampling, normal extraction, preparation or publication. Original root/curve data stays unchanged. The initial fixture assumed preparation started at zero; its receipt is failed, and the corrected before/after counter witness passes. Native Max Copy/Instance ownership and complete rows also pass.
- All four delivered examples preserve every root/layer/Area setting and native Paint payload; complete placement hashes match the frozen 0.83.0 receipt (`f55e866b93d4832d007abbdf94e003fc95d5c20fd41d6f3585a3192e3a0b6c3f`). Original files are not rewritten. A first fixture referenced the wrong historical profile; its failure is retained.
- Core-06 60,000 rows / 180,000 terrain faces: 30 actual Layers panel cycles and variation selections median/p95 **47.25/65.97 ms**. Thirty recipe-policy and thirty numeric-seed selections also leave complete rows, candidate/normal work, preparation and uploads unchanged. Subsequent **46.33 s** Live idle passes. Actual 100% Layers/recipe/Amount bounds and overlap checks pass; control-body captures were inspected, but their top background pixels are not a clean full-window capture. 150% remains pending.
- Ten actual pending Copy-button operations each Undo successfully without calculating or changing 60,000 published rows. Explicit Update to 90,000 rows preserves complete original layers and Same output, but a later heavy Undo assertion fails when Max expands its heap and clears history. Low-allocation direct probe and a warmed larger-heap stress run pass Undo/Redo. **This is an unresolved heap-pressure limitation, not a fixed failure.** A/B `undo-pressure-*.txt` reproduces it on delivered 0.83.0 (235,538,738 â†’ 353,230,395 bytes) and candidate 0.84.0 (353,386,578 â†’ 529,894,530 bytes), with empty Undo after Update in both. The old `Redo restored copy: true` line in those failed observations only reflects a still-present layer after failed Undo; it is not a valid Redo pass. The successor fixture labels this correctly. See I05 contract's official-source explanation; allocation work remains for I10/I11 before final program acceptance.
- Added explicit named-copy rejection for authored Edit/radius data pending I13, rather than silently dropping it. Recipe action button now clearly says Add layers / Create new setup. These final script changes are not yet host-qualified. `generated-03` passes with script **`483d15fdce766b9276296146243a7dc7e14b1c00ebaf09e6bebaad845d9542a8`**; native-01 remains unchanged.
- Core-05 PID 22924, core-06 PID 17268 and frozen baseline PID 26760 exited by guarded quit; process absence was verified. Only artist PID 15780 and unrelated PID 42536 remained before launching `foundation-roadmap-variation0840-candidate100-20261016-07`. Continue its exact-pair core/rollback, UI and scaled checks, then remaining I05 source/receiver/mask/Relax and failure matrix. No I05 delivery/commit/package exists yet.

### I05 binding guard correction â€” successor qualification required

- Candidate100-07 PID 26916 and candidate150-08 PID 13948 loaded script `483d15fdce766b9276296146243a7dc7e14b1c00ebaf09e6bebaad845d9542a8` with native-01. Core transaction matrix passed in both scales. Candidate100 also passed post-mutation copy rollback, unknown-policy and unsupported-radius guards, masked complete-row matching, distinct compatible receiver bindings, single-receiver invalidation, zero-weight sources, Relax, the four legacy examples, actual recipe/Amount UI handlers, passive heavy choices and a later idle interval. Python final repeat: 166 passed, 13.16 s. Test-only syntax/type/path-normalization failures are retained beside corrected successors.
- A focused source audit caught an I05 error: the new domain had been appended to the receiver **key** in the Edit/radius binding map. That made a changed domain look like an added receiver, allowing stale overrides to follow different random candidates. `binding_guard.ms` reproduces the failure in candidate100-07. The successor keeps the original receiver key and places a nondefault domain in the **binding value**. Default/legacy domains preserve the preceding binding exactly. This script correction is implemented but not yet host-qualified; do not use the earlier passes to claim this failure fixed.
- Next: launch a fresh matched successor, rerun binding guard plus affected core/mask/legacy/UI checks; finish 100%/150% layout/capture, source/receiver allocation and incompatible-Paint failure coverage. Keep B26 open with its independent A/B evidence. Both candidate hosts are still owned and must be closed or recorded before resuming. No 0.84.0 package or Git commit exists.


### I05 final successor — scoped-qualified and packaged

- `native-02` passed 35/35 suites (9.04 s), adding duplicate correspondence-ID rejection. Final script `c556d4cfa840f539aba5179081ed261320837fefe87da14549e9fed0a6c29948` is also its build-time script; main native SHA `e25b592962a4732056bf9aa206af9548e33feef87b0a222356d2ab1e0b4b222d`. Generated-04 passes 289 controls; final Python repeat: 166 passed, 12.58 s.
- Final 100% host `foundation-roadmap-variation0840-successor100-20261016-09` PID 3920 passes the corrected binding guard, complete core/rollback/masks/Relax, unsampled Save, receiver growth/quota/Undo, four legacy examples, actual recipe/Amount handlers, incompatible Paint and injected late Add/New setup failures, source insertion/removal/reorder/attribute cases and painted spline-band copy/import. Every matching claim compares all eight placement fields, not counts alone. Domain edits reject stale authored radius bindings and retain publication.
- Final 150% host `foundation-roadmap-variation0840-successor150-20261016-10` PID 9220 loads the exact same pair. Both scales pass actual control bounds, overlap/text checks and passive policy choices. 60k-row manager cycles median/p95 are 45.17/62.96 ms at 100% and 32.83/85.72 ms at 150%. Later Live idle checks pass at 41.38/53.03 s with complete rows and relevant work counters unchanged. One premature 150% check failed the 30-second minimum at 24.06 s; counters were unchanged and the failed receipt is preserved.
- Native HWND snapshots can return cropped/underlying pixels; the 150% manager was separately inspected in `owned-manager150.png`, captured with PrintWindow from the verified owned PID. Full controls are visible there. Physical DPI/input remains open.
- MZP `dist/CyrusScatter-0.84.0-20261016/CyrusScatter-0.84.0-Max2027.mzp`, 2,727,288 bytes, SHA `c4e8804baf3aa1edb493435c34a102618f2cf6771c1b9c9c6839c8dc77a5109b`. Archive, exact payload, host/version guard and uncalled-installer compilation passed. Not installed. The four original examples remain byte-preserved except the library's use guide and version/qualification inventory metadata.
- Current artist/architecture/version/product/roadmap docs and website source wording now explain variation, format 3 and B26. Website docs:sync/docs:check and local build pass (existing chunk-size advisory); nothing is published. Git checkpoint still needs completion. [I05 handoff](I05_0840.md), [qualification](QUALIFICATION_0840.json) and [package](PACKAGE_0840.json) pin the bounded delivery. B26 is not fixed by this phase; I10/I11 must address it before final program acceptance. I06 is next.

Both final owned hosts (3920 and 9220) exited after guarded quit; closure markers and process absence were verified. Waiter timeouts reflect exit before transport acknowledgement, not a host failure. Artist and unrelated camera profiles remain untouched.

### I05 pushed / I06 entry

I05 implementation `f2bc8dd6bc831a71cc46b19a6cb91611d431928d` matches `origin/codex/workflow-0.75`. Only the unrelated landscape row and the preserved untracked design/presentation files remain outside that commit. I06 begins with a bounded lattice/projector and explicit signed-cell identities; the old million-limited ordinal encoding cannot safely represent moving grid bounds. See the new contract before integration.


### I06 numeric foundation and candidate integration — not delivered

- HEAD `17dc5e4c54f84ef153e0d3584942d41784ad2454` is the pushed I05 checkpoint/I06 contract. Candidate changes remain uncommitted; unrelated landscape/presentation files remain preserved.
- `build/grid-0850-20261016-01/native-foundation-01` failed compilation on an ambiguous brace-initialized Box overload; explicit Vec3 fixed it. `native-foundation-02` passed all 36 native suites (9.18 s), with 48,965 grid assertions. Its 180,000-face / 10,201-hit projected lattice took 80.60 ms / 625,951 query visits in the native fixture, not Max end-to-end timing.
- `native-pipeline-03` passed all 36 suites (11.33 s). Grid anchors reuse the complete existing source/transform/mask pipeline. Tests compare complete common rows after footprint growth, anchor reordering, Include and UV-density thinning; zero weights, serial/parallel Clusters, invalid anchors and old/new identity transport also pass. Constant-height coplanar ties now avoid barycentric height roundoff. These builds still carried the frozen 0.84.0 script but exposed no grid UI; do not package/install them as a delivery.
- The current candidate advances source/UI to 0.85.0, appends saved grid settings, adds the cached Max adapter and Layout controls, and extends complete recipes/numeric settings to 4/3. `generated-01` passes 296 controls; script SHA `49b498fcc6ca587be809d86730d327267258729807138b574a8b499ab22f7856`. Layout-generator tests pass. First Python run: 165 passed / one catalog-count assertion failed because it still expected 289; the expectation/version were updated, pending focused repeat.
- `native-integration-04` is running against the new candidate. No I06 owned Max host is running yet. Next: inspect its compile/native tests, launch a matched disposable Max 2027 profile, verify new schema/recipe/default compatibility, then the full I06 matrix. B26 remains open; original four library examples are unchanged. No 0.85.0 package exists.

- `native-integration-04` SDK compilation passed; native result was 34/36. Two new persistence fixtures failed: the preset assertion searched the preceding version string, and a hydrated Paint document was passed to the manifest serializer. Corrected fixtures use the new version and the actual writeNew/read path; a subsequent diagnostic run caught the test reusing the same attachment folder, corrected to its own subdirectory. No product serializer guard was relaxed. Focused Python catalog/recipe checks pass (3/3). A fresh full candidate build follows; failed receipts remain.

### I06 Max integration and inactive-population correction — candidate only

- `native-integration-05` passed 36/36 suites (9.12 s, 79,651 grid assertions). Its first host caught an unqualified MAXScript lookup for the appended `placementMode`; changing the call to `this.placementMode` fixed the undefined comparison. Analyzer Single/EdgeRow is now rejected during preflight, including empty grids. Generated-02 passed 296 controls; Python full suite passed 166 tests (11.83 s).
- Owned host `foundation-roadmap-grid0850-core100-20261016-02` (36168) passed analytic grid/hex/origin growth, Manual/Update/Undo/Redo, all-eight-field copy/import/reopen, shared-admission failure retention, mesh/slope/altitude masks, zero weights, Relax, all four frozen presets, and actual dropdown/spinner/owner-switch checks. Frozen recipe and scene files were not rewritten. Native integration also passed Point/Empty, Include/exclude, white/black UV masks, protected Edit/dormancy/binding failure, analytic tilted-plane normals, projected movement and final radius distance checks.
- Live heading and active heading animation each rebuilt only the affected receiver. Idle, unrelated time/object changes and inactive grid-heading animation in Surface random preserved complete rows and work counters. A new adversarial test **failed** for animated inactive Count: rows and uploads stayed identical but attributes/preparation/publication rebuilt. Candidate validity now excludes Count/Density/refill fields in grid mode; root keys also omit inactive refill settings. This is a product correction, not a weakened assertion.
- `native-integration-06` passed all 36 suites (11.03 s) with the corrected script/native pair. Owned successor `foundation-roadmap-grid0850-final100-20261016-03` is starting for the affected repeat and heavy/UI tests. Prior host 36168 was asked to quit with an owned closure marker; the quit request times out after process exit by design. Verify absence. I06 remains uncommitted/unpackaged, and B26 remains open. Next: final runtime matrix, 100%/150% controls, heavy timing/idle/resources and two new actual-result preset examples.

### I06 final pair, examples and package — scoped-qualified

- Final `native-integration-06` is the exact host/package pair: script `9fc30834f8340dff09399fe31e678406eeb6bc444fc5b4d4aae28af9c68a5cea`, main native `b9dbf1c078e3b87e4d059a0749a9276f0d240567da6178a5db68a3dcba9d48b0`. Generated-03 passes 296 controls; final Python run passes 166 tests (12.17 s). Both final owned profiles load this pair.
- 100% host `foundation-roadmap-grid0850-final100-20261016-03` (42004) passes core, masks/Relax, Paint/Bands, radius binding, integration oracles, legacy examples, actual UI/Manual/Live/time/owner tests, and shared-limit/UV/vertical failure recovery. Corrected inactive Count animation and inactive refill/Density edits now do no calculation/publication. Relevant animated terrain still updates all affected grids.
- 150% host `foundation-roadmap-grid0850-final150-20261016-04` (32324) also passes core and actual UI; both scales pass all twelve panels after queued layout. Immediate measurements had clipped bounds before Max settled; those failures remain. Full-window top/bottom captures verify grid text and scrolling. Physical DPI/input is not claimed.
- Heavy terrain has 180,000 faces and 55,778 complete rows; initial 100% Update 1,345 ms. Warm Layout median/p95 94.47/136.85 ms (100%) and 84.41/140.91 ms (150%); owner switch 93.92/141.87 and 83.57/123.07 ms. Full rows and projection/candidate/preparation/upload counters remain unchanged. Later idle 114.54/132.90 seconds passes. These scoped measurements do not close B26.
- Sixteen grid snapshot replacements followed by collection do not accumulate meshes; switching generator releases the grid cache. Metre-to-centimetre complete recipe/numeric settings tests pass. Added two actual-result grid presets; each reopens, saves through UI and reproduces all eight placement fields through Saved import/Undo/Redo. A fixture mistakenly chose New while expecting Saved; correcting its explicit choice passes. The four original examples remain byte-preserved.
- MZP `dist/CyrusScatter-0.85.0-20261016/CyrusScatter-0.85.0-Max2027.mzp`, 3,638,650 bytes, SHA `53764753ce3e320aeafd977328788323cdaad8a9919736056089d2e07cdc64d0`. Exact payload, archive guards and uncalled installer compilation pass with 27 bundled files. Not installed. [I06 handoff](I06_0850.md) and 55 frozen evidence records document this scope. Current docs and website sources are being aligned; Git checkpoint remains next, then I07/P08.
- Prior host 36168 has exited, with closure marker and process absence verified. Final hosts 42004 and 32324 remain owned until guarded cleanup. Artist PID 15780 and unrelated camera hosts 42536/56168 are preserved.

Both final owned Max hosts (42004 and 32324) exited after guarded quit; closure markers and process absence are verified. Transport waits timed out because Max exited before acknowledgment. The artist host and unrelated camera profile were not modified. Website docs:sync/docs:check and local build pass after adding seven control explanations and updating reviewed current-source wording; the existing bundle-size advisory remains. Nothing is published. Git checkpoint is now being prepared.


### I06 Git checkpoint verified / preset-gallery planning only — 16 October 2026

The remote branch `codex/workflow-0.75` matches implementation `9f8cc157279b6e257f1f4a0eb6280fc75b0ea58c`. The existing 0.85.0 MZP remains 3,638,650 bytes with SHA-256 `53764753ce3e320aeafd977328788323cdaad8a9919736056089d2e07cdc64d0`; archive integrity and the recorded identity were rechecked during the preceding status response. No new runtime qualification is inferred.

The user's subsequent request is documentation only: make a detailed easiest-to-hardest preset/gallery improvement plan with performance and Max 2027 testing. [PG01–PG10](../preset-gallery-improvements/README.md) covers no-op settings apply, visual browsing, explicit capture, safe revisioned maintenance, selective style, portable assets, transactional import, installer delivery, shared/XRef/material adapters and later authored/effect presets. Its [validation matrix](../preset-gallery-improvements/VALIDATION.md) and [checklist](../preset-gallery-improvements/TODO.md) distinguish proposed gates from earlier passes. No PG implementation, version bump, host test, build, install or push occurred in this planning task. Historical receipts and unrelated landscape/presentation work remain preserved.

Documentation validation passed: nine Markdown documents checked, 283 local links resolved, all ten PG steps have behavior/performance/Max 2027/exit sections, and git diff --check is clean. The pre-existing landscape row is preserved exactly; tracked product files and historical qualification/package records are unchanged.


### 0.85.1 library delivery — 16 October 2026

The [handoff](../preset-gallery-improvements/DELIVERY_0851.md), [qualification](../preset-gallery-improvements/QUALIFICATION_0851.json) and [package identity](../preset-gallery-improvements/PACKAGE_0851.json) pin the final pair. Native 39/39, Python 166, generated 296 controls, all eight examples, the complete supported functional suite, one-hour import/reuse and two 30-minute gallery soaks pass. The valid heavy gallery fixture is 20,000 rows/180,000 faces. A settled 60,000-row Update can be rejected by the new conservative Undo-preserving admission guard; it is not a successful heavy-editing qualification or closure of B26. No further Phase 6 work or artist installation was performed. XRefs/material variants, absent I13/I14 adapters and production renderer/input acceptance remain open.

### 0.85.2 UI correction — 16 October 2026

The [correction handoff](../preset-gallery-improvements/UI_CORRECTION_0852.md) tracks the user-reported main Modify wheel/background-drag failure and undersized default library. Bind the existing native navigation handler on lazy mount, release on close, and normalize Max default-zero scale to one. No further Phase 6 feature is included; I07 and all broader B26/adapter gates remain unchanged. Historical 0.85.1 receipts stay frozen.
