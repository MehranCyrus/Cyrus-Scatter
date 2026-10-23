# Scatter simplification plan — 22 October 2026

**Planning only. No implementation, test execution, build, version change or release is authorized by this document.** The user requested a source audit and a detailed plan to simplify Scatter without changing features or scatter results. This plan records that audit and a recommended future sequence.

## 1. Decision and scope

Keep the current foundation: explicit layer/source/receiver ownership, stable identities, native bulk placement storage, receiver-bound Paint, bounded work, retained display and atomic publication. Simplify how those responsibilities are expressed and verified. Do not return to the 0.64/schema-48 model.

The scope is `AminScatter/` and the minimum existing generator/test tooling needed to prove equivalence. MCP, knowledge infrastructure, the website, Analyzer implementation, Licensing implementation, Physics Lab, Arrange, artist assets and unrelated roadmap features are outside this work. Preserve their existing integration contracts.

The [21 October code-quality proposal](IMPLEMENTATION_PLAN.md) remains intact. Its broader website and quality-program tasks are not resumed here. The packages below are the narrower recommendation for this request; SP identifiers are local planning IDs, not release or roadmap phase numbers.

Two outcomes are distinct:

- **Maintainability:** clearer state, smaller responsibilities and fewer duplicated declarations. No speed improvement is implied.
- **Performance:** less work or memory only where a repeatable measurement demonstrates redundancy. That is a separately identified optimization, with the same result and lifecycle checks. It is not an excuse to change scheduling during a readability refactor.

## 2. Audited baseline and evidence limits

| Item | Baseline |
| --- | --- |
| Branch / HEAD | `codex/workflow-0.75` / `3d387550cacf37fe1aeae7a01455f7644d9cf08b` |
| Product | Scatter 0.86.8.2; saved schema 59; `CyrusUnified2` |
| Other format boundaries | Complete recipe 8; native placement 2; publication bridge 4 |
| Current delivery evidence | [0.86.8.2 handoff](../source-clearance/DELIVERY_08682.md), with its original source/package/host identities and qualification limits |
| Working tree | No Scatter implementation diff at inspection. Extensive existing Arrange, Physics, website, knowledge and documentation changes are present and must be preserved |
| Knowledge verification | Generation `7bd37979ae4e3c242694fde44943d7ec54cfe6236112ce00c7d01bae18751fbc`; all 48 enrolled parents freshly verified; enrollment is limited, so unindexed implementation details were inspected directly |
| New validation in this task | Source inspection and plan-document checks only. No native/host tests, builds, Max launches or performance measurements |
| Future host scope | Max 2027 only by default. Historical 2024/2026 receipts do not become new qualification for a refactor |

Source line numbers below identify this inspected baseline. Recheck them and input hashes before implementation. Test code proves that a witness exists, not that it passed in this planning task.

The current [delivery](../source-clearance/DELIVERY_08682.md), source and [foundation](../../ENGINEERING_FOUNDATION.md) header establish schema 59. Some historical paragraphs, including the F11 limits paragraph, retain schema-58 wording. Do not interpret those as an instruction to downgrade the product or remove its supported 58-to-59 upgrade. Correcting enrolled documentation is separate from this plan.

## 3. Equivalence contract

Every implementation slice must satisfy the following before it is accepted:

