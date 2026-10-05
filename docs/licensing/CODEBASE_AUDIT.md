# Licensing codebase integration audit

**Reviewed 2026-10-02. Static source findings only. No plugin code was changed and no build, Max session or licensing enforcement experiment was run.**

The code supports adding a separate licensing layer without rewriting the scatter algorithms. The difficult part is deciding which operations that layer may stop: preview, render preparation and script authoring share calculation paths, while evaluation also updates edit identities and caches. A blanket check in every native function would create avoidable compatibility and performance risks.

**October 4 follow-up:** this document retains its original static scope and evidence. The [first runtime experiment](L0_EXPERIMENT_2026-10-04.md) and [current provisional contract](OPERATION_CONTRACT.md) cover the later source snapshot, including Brush/group/MCP paths. Its 69 declarations supersede the count below only for that later snapshot. The [subsequent signed-license experiment](SIGNED_LICENSE_EXPERIMENT_2026-10-04.md) adds real verification while retaining that frozen product baseline; complete native boundary qualification remains unfinished.

This audit supplies the source map for [roadmap L0](ROADMAP.md). L0's runtime prototype and policy proof remain unfinished. Findings below are integration hazards and improvement proposals, not vulnerabilities in an already deployed licensing system.

## Evidence and scope

The [source snapshot](evidence/codebase_snapshot_2026-10-02.json) records 37 selected file fingerprints and 38 `def_visible_primitive` declarations across both native source trees. It includes the dirty working tree at HEAD `1bfb400abc19b7472b4c20621970d435ac214c33`; that commit alone does not reproduce the inspected source. Local before-copies are retained under `_local/maintenance/2026-10-02-licensing-code-audit/source/`.

The review traced representative generation, preview, retained display, CS Edit, Analyzer, bake/export, PFlow, startup and packaging paths. The declaration scan is not a full callable-surface audit: Max SDK callbacks, MAXScript functions, parameter setters and future registrations also matter. Algorithm correctness, all input parsing, live renderer behavior and installed-binary identity were not requalified here.

## Keep the existing separation

Both [Scatter CMake](../../AminScatter/CMakeLists.txt) and [Analyzer CMake](../../CyrusSurfaceAnalyzer/CMakeLists.txt) already separate host-independent computation from Max modules and allow core-only builds. Keep that structure. LicenseCore should be independently testable and consumed by host adapters, with no entitlement logic inside numerical loops.

The [retained point interface](../../AminScatter/include/point_preview.h) publishes immutable snapshots; [PointItem::Display](../../AminScatter/src/point_display.cpp) draws prepared data. Preserve this boundary. A status refresh must not invalidate every point buffer, reacquire seats, scan credentials or verify a signature during drawing.

The [compute range executor](../../AminScatter/include/execution.h) joins workers before returning. It is not an asynchronous networking facility. Future license refresh needs its own bounded lifecycle and immutable result publication; it must not occupy placement workers or pass Max objects to network threads.

## Findings that affect the first coding loop

### C01 Separate enable controls from authorization

**Observed:** [activation.cjs](../../AminScatter/tools/ui/activation.cjs) adds the serialized `cyrusEnabled` control and a placement early return of `#()`. Disabling an Analyzer can also select an empty preview. The [Analyzer script](../../CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms) has its own enable property and stops analysis when disabled. These controls intentionally change scene behavior; their names do not mean commercial activation.

**Recommendation:** keep them as artist controls. Add a separate process/session license snapshot and structured status/recovery interface. Never implement expiry by setting `cyrusEnabled=false`, disabling a layer or replacing its data with empty output. Do not serialize account credentials, leases or private authority into a `.max` scene.

**Gate:** E04/E15 must distinguish artist-disabled output from denied new authoring, with scene parameters unchanged by license transitions.

### C02 Calculation functions do not prove authoring intent

**Observed:** the generated [controller](../../AminScatter/scripts/AminScatterObject.ms) routes `placements` through `cspImpl_placements`, then calls `aminScatterTransforms` or `aminScatterAdvanced`. Preview calls `placements ... previewOnly:true`; PFlow and bake use the same placement workflow. Blocker queries and final cleanup can enter it recursively. The [native bridge](../../AminScatter/src/max_bridge.cpp) consumes caller-provided nodes/settings and returns transform/source rows; the inspected entries have no entitlement or saved-state authority contract.

**Consequence:** checking only the `placements` wrapper would leave its implementation method and native entries outside that check. Conversely, denying every native calculation without a license can interrupt legitimate scene regeneration. `previewOnly`, `rawOnly`, `finalPass`, render globals and an executable filename are behavior inputs, not proof of authorization.

**Recommendation:** first trace a direct parameter change followed by evaluation in a disposable fixture. Define the permitted inputs and owner of an operation context. Compare a practical boundary around commercial workflows with any stronger native ownership of saved state; record limitations honestly. If a scoped permit is used, native code must mint and validate it for the intended operation/lifetime. A public script command accepting `evaluation=true` does not solve this problem.

**Gate:** E01 must cover both computation entries, exposed wrapper/implementation paths, direct parameter writes and saved evaluation. This is the main unresolved L0 policy/architecture question, especially for free rendering.

### C03 Authorize before clearing completed output

**Observed:** `cspImpl_refreshPreview` clears `cachedPoints` and counters before entering calculation, and its catch keeps the cache undefined. In [pflow.ms](../../AminScatter/tools/ui/templates/pflow.ms), `CyrusPFBuild` calls `CyrusPFClear` before placement evaluation. PFlow preparation also temporarily changes baked nodes' renderability and restores it through cleanup. These paths handle calculation failure today; they were not designed as licensing transitions.

**Integration risk:** a new denial deep in calculation could remove completed preview/render preparation before the operation reports failure. This is a source-derived consequence to test, not an observed licensing failure.

**Recommendation:** perform local authorization admission before cache reset, Undo setup, transient-node removal or renderability changes. For later failure/expiry, stage results and publish only completed output where feasible, with explicit rollback. If the UI retains the last approved preview, label it as retained/stale when appropriate; do not present denied new settings as successfully calculated. Keep approved render continuity separate from merely keeping a viewport cache.

**Gate:** E15 includes denial before rebuild, failure during preparation and expiry during a render/edit operation. Compare cached output, source parameters, transient nodes and baked renderability before and after.

### C04 Gate actual CS Edit mutations through their shared implementation

**Observed:** [cyrus_edit.cpp](../../AminScatter/src/cyrus_edit.cpp) exposes native Move/Rotate/Scale, deletion through `Notify`, `reset`, `CloneSelSubComponents`, script `cyrusEditTransform` and a mixed `cyrusEditCommand` dispatcher. Command 0 resets; 1 selects; 2 deletes; 3 clones selected rows; 4 transforms; the fallback queries validity. UI tools and script commands reach overlapping mutation methods. `Clone(RemapDir&)`, Undo and Redo are additional host paths.

**Recommendation:** classify the dispatcher by operation rather than licensing every command identically. Put admission at shared mutation boundaries before `theHold.Begin`, `hold`, row changes or new identities. A drag needs an operation permit and defined finish/cancel behavior, not one seat checkout per mouse movement. Keep selection, status and recovery usable under their own policy.

Do not blanket-gate `changed()`, `NotifyDependents`, every `Clone` or restore callback. Some serve selection, host copying or restoration. Determine their call context and prove the intended outcome in Max. A denied operation must leave Undo state and axis-tripod locks balanced.

**Gate:** E01/E13/E15 compare native tools and script commands, expiry mid-drag, Cancel, Undo/Redo, reset/delete/clone and host object copying.

### C05 Evaluation can update persistent edit bookkeeping

**Observed:** [cyrus_edit_stack.inc](../../AminScatter/src/cyrus_edit_stack.inc) applies stored deltas but also binds layer signatures, maps input IDs, appends rows and recovers legacy identities. [Storage](../../AminScatter/src/cyrus_edit_storage.inc) saves the rows and reads both legacy and current chunk formats. `EditRestore::Restore/Redo` copies stored maps and calls `changed()`.