1. **Same ordered result:** preserve candidate/instance identities, source and receiver correspondence, all transform components, effective XY/3D radii, accepted ordering, protected flags, Band/anchor provenance and output membership. Native reasons/conflicts, attempts, quotas, shortfall, rounds, limit outcomes and charged work must also agree at their existing observable boundary.
2. **Same numerical execution:** preserve RNG domains/seeds, loop and cell traversal, stable sorts/ties, arithmetic order, strict comparisons, thresholds, cleanup/refill order and failure precedence. Algebraically equivalent code is not sufficient evidence of equal floating-point output.
3. **Same authored model:** preserve parameter-block and class IDs, field/tab order and defaults, UUIDs, units, schema 59, recipe 8 and existing supported recipe conversions. Keep stable source-row IDs distinct from native source slots and output indices.
4. **Same user behavior:** retain controls, labels/order/visibility, selection modifiers, actions, explicit Update, Manual/Live behavior, one-action Undo grouping, save/reopen, copy/import and source replacement. A pending Manual recipe and its preceding publication remain distinct.
5. **Same transaction boundaries:** stage the complete successor before installation, keep native Edit rollback valid through the install tail, and retain the preceding complete result on failure. Post-commit observer errors must not trigger a rollback of an already committed result.
6. **Same lifetimes and admission:** preserve reference sharing, old/new coexistence, scratch limits, memory estimates, fallback decisions, release thread/timing and necessary Undo/render/PFlow pins. No deep copies of placement populations or longer-lived rollback roots merely to make code look safer.
7. **Same avoided work:** warm browsing, selection and unrelated animation must not add solves, preparation or unchanged-buffer uploads. Relevant animation/dependencies still invalidate correctly. Cold reconstruction and structural commands keep their existing separate behavior.
8. **Same failure interface:** preserve validation bounds, rejection order, actionable messages, previous-result retention and valid recovery. Do not silently repair a baseline defect as part of a refactor.

These constraints follow F01–F12. Their verification limits remain applicable: identities do not imply arbitrary topology correspondence; spacing remains its declared radius model; conditional stability under quota, Relax and shared acceptance is not universal invariance.

## 4. Findings and recommended packages

| Package | Recommended work | Risk | Dependency |
| --- | --- | --- | --- |
| SP00 | Freeze results and make host completion evidence trustworthy | Test-tooling changes; essential prerequisite | First |
| SP01 | Decompose authoritative template text without changing generated bytes | Low if final bytes are identical | SP00 baseline identity |
| SP02 | Centralize clearance value-field bookkeeping | Low–medium | SP00 affected authoring/persistence witnesses |
| SP03 | Extract contiguous recipe validation groups | Low–medium | SP00 recipe acceptance/error corpus |
| SP04 | Name transient snapshots, then clarify publication stages | High lifecycle risk | SP00 transaction/failure matrix |
| SP05 | Clarify native policy compilation, then round/settlement code | Medium initially; high for settlement | SP00 native parity/oracles |
| SP06 | Name preview resource estimates without moving ownership | Medium | SP00 reservation/lifetime witnesses |
| SP07 | Remove specific duplicated UI-owner handling only where justified | High callback risk; optional | SP00 current generated-handler lifecycle witnesses |

SP02 and SP03 can proceed before the higher-risk publication/solver work. Do one package, and one responsibility within that package, at a time. Nothing requires completing every package.

### SP00 — Establish the preservation baseline

**Observed:** meaningful independent numerical, storage, publication and host witnesses already exist. However, some host checks compare counts or aggregate movement, older parity fixtures depend on a removed product switch, and completion checks are not uniformly fail-closed.

**Sources:** [clearance tests](../../../AminScatter/tests/source_clearance_tests.cpp) (`independentOracle`, `refillOracle`, lines 155/194); [procedural tests](../../../AminScatter/tests/procedural_tests.cpp); [current Relax checks](../../../tools/clearance_relax_08682/checks.ms); [native-placement controller fixture](../../../tools/native_placement/fields_controller.ms); [current host driver](../../../tools/clearance_relax_08682/host.py), especially its `if log.exists()` branch.

**Future work:**