**Recommendation:** distinguish new artistic mutation from evaluation/restore bookkeeping. Disabling all writes in an unlicensed session would be too broad. Keep identity recovery, scene save/load and the approved history behavior testable without erasing edits. Existing fingerprints and topology hashes in `cyrus_edit.cpp` describe layout/cache identity; they are not cryptographic signatures or license proof.

**Gate:** E15 covers legacy load, missing caches, stacked edits, lower-modifier changes, save/reopen and approved Undo/Redo behavior. No schema or Class ID migration is justified solely by this audit.

### C06 Bake and export need an honest protection boundary

**Observed:** `bakeInstances` in the [controller template](../../AminScatter/tools/ui/templates/before.ms) creates Max instances from transform/source rows. Analyzer `exportCurves` creates splines from its stored arrays. The generator removes the old bake button from generated preview panels, but the method remains in the controller. PFlow uses ordinary scene objects and script-accessible row arrays; its transient nodes are removed before saving.

**Recommendation:** do not claim enforced export permissions from a disabled button or a separate `canBake()` script check. If a native bake/export command is justified, it must own the meaningful operation and participate in rollback. Already delivered transforms and geometry remain locally accessible. A permanent render cache is not present merely because PFlow displayed a result; rendering after reopen can require regeneration.

**Gate:** B07 and E01/E15 explicitly address script-invoked bake, Analyzer export, clean render workers, reopen without preview/PFlow caches, and the practical limits of restricting locally available output.

### C07 Cover Analyzer callbacks and downstream dependencies

**Observed:** Analyzer's `runAnalysis` wraps `cspImpl_runAnalysis`; the native `cyrusAnalyzeSurface` entry is independently exposed. The script saves paths/points and updates them through manual UI or a 250 ms live timer. Scatter uses those arrays for area, falloff and distribution behavior. Render callbacks pause Analyzer's live updates; that flag is scheduling state, not license authority.

**Recommendation:** authorize new analysis at the appropriate native/workflow boundary, preserve existing results on denial and keep stored-result reads available according to the continuity contract. Treat any required analysis during scene regeneration separately. Never perform login, refresh or seat checkout on every timer tick.

**Gate:** E01/E15 cover manual analysis, direct native calls, live update, retained results after denial and dependent Scatter evaluation in each promised renderer mode.

## Preparation before integration and packaging

### C08 Maintain a complete operation inventory

The snapshot contains 38 native MAXScript declarations, including postprocessing helpers in `.inc` files. Review them by purpose, not just the two generation functions:

| Family | Examples | Proposed treatment |
| --- | --- | --- |
| Generation and analysis | `aminScatterAdvanced`, `aminScatterTransforms`, `cyrusAnalyzeSurface` | L0 must resolve authoring/evaluation authority |
| Row processing | source filtering/transforms, overlap removal, orientation, falloffs, Analyzer area and whole scale | Classify direct calls and reuse the parent operation policy; avoid an entitlement per helper |
| Edit mutations | command and transform entries plus Max SDK methods | Shared native admission and bounded operation lifetime |
| Edit evaluation and inspection | stack, topology, fingerprints, active layers, selection and revision | Preserve approved evaluation/inspection; some update bookkeeping |
| Preview preparation and drawing | sample/build/query/draw, retained create/publish/matches | Keep display continuity and hot paths free of licensing work; transient helpers are not paid scene authoring by default |
| Session controls and diagnostics | CPU thread limit, compute stats, batch switch, retained stats | Explicit classification; no accidental seat acquisition |

Add a coverage check when a new exposed entry is introduced. A declaration inventory helps detect omissions; it does not prove correctness of the guard or cover SDK callbacks automatically.

The [generator](../../AminScatter/tools/ui/generate.cjs) has both unguarded string replacements and stages with unique-anchor assertions, such as [retained-points.cjs](../../AminScatter/tools/ui/retained-points.cjs). Use unique-anchor assertions and generated-output checks for new licensing UI/status integration. Generate in an isolated staging directory and compare the result; do not hand-edit the generated controller or require an unrelated wholesale generator rewrite.

### C09 Add an explicit runtime lifecycle without changing host globals