- Freeze a small set of current scenes and native inputs before refactoring, including their persistent UUIDs, seeds, insertion order and source/receiver mappings. Run baseline and candidate on copies of the same inputs with the same SDK/compiler settings; do not recreate independent scenes and then normalize away changed identities.
- Reuse the existing native oracles and private request transport. Add the smallest current harness adapter needed for explicit fresh run paths, Max 2027, payload identity and scenario selection. Do not build a general testing framework or rewrite historical campaign tools.
- Require a current request/scenario ID, expected assertion IDs, nonempty results and an explicit terminal marker. Missing, stale, truncated, mismatched or caught-failure logs must fail. A transport success or existing old PASS log is insufficient. Reconcile an uncertain request before issuing another mutation.
- Record ordered publication fingerprints plus actual frozen source/receiver/owner metadata. `cyrusPlacementPublicationFingerprint` at [recipes_bridge.cpp:503](../../../AminScatter/src/recipes_bridge.cpp) includes metadata supplied by its caller; a literal label such as `#("field-controller")` does not independently verify correspondence. Keep a bounded readable mismatch report for small fixtures.
- Compare per-row reasons/conflicts and budget bookkeeping in the native result tests, where they exist. Do not add a public production API simply to expose every internal value to a host fixture. Keep high-count diagnostics native/streamed or paged, rather than materializing a million script rows.
- Adapt useful bodies from `tools/native_placement/` and `tools/source_clearance_0868/`; their hard-coded historical directories and `procNativeRoute` assumptions are not ready-made current qualification. Do not restore the retired product switch to make a test run.

**Exit:** frozen expected outputs survive independent reruns; a deliberately missing/failed/stale scenario cannot pass; test coverage and unavailable cases are explicit. A baseline defect is recorded separately, never incorporated into a refactor's changed golden result.

### SP01 — Separate source responsibilities with identical generated output

**Observed:** [generate.cjs](../../../AminScatter/tools/ui/generate.cjs), lines 5–23, already composes authoritative templates. The large `unified-core.ms` still mixes authored data, ownership, evaluation, publication, output and component UI definitions.

**Important source fact:** [approved-layout.cjs](../../../AminScatter/tools/ui/approved-layout.cjs), lines 403–417, first consumes component definitions and then replaces the old contiguous rollout block with composed pages and [approved-main-ui.ms](../../../AminScatter/tools/ui/templates/approved-main-ui.ms). An apparently discarded rollout body can still be a generator input. Do not delete it based only on the final replacement.

**Future work:** extract one contiguous non-UI responsibility, preferably publication snapshot/staging text, into a dedicated template fragment. Assemble it at exactly its original position before the existing licensing/inventory/layout transformations. Keep all declarations, comments, whitespace, forward references and lexical scope in the resulting runtime text unchanged. Add exact missing/duplicate/ordering checks for the new fragment.

**Preserve:** the existing generation order, BOM/newlines, runtime fingerprint, semantic control identities, generated inventory/catalog content and all current runtime functions. Do not introduce `fileIn`, dynamic evaluation, runtime include dependencies or a new UI framework.

**Exit:** final `scripts/AminScatterObject.ms` is byte-identical at the unchanged product version; generated metadata remains identical or has a separately explained non-runtime provenance change. Update source maps/checker input paths honestly. Only later packages may change method structure.

### SP02 — One definition of clearance value-field bookkeeping

**Observed:** [unified-core.ms](../../../AminScatter/tools/ui/templates/unified-core.ms), lines 2539–2574, repeats the eight clearance value fields in validation, accepted-field checks and deletion; default row construction also depends on the same order. `CyrusClearanceFields` at line 600 additionally includes the identity tab.

**Future work:** introduce one explicitly ordered value-only field/default definition for these local authoring operations, retaining separate `clearanceSourceIDs` handling. Use the simplest constant/list supported by the existing language patterns. Do not introduce a reflective schema framework.

**Preserve:** saved parallel tabs and their order, sparse rows keyed by source UUID, defaults, validation calls/errors, selected-ID capture before mutation, dirty notifications and the current single Undo action. Keep independent scope inheritance, target strings/UUID translation and recipe remapping unchanged.

**Exit:** set/delete/default/reset and multi-source edits, malformed tab lengths/IDs, source replacement/removal, copy, recipe roundtrip, schema-58 upgrade and Undo/Redo preserve the same fields and results. In particular, reusing a list containing the ID tab must not accidentally treat identity as an editable value.

### SP03 — Make recipe validation readable by record group