**Observed:** Scatter's `DllMain` records its module handle; Analyzer's is a stub. `LibInit` is empty in the inspected bridges. [CyrusScatterEdit](../../AminScatter/src/edit_plugin.cpp) imports descriptors from `AminScatter.dlx`; it is not a second independent CS Edit engine. Analyzer is a separately built module. Startup scripts load the scene class definitions before scene opening.

**Recommendation:** keep class registration and scene decoding available without network access. Initialize the licensing runtime through a deliberate supported host lifecycle outside `DllMain`, with cancellation, refresh ownership and bounded shutdown. Do not add browser/HTTP initialization or thread joins under the loader lock. Microsoft documents the relevant [DLL lifecycle restrictions](https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-best-practices).

Define one intended runtime identity per process and a versioned ABI for Scatter/Analyzer. Do not accidentally create two stateful cores by statically linking a singleton into each product. Test independently installed and mixed-version modules. For any new dynamically loaded runtime, use deliberate paths and qualified dependency resolution; do not change Max's global DLL search behavior to fix our plugin. See [Microsoft DLL loading guidance](https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-security). Actual load-order behavior remains a Max experiment.

### C10 Establish release identity and durable credential ownership

**Observed:** [build_max.py](../../tools/build_max.py) currently packages Scatter 0.63 and Analyzer 0.14. CMake, native description strings and the controller schema use other version identifiers. Packaging deliberately substitutes legacy installer labels and creates content-addressed native directories. It writes hashes and a manifest and uses a fixed ZIP timestamp for reproducibility; the inspected flow does not sign that manifest or call a signing tool.

**Recommendation:** preserve the useful staging/hash checks, but add one immutable commercial release identity with explicit publication/update eligibility. Do not infer entitlement dates from file modification time, the fixed ZIP timestamp, CMake versions or Max's schema version. Keep Class IDs and scene migration versions independent. Sign final binaries before computing distributable hashes, then authenticate release metadata through the defined release channel; test the actual final package.

The [Scatter installer](../../AminScatter/installer/install.ms) and [Analyzer installer](../../CyrusSurfaceAnalyzer/installer/install.ms) install to separate user script folders; [Scatter uninstall](../../AminScatter/installer/Uninstall.ms) removes registration and asks the user to delete its program folder after restart. Put future account/device credentials and verified caches in a separate deliberate OS-protected data location, with account-switch, repair and uninstall retention rules. Sharing signed rights does not require sharing writable scene data or placing tokens beside replaceable binaries.

**Gate:** E08/E14/E17 cover Max 2026/2027 configuration, both product install orders, mixed modules, clean/restricted users, repair/reinstall, account switch and production/test trust separation. Build configuration is not runtime qualification. A full installer migration is not required before the first prototype.

## Changes to the immediate implementation packet

| Order | Small deliverable | Existing roadmap tests |
| --- | --- | --- |
| 1 | Convert this map into an operation/caller contract; reproduce changed parameters versus saved evaluation with fake decisions | E01, E15 |
| 2 | Define independent status, structured denial and operation admission; prove enable flags never represent license state | E04, E15 |
| 3 | Prototype denial before preview/PFlow reset and before shared CS Edit mutations; prove rollback and history behavior | E01, E13, E15 |
| 4 | Build the standalone policy/verifier and a same-product feature-extension fixture | E02–E04 |
| 5 | Qualify runtime lifecycle, ABI/load identity, credential ownership and release metadata before the Max/service pilot | E08, E14, E16, E17 |

This is detail under the existing L0/L1/L3 plan, not a separate roadmap. Core math, retained rendering, persisted IDs and the render transport need no speculative rewrite to start. Any larger native-state ownership change must be justified by the boundary experiment and the selected render/continuity policy.

## Validation limits

The document/evidence check passed: all 37 selected source fingerprints and local before-copies matched; the fresh 38-declaration scan matched; 24 licensing-related Markdown files and 267 local link destinations passed the structural checks. The local reproduction is `_local/maintenance/2026-10-02-licensing-code-audit/validate.py`, with its result in `validation.json` beside it.

Passing those checks does not demonstrate authorization, licensing resilience or renderer behavior. This supplies a static map of the reviewed paths; L0's runtime proof, all E01–E17 experiments and licensing security qualification remain pending.