**Observed:** [recipes.cpp](../../../AminScatter/src/recipes.cpp), `validateSettings` at line 97, combines general scalar validation with long Path/Band, clearance, variation-domain, source and mapping record checks. Supported conversion lives separately in `currentDocument` at line 189.

**Future work:** extract one contiguous group of checks into a private same-translation-unit helper, preserving its position in `validateSettings`. Begin with the clearance-record block; handle Band records in a later slice. Keep current containers, comparisons and error strings.

**Preserve:** closed-field acceptance, all size/unit/identity bounds, first-failure precedence for documents with several errors, current defaults and conversions of supported recipe formats 1–7 into 8. Retired scene formats and supported portable recipe formats are different contracts.

**Exit:** valid and malformed current/older recipes produce identical normalized data or identical first rejection. Reuse [recipe tests](../../../AminScatter/tests/recipe_tests.cpp), [store tests](../../../AminScatter/tests/recipe_store_tests.cpp), and relevant package tests. No saved format, asset admission or dependency behavior changes.

### SP04 — Name transient state and clarify the publication transaction

**Observed:** in [unified-core.ms](../../../AminScatter/tools/ui/templates/unified-core.ms), staged previews return 21 positional fields near line 3926; `procPreviewState` captures 23 at line 3930; result state captures 12 at line 3955; `evaluateProcedural` captures a separate 13-field root publication at line 4075. Restore/install code interprets these by index. The root method at line 4038 also owns admission, native Edit transaction, preparation, evaluation, staging, installation, rollback and observers.

**Future work, in order:**

1. Inventory each state family's producers/consumers and field-by-field capture/restore mapping. Keep staged-successor state distinct from rollback state.
2. Name one transient state family using small local access/capture helpers or an existing-language record pattern after verifying scope/load/reload behavior. Do not choose global structs, dictionaries or serialization merely to remove numeric indexes.
3. Keep the transaction-owning `try/catch` visible in `evaluateProcedural`. Extract only small contiguous preparation/staging operations whose dependencies are explicit; preserve the visible commit sequence. Avoid a generic callback-based transaction runner.

**Preserve:** admission before Edit mutation; all-owner staging before any install; the current placement of `publishGroupEdits` and visibility synchronization; input-key recheck before epoch/install; root/leaf agreement before Edit commit; complete rollback on failure; and post-commit observers outside the rollback region. Preserve dropping `previousPublication`/`previousResults` before the Count-down working-set checkpoint at lines 4159–4160. Named state must hold the same references, not larger copies or longer-lived closures.

**Required host failure matrix:** preparation failure, later-layer display staging failure, input mismatch before install, partial display installation, native/root publication installation, failure while Edit rollback is still available, retry after failure, and observer failure after commit. Use existing test-only fault seams or narrowly scoped private instrumentation; keep injection controls out of shipping payloads. Prove complete output/history retention, not only unchanged counts.

**Exit:** exact result and authored-state parity, coherent preview/native/output epoch, preserved unrelated Undo history, no added population-sized copies and the same last-owner release. Test `procEnsureDisplay`'s separate all-layer rollback path as well as the main solve transaction.

### SP05 — Clarify native compilation before touching settlement

**Observed:** [source_clearance.cpp](../../../AminScatter/src/source_clearance.cpp) combines policy validation/cohorts/defaults in `Context` (line 44), components/bounds in `compileClearance` (line 146), and stateful settlement/cleanup/refill in `evaluateClearanceComponents` (line 178). [procedural.cpp](../../../AminScatter/src/procedural.cpp), `evaluate` at line 37, also combines validation, pair lookup, ordered rounds and bookkeeping.

**Future work, in separate slices:**

- First name/extract current default-rule and cohort/component construction operations without changing the data structures or loops. Keep `CompiledClearance`'s reference to its input `Plan` inside the same synchronous solve lifetime.
- Next extract group metadata initialization or a contiguous procedural validation block. Keep the existing compile-once behavior; do not add another cache.
- Only if readability still warrants it, extract round/cleanup/settlement operations as a final high-risk slice. Keep the state machine and its loop in one readable location; a longer explicit function can be preferable to a hidden framework.

**Preserve:** participating-source filtering, equivalent default/custom schedules, Count admission before preference, protected/preferred/layer/ordinal ordering, stable sorts and tie breakers, both metric grid widths/traversal, `hypot` expression order, strict distance comparisons, provisional blocker hints and same-prefix stale settlement. Preserve cleanup reservations, prefix growth, visit charging, settlement limits, exception precedence and underfill.

**Exit:** the existing 240 single-pass and 500 refill clearance oracle cases, procedural exhaustive tests, fixed-seed state sequences, exact-threshold/XY-versus-3D cases and work-limit/failure cases agree with the frozen baseline. Later-stage extraction also needs affected host publication/Undo witnesses. Do not merge normal and ranked acceptance paths solely because both contain round loops.

### SP06 — Name preview reservation formulas while preserving ownership

**Observed:** [point_display.cpp](../../../AminScatter/src/point_display.cpp), `Generation::plan`/constructor at lines 136–220, interleaves quotas, CPU estimates, GPU/scratch/coexistence allowances, fallback and reservations. [point_publication.inc](../../../AminScatter/src/point_publication.inc), lines 3–42, already expresses a compact stage-then-swap publication boundary.

**Future work:** name the existing point and mesh estimate calculations as small private operations. Leave acquisition, fallback, failure handling and swaps where they are. Initially preserve every formula literally, including capacities, palette bytes, appearance charges, full-plus-box transform streams, scratch overlap, group allowances and the re-estimate after `plan(true)`.

**Preserve:** when process `used()` is observed, old/new coexistence, first-reservation cleanup if the second fails, shared/weak ownership, host-thread release, reduced-box policy, group limits and all owner/process limits. Keep Point/Mesh item paths distinct and leave `point_publication.inc` structurally intact.

**Exit:** the same quotas, byte estimates, fallback/admission decisions and release counters for empty, point-only, mesh, textured/opacity, shared-resource, reduced and failed generations. Existing [publication tests](../../../AminScatter/tests/publication_tests.cpp) explicitly model collaborators rather than GPU behavior; add focused estimate characterization and retain owned Max display/lifetime checks for changes touching real resources.

### SP07 — Optional cleanup of actual generated UI-owner handling

**Observed:** the live UI path is [approved-main-ui.ms](../../../AminScatter/tools/ui/templates/approved-main-ui.ms), [approved-layout.cjs](../../../AminScatter/tools/ui/approved-layout.cjs) and [lazy-pages.cjs](../../../AminScatter/tools/ui/lazy-pages.cjs). It already has `beginPageEdit`/`endPageEdit`, selective bind requests, owner-aware queues, captured `eventPanel`, layout stamps, lazy bodies and close cleanup. These are existing protections, not missing features.

**Future work:** identify an exact duplicated capture/cleanup/value-sync sequence in live generated handlers, characterize it, and consolidate only that sequence using the existing mechanisms. First document the model-owner versus view-owner transition in `bindSection`/`bindEditors`. If no small safe repetition is demonstrated, skip runtime refactoring and retain the documentation/tests.

**Preserve:** which owner is captured at action time versus resolved at queued dispatch, pending-owner full-bind fallback, nested action depth, early returns and exceptions, one Undo/action, teardown of timers/scroll handlers/references, layout and value synchronization boundaries, licensing guards and control presentation.

**Exit:** actual generated control events followed by posted timers survive queued source-page mount → selected-owner switch → multi-source edit, nested refresh, close/reopen and scene replacement. Verify the intended owner's exact fields and Undo, no stale-owner writes or duplicate handlers, and unchanged warm solve/preparation/upload counters. Direct `.tick()` calls alone do not qualify event ordering. Do not redesign the UI, add polling, broaden invalidation or introduce another callback framework.

## 5. Verification matrix and economical check selection

Reuse existing test bodies and extend gaps instead of adding a second solver or duplicated test infrastructure.

| Behavior / risk | Existing starting points | Additional acceptance needed |
| --- | --- | --- |
| Exact numerical rules and refill | `source_clearance_tests.cpp`, `procedural_tests.cpp`, `spacing_tests.cpp` | Frozen ordered baseline, state edit/restore, first failure, reasons/conflicts and charged-work parity |
| Layout, maps, transforms and identities | `receiver_tests.cpp`, grid/mesh-density/orientation/spline tests; native-placement feature fixtures | Same frozen receivers/sources/UUIDs; Random/grid, Density/Fixed Total, maps, scale/orientation and Band provenance; no regenerated expected scenes |
| Paint and authored edits | Brush/receiver/Edit-block tests; native-placement lifecycle and field-controller bodies | Planar and supported curved Paint, overlap/erase, full identity/radius/transform parity; Edit/clone/delete/radius Undo; source/receiver replacement and dormant bindings |
| Publication and failure | `publication_tests.cpp`, `placement_publication_tests.cpp`, `placement_store_failure_tests.cpp`, native-placement `failures.ms` | Current host script/native install matrix, later-owner failure, retry and post-commit observer distinction |
| Manual/Live and avoided work | Source-clearance `host_lifecycle.ms`, native-placement `controller.ms` | Pending Manual edits, relevant geometry/map/animation, unrelated timeline/selection, warm browsing; counts of solve/preparation/uploads rather than timing alone |
| Current UI owner/action lifecycle | `clearance_relax_08682/checks.ms`, source-clearance `ui_events.ms` | Actual posted owner switch, queued bind, multi-selection, nested refresh, early-return/error cleanup, teardown/reopen and one-step Undo |
| Persistence and library behavior | Recipe/store/package tests; source-clearance upgrade/save fixtures | Supported older recipe imports, schema-58 explicit upgrade and its Undo, current reopen/copy/merge/role remapping; library apply/replacement remains unchanged |
| Display/output/resource lifetime | Viewport-policy/publication/storage tests; native-placement output/lifecycle bodies; 0.86.8.1 appearance fixtures | Same shown subset, supported material/opacity and source appearance, exact output/PFlow/Bake, shared consumers, abandoned history and scene reset; actual retained owner observed |

For exact parity, compare ordered rows; also diagnose by stable ID. Do not sort away output order, compare only counts/energy/images, regenerate goldens after a change, or compute expected answers with the helper being refactored. Existing publication fingerprints are useful only with complete declared metadata and their precision scope understood. Keep native full-precision equality separate from existing bounded host transport representation; any boundary tolerance must be declared before implementation, not added after a mismatch.

Timing, process-private memory and opaque process/GPU handles are not deterministic placement equality fields. Explicitly list any excluded operational fields. Geometry/acceptance/work diagnostics remain comparable. Readability work must not introduce reproducible resource or latency regressions; a speedup claim needs a separate controlled before/after measurement.

Future commands below use a **fresh** run name; they were not run for this plan:

```powershell
# From AminScatter/: deterministic generation/layout checks.
node tools/ui/generate.cjs --check
node tools/ui/approved-layout.test.cjs

# From repository root; documented Max 2027 build and source checks.
python tools/procedural_lab/check_generated.py --output build/<fresh-run>/generated
python tools/procedural_lab/offline_build.py --project scatter --year 2027 --output build/<fresh-run>/scatter

# Select the affected suites; the names below exist in current CMake registration.
ctest --test-dir build/<fresh-run>/scatter -R '^(scatter_source_clearance|scatter_procedural|scatter_spacing|scatter_receivers)$' --output-on-failure
ctest --test-dir build/<fresh-run>/scatter -R '^(scatter_publication|scatter_placement_publication|scatter_placement_store|scatter_placement_store_failure|scatter_viewport_policy)$' --output-on-failure
ctest --test-dir build/<fresh-run>/scatter -R '^(scatter_recipes|scatter_recipe_store|scatter_recipe_library|scatter_asset_package)$' --output-on-failure

# Existing integration-tool test entry point, when affected by the slice.
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q
```

SP01 starts with generator checks and byte comparison; do not rebuild every native subsystem repeatedly for an identical runtime text extraction. Native/recipe slices run their focused suites, then affected host/failure cases. Runtime MAXScript changes need generated checks and current owned Max 2027 execution; a static pass is not compilation/lifecycle acceptance. Run the broader native/integration gate at a coherent milestone or when shared changes/failures justify it.

Host commands depend on SP00's current adapter; do not present dated launch paths as ready-to-run commands. Match source, generated script, native/managed payloads, loaded paths/hashes, fixtures and Max/SDK identity before scene mutations. Use owned disposable profiles/scenes, preserve an unrelated Undo sentinel, serialize requests, and stop only verified owned processes. Missing SDK/host/assets/device coverage is `blocked` or `not run`, not a pass. Physical input/DPI, renderer fidelity and GPU device loss remain separately scoped acceptance.

## 6. Work deliberately deferred

- Generic transaction, scene-owner, node, schema-registry, renderer or test frameworks; a broad C++/MAXScript/Qt rewrite; automatic C++ migration merely to reduce script lines.
- New final-component caches, async placement/cancellation, workers, GPU computation, algorithm/grid/container substitutions, limit changes, RNG changes, alternate floating-point expressions or relaxed equality tolerances.
- Changing static-update dependencies or moving UI work off the host thread. B21 optimization requires current measured redundant work; selective binds/layout stamps already exist. Compiling clearance once and ignoring dormant sources are already implemented in 0.86.8.1.
- Removing supported recipe conversions, the schema-58 upgrade, failure guards, licensing checks, native/array boundary readers, protected edits or saved parameter fields as supposedly obsolete code.
- Combining Point/Mesh publication paths or the staged-preview and rollback-preview records just to reduce apparent duplication.
- The repeated Edit eligibility predicate at `cyrus_edit_stack.inc:144/154`: the repetition is small and direct primitive coverage is limited. Revisit only after a demonstrated maintenance need and a targeted current Edit/Undo witness; it is not a first cleanup target.
- Fixing B05 cold container Undo, B11 cold realization, B21 panel latency or other discovered defects silently. Preserve reproductions and request a separately identified correction scope if needed; do not change golden output to absorb them.
- Full codebase reformatting, cosmetic file/identifier renames, historical receipt rewrites, website work, new feature/API/schema/version selection, packaging, installation, deployment or Git commit/push.

## 7. Order, stop rules and first future slice

Recommended order: **SP00 → SP01 → SP02/SP03 → SP04 → SP05 → SP06 → optional SP07**. SP05 settlement extraction is separately stoppable and may be omitted if it hides more state than it clarifies. SP06 can proceed after its own resource baseline without waiting for unrelated solver changes.

For each slice: freeze inputs → characterize baseline → make one bounded implementation change → run relevant exact/independent/failure checks → inspect the full diff and generated output → record evidence and limits. Repeat only checks justified by new changes, failures or unresolved concerns. Avoid concurrent mutations in the same Max process.

**Stop on any unexplained difference** in output, ordering, authored state, diagnostics, failure/Undo behavior, admission or lifetimes. Isolate or back out the owned slice; preserve unrelated work. Never overwrite golden results, lower limits/requirements, clear Undo or force broad refreshes to make the refactor pass. If a performance candidate changes only intended internal work counters, document that explicit difference separately while preserving all result and lifecycle contracts.

The first recommended future implementation is **SP00 plus one SP01 byte-identical extraction**. Then SP02/SP03 offer bounded useful cleanup before the transaction and solver. Approval of this plan is not authorization to execute all packages or resume unrelated plans. A later user-testing binary delivery follows the version policy and exact qualified Max 2027 MZP workflow; no version is chosen here.

Planning completion means this document and verified source references exist, product source/generated artifacts are preserved, and proposed changes are clearly separated from executed evidence. It does not mean a refactor or new qualification has occurred.
