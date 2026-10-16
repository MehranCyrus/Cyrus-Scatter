# Preset and gallery improvements — staged implementation plan

**Implementation authorized:** the subsequent user request starts the full plan with version 0.85.1. Follow [candidate progress](PROGRESS_0851.md); the planning-only statements below describe the preceding checkpoint.

16 October 2026. This plan originated as a documentation-only checkpoint. The subsequent user request authorizes its implementation as **0.85.1**. The [candidate ledger](PROGRESS_0851.md) records implementation and evidence separately; this plan is not release qualification. The [collection browser layout](BROWSER_LAYOUT.md) incorporates the user's later Forest screenshots.

The subsequent [0.85.2 UI correction](UI_CORRECTION_0852.md) addresses Modify background navigation and default library scale without adding another roadmap feature. Original PG01–PG10 contracts and qualification limits remain.

Baseline: Scatter **0.85.0**, scene schema 58, complete recipe format/capability 4, numeric settings format/capability 3, library presentation capability 1; branch `codex/workflow-0.75`, commit `9f8cc157279b6e257f1f4a0eb6280fc75b0ea58c`. That commit matches the remote branch. The [I06 handoff](../improvement-program/I06_0850.md) identifies the existing qualified package. Six procedural recipes, matching scenes and actual-result thumbnails exist; the larger program and EXE remain incomplete.

This is a detailed supplement to [I03/I13/I14/I15](../eleven-phase-roadmap/FOREST_IMPROVEMENTS.md) and [P10](../eleven-phase-roadmap/TODO.md), not a replacement roadmap. **PG numbers rank this library work approximately from easiest to hardest; they are not product versions or the original P-phase numbers.** Dependencies take precedence over rank. The [execution ledger](../improvement-program/PROGRESS.md) remains the current project handoff. [TODO](TODO.md) tracks this plan; [validation](VALIDATION.md) defines the evidence required for each future delivery.

## 1. What exists and what the research adds

| Area | Inspected Cyrus baseline | Remaining opportunity |
| --- | --- | --- |
| Settings presets | Typed numeric/curve categories, units, static-controller guards, seed policy and transactional apply | Avoid identical apply work; clarify category versus complete recipe semantics |
| Complete recipes | 242 allowlisted settings, ordered layers, compatible receiver-bound Paint, roles and spacing relationships; Add Layers/New Setup | Selective style application to an existing layer; safe updates to saved recipes |
| Browser | Search/category/tags, 128-row pages, file-only worker, selected-item PNG preview, Refresh/Cancel | Thumbnail grid, collection navigation and explicit preview capture |
| Persistence | Strict format validation, bounded Paint sidecars, hash-bound presentation; new-file recipe saves | Revision-aware Update Existing and recoverable management of owned files |
| Variation | Same/New copy, Saved/New recipe import, Saved/Current/New numeric seed | Explicit Keep/Saved/New policies for selective application and later nested assets |
| Assets | Scene roles must be bound; six matching `.max` demonstrations can be opened separately | Collect/package assets and stage supported models/materials into the destination |
| Authored Edit/effects | Complete save rejects unsupported authored Edit/radius or controller data; effect foundation is not implemented | Add adapters after I13/I14 establish their contracts |

Source anchors, inspected at the baseline:

- [Recipe UI/capture/import](../../../AminScatter/tools/ui/templates/recipes.ms): `CyrusRecipeCapture`, `CyrusRecipeImport`, `CyrusOpenRecipeLibrary`, Save/Review/import handlers.
- [Numeric apply/write](../../../AminScatter/tools/ui/templates/presets.ms): `CyrusPresetApply`, `CyrusPresetWrite`.
- [Recipe codec](../../../AminScatter/src/recipes.cpp): `validate`, `currentDocument`, `writeNew`, `read`; [field inventory](../../../AminScatter/src/recipe_fields.inc).
- [Catalog](../../../AminScatter/src/recipe_library.cpp) and [limits](../../../AminScatter/include/recipe_library.h): scan/page, sidecar integrity, cancellation, thumbnail lifetime.
- [Current examples](../../../AminScatter/library/README.md), [I03 evidence](../improvement-program/I03_08261.md), [I05 variation evidence](../improvement-program/I05_0840.md), [format 4](../improvement-program/FORMAT_4.md).

The local knowledge index is stale; this recipe template is not enrolled in its path results. These findings use direct source inspection. No index refresh or new Max run forms part of this planning task.

### Forest evidence and its limits

The sibling [library research](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/37_LIBRARY_MAX_PRESETS_SUMMARY.md>) traces a selected Forest Pack Lite 9.4.3 / Max 2027 native path. It finds selective style transfer, target General/surface retention, eligible effect tables and XRef-based acquisition. It does not establish complete cloning or arbitrary Pro behavior. Its 17 indexes / 341 entries are catalog observations, not 341 successfully imported full presets. Offline evidence checks and SDK compile probes are not host round trips.

The [preset proposal](<F:/Cursor/_Cyrus_Apps/Forest Reverse/design/11_PRESETS_AND_LIBRARY_SPEC.md>) and [asset-import proposal](<F:/Cursor/_Cyrus_Apps/Forest Reverse/design/12_LIBRARY_ASSET_IMPORT_SPEC.md>) inform this plan; their M-numbered milestones are not Cyrus execution status. Their strongest lessons are separate document kinds, explicit apply policies, authored identity separate from variation, content freshness, dependency ownership and staged failure recovery.

Forest's public [browser documentation](https://docs.itoosoft.com/forestpack/forest-library/library-browser) documents a thumbnail grid, navigation, XRef/merge and material choices. Its [library editing documentation](https://docs.itoosoft.com/forestpack/forest-library/editing-a-library) documents Pro user libraries, asset collection and thumbnail capture. Use these as behavior references. Do not infer proprietary performance, adopt arbitrary imported scripts, or promise Forest-native file conversion.

## 2. Shared product and data contract

Retain [F01–F11](../../ENGINEERING_FOUNDATION.md): owners, independent collision scopes, conditional identity stability, Manual/Live semantics, bounded work, atomic publication, host-thread access, geometry/units and persistence. F12 also applies when an Analyzer role is present. A library operation must not silently Analyze stale terrain guides.

### Separate reusable content and actions

| Kind | Content | Allowed action in the relevant stage |
| --- | --- | --- |
| Numeric settings | Existing category values/curves and units | Apply to captured owner; seed policy only where relevant |
| Complete recipe | Supported ordered layer settings, Paint and relationships; external roles | Add Layers or New Setup, as today |
| Style selection | Explicit supported subset from a recipe, with retained-field policy | Apply Style to one existing layer in PG05; never infer replacement of Paint or custom records |
| Asset package | Recipe plus permitted assets, typed manifest, dependency hashes and optional thumbnail | Collect in PG06; import supported assets in PG07 |
| Authored/effect document | Explicit custom records or typed effect definitions/instances | PG10 only after corresponding I13/I14 adapters exist |

Keep schema, product, evaluation contract, document revision and presentation version distinct. Introduce new capability/version fields only for a real new contract. Reading, cataloging and thumbnail viewing must not rewrite older documents. Unknown future versions reject with useful diagnostics. Use narrow tested conversions where required, not speculative general compatibility.

### Apply policy

Complete recipe Add/New retains the current Saved/New variation behavior and creates fresh ownership. Numeric settings preserve their existing explicit seed choices. New **Apply Style** defaults to keeping destination receivers, Paint, seed/random-domain identities, layer order, visibility and external collision relationships. Users select supported setting groups before applying. Source replacement is excluded from the first style slice; PG07 adds it with explicit source remapping. Paint replacement stays outside style application until a separately reviewed compatible-coverage operation exists.

Capture owner identity, document content identity and the destination's relevant authored revision in a detached apply plan. Revalidate at commit after dialogs/asset staging; if the destination changed or was deleted, rebuild the review rather than applying to another owner. Reject missing/ambiguous roles, incompatible Paint, unsupported controllers and unsupported authored data before mutation where detectable. Later host failures must still roll back.

An authored import/apply transaction and a subsequent placement calculation are separate boundaries: a failed authored commit restores the previous graph/publication; a successful Manual apply retains the previous publication until Update; a later solve failure retains that publication while keeping the newly authored settings available for correction. Do not claim every external SDK operation can be rolled back until its adapter passes fault tests.

### File ownership and sharing

Keep user recipes separate from versioned bundled examples. A complete recipe currently references models/maps/paths; a matching demo scene does not make that recipe a self-contained asset package. PG06/PG07 close that gap for a declared supported subset. No thumbnail browsing can import assets. No implicit library MaxScript hooks or private diagnostic code enter shared packages. Permission to redistribute substituted assets must be explicit.

## 3. Order, dependencies and roadmap mapping

| Step | Difficulty | Deliverable | Prerequisites / existing roadmap |
| --- | --- | --- | --- |
| PG01 | Small | Clear actions and identical-settings no-op | Current P02/P10, I02/I03; F04/F08/F11 |
| PG02 | Small–medium | Responsive thumbnail gallery and collections | PG01 action model; I03/P10; F04/F06–F08 |
| PG03 | Medium | Explicit thumbnail capture and curated examples | Existing preview service; PG02 optional; I03/P10; F04/F08/F09 |
| PG04 | Medium | Safe recipe update, copy and metadata maintenance | Current codec; PG01; I03/P10; F05/F06/F11 |
| PG05 | Medium–large | Selective style apply to an existing layer | PG01/PG04 identity/revision contract; I15/P10; F01–F06/F09–F11 |
| PG06 | Large | Bounded asset manifests and portable export | PG04 revisioned publication; I15; F05–F07/F09–F11 |
| PG07 | Large | Transactional supported-asset merge and binding | PG05/PG06; I15; F01–F11 |
| PG08 | Large | Library distribution and installer qualification | PG06/PG07 supported package; final delivery workstream |
| PG09 | Very large | Shared/XRef assets and material variants | PG07 ownership; I15/I17 declared adapters |
| PG10 | Very large / dependency-heavy | Authored Edit/radius and effect preset adapters | I13 and I14; PG05/PG07; I18 only when its language exists |

Suggested implementation batches, once coding is requested: PG01–PG03 for everyday browsing; PG04–PG05 for authoring/reuse; PG06–PG07 for portable content; PG08 for an isolated installer pilot; PG09/PG10 when their dependencies are ready. Final EXE qualification repeats after the full supported feature set is frozen. This order does not mark I07 paths, B26 or other goal work complete or authorize their implementation in this documentation task.

## 4. Detailed steps

### PG01 — clarify operations and skip identical numeric apply

**Artist outcome:** distinguish a settings preset, complete recipe and future asset package. Applying already-effective settings with Keep/Saved values does not add an unnecessary scene edit.

**Implementation plan:** retain existing formats and defaults. Show type, included settings/Paint, external dependencies and the meaning of Add/New/variation near the action. Extend the existing apply preflight with a normalized effective-value comparison after unit conversion, seed policy and validation. Compare supported curve/editor data and spacing ownership flags as well as visible numbers. New variation remains an authored action. A no-op must not detach shared controllers, create an Undo hold, dirty inputs or rebind all panels. Animated/wired targets retain their current rejection rules; do not use equality to bypass validation. The baseline `CyrusPresetApply` unconditionally enters an Undo hold and marks inputs dirty; this is a source observation, not proof that caches subsequently run a full solve.

**Performance:** use V01/V04. Identical effective apply produces zero Undo entries, owner revisions, terrain/placement/preparation/upload work and full-panel rebinds. Compare bounded preflight time against the baseline on identical fixtures. Changed values still follow normal dependency work; preserve unrelated layers.

**Max 2027 acceptance:** invoke actual Amount/Transform/curve/spacing Apply handlers twice; compare full authored state and rows/counters after the second operation. Exercise pending Manual edits, Keep Current/Saved/New seed, shared static controllers, missing Look-at target, deleted owner and an animated/wired target. Verify no-op preserves earlier Undo history and real changes have one Undo/Redo with stored variation. **Exit:** useful action clarity and a proven no-op boundary, without a new serializer or product version selected by this plan.

### PG02 — a visual gallery with bounded work

**Artist outcome:** browse thumbnail tiles, filter collections/categories, change thumbnail size and retain a compact list option. Selection shows included layers/Paint, dependencies, format support and content status.

**Implementation plan:** reuse the file-only native index, search/page API and existing recipe service. Virtualize visible tiles plus bounded prefetch; do not create a control/image for every indexed entry. Keep callbacks bound to the captured controller. Key thumbnails by content identity and requested size, cancel obsolete requests, discard stale completions and dispose image/GDI resources. Keep folder selection and search separate from scene binding. Persist simple view preferences separately from recipe data. Do not add filesystem polling while idle or expose arbitrary multi-root mutation before its ownership rules exist.

**Performance:** V01–V03. Retain the existing 10,000-entry / 100,000-directory-entry / estimated 32-MiB metadata bounds. Initial proposed decoded-thumbnail cache ceiling: 64 MiB, plus at most two bounded decode jobs; account for transient buffers and UI/native handles separately. Start with small visible previews rather than decoding the entire library at full size. Adopt final measured limits before implementation freezes; failures/over-limit entries show placeholders. Cached search/page/selection handler target is p95 <=100 ms on the defined local fixture; cold indexing/decoding is reported separately. All passive scene-work counters remain zero.

**Max 2027 acceptance:** actual search/category/tile/list/zoom/page handlers; rapid selection while decoding; missing/corrupt/stale PNG; Unicode/duplicate labels; scan cancel/close/reopen; destination deletion and owner switching. Verify 100%/150% layouts and scrolling in the owned host. Repeat in Manual with pending edits and Live with heavy placements. Physical 4K/mixed-monitor behavior remains open until exercised. **Exit:** responsive visual browsing with bounded memory and no scene evaluation.

### PG03 — explicit thumbnail capture and useful examples

**Artist outcome:** choose an existing PNG or explicitly capture the current result; replace a thumbnail without recalculating scatter during ordinary browsing.

**Implementation plan:** default to an explicit viewport capture of a selected setup's existing publication. If Manual settings are pending, require an explicit Update-and-capture action or a clearly labeled published-result-only preview; never attach a stale image as if it represented newly saved pending settings. Record recipe/content identity, published-result fingerprint, capture method and relevant view provenance. Keep render-based preview as a separate explicit supported action; qualify renderer-specific capture later. Do not change artist cameras, selection, materials or global render options without restoring them, including cancellation/failure. Temporary scene content must be transaction-owned. Saving a PNG is separate from scene Undo.

**Performance:** V01/V03/V05. Capture runs once on request; list/search/refresh never captures or renders. Enforce existing 1024-pixel / 2-MiB file limits and bounded transient image storage. Time capture/readback/encoding separately from any explicitly requested Update. Discard stale completion if owner or relevant content changed.

**Max 2027 acceptance:** capture all six existing examples, inspect the actual image and compare it with saved/reopened content. Test empty/hidden setups, pending Manual state, changed camera/selection, cancel, invalid path and owner deletion. Verify normal state and resources after 60 capture/open/close cycles. Keep the original six scene/recipe/image witnesses unchanged. Add at least two distinct examples when their features exist: a genuine avenue sequence/gap example depends on I07; a formal garden may use current grids/Bands. Do not label Bands as direct path placement. **Exit:** accurate, explicitly generated previews with reproducible provenance.

### PG04 — safe update, save-copy and library maintenance

**Artist outcome:** Update Existing, Save Copy, rename and edit tags/description without accumulating accidental duplicates or damaging Paint. Bundled content remains read-only; editing it creates a user copy.

**Implementation plan:** extend complete-recipe `writeNew`; do not replace the numeric preset writer blindly. Separate stable logical recipe identity from content revision/hash and path. Save Copy gets a new logical identity; Update preserves identity and advances revision. Compare the expected old content hash immediately before replacement to detect another process's edit. Stage and validate all requested recipe/Paint/presentation data before one publication boundary. Use immutable referenced payloads and an atomic manifest/descriptor switch on supported local filesystems; retain the previous valid revision until recovery can be proved. Do not promise multi-file atomicity from several renames. Network storage gets a separately tested contract or explicit unsupported-update fallback to Save Copy. Clean only owned unreferenced staging/revisions; never remove an artist's chosen PNG or a shared attachment by filename alone. File management does not enter Max scene Undo. Deletion, if included, moves a user-owned entry to recoverable quarantine; permanent deletion is outside this slice.

**Performance:** V02/V06. A metadata-only update must not evaluate a scene, recapture Paint, decode every image or rescan all assets. Refresh only the changed entry/index generation after a successful commit. Full Save remains an explicit bounded operation. Before applying stricter whole-entry atomicity, document its difference from today's safe recipe save with a separately reported optional presentation failure.

**Max 2027 acceptance:** exercise actual Save/Update/Copy/rename handlers; reopen/import the result and compare settings/Paint bytes. Inject failure at payload staging, thumbnail staging, manifest commit and cleanup; test read-only/locked destination, disk-write failure, concurrent same-path edit, obsolete optional metadata removal, duplicate names and interrupted recovery. Previous complete entry remains usable; thumbnails must never silently describe another revision. **Exit:** recoverable revisioned maintenance with explicit supported filesystem scope.

### PG05 — selective Apply Style to an existing layer

**Artist outcome:** apply selected amount, layout, transform, filter or curve settings while preserving chosen destination content. Review states both changed and retained groups.

**Implementation plan:** introduce a reusable detached apply-plan path around existing typed validators and command/Undo logic. First slice targets one captured existing layer and supported static numeric/curve groups; any included node/map-dependent setting requires an explicit role binding. Do not invent a new file kind if an allowlisted projection of the current recipe is sufficient. Keep receivers, Paint, sources, layer order and collision relationships by default. Offer Keep/Saved/New variation with scope explained; Keep is the default for this new action, without changing complete-recipe Add/New defaults. Protect authored Edit/radius bindings: reject incompatible geometry/frame/domain changes until I13 supports transfer. Reject an unsupported group as a whole; never partially apply it under a complete-save label. Precompute the effective diff, unit conversion and dependency invalidation, then commit once. Source import/replacement waits for PG07.

**Performance:** V01/V04. Repeated identical Keep apply has zero scene mutation/Undo and no solve. A changed plan schedules one consolidated relevant update, preserves unrelated layer rows and reuses unaffected candidate/map/asset stages. Manual publication does not change until explicit Update. Large supported setting arrays have existing bounded admission.

**Max 2027 acceptance:** use a painted mountain destination and a different recipe; apply each group independently and in combination. Verify kept Paint/receivers/relationships exactly, including dormant data. Test units, missing/ambiguous roles, owner changes during review, invalid enum/future format, Save/New variation, new grid settings, protected Edit/radius rejection, Undo/Redo and save/reopen. Inject a failure after some setters ran and verify authored graph/publication recovery. **Exit:** explicit selective reuse with no implicit coverage/source replacement.

### PG06 — portable asset manifest and export

**Artist outcome:** choose a supported recipe and package its permitted dependencies for another scene/computer; see missing or external dependencies before export.

**Implementation plan:** define a closed manifest containing recipe/revision, typed roles, stable asset IDs, byte hashes, relative paths, units/frame, required plugin/renderer versions, redistribution declaration and an owned-file inventory. Begin with procedural/static supported meshes, declared materials and bitmap dependencies. Explicitly leave receiver terrains as roles unless a demonstration-scene option includes them. Preserve compatible Paint requirements. Do not silently flatten unsupported controllers/proxies/groups or claim arbitrary plugin support. Traverse a visited dependency graph, detect cycles, and reject unsupported edges with a role-specific explanation. Set numeric graph/file/byte/depth and extraction-memory admission before implementing the writer, using measured fixtures. Collect each shared file once. Use safe relative paths; reject traversal, absolute output paths, links escaping the package and case-insensitive name collisions. Verify content rather than path/mtime alone at explicit export/import boundaries.

**Performance:** V02/V07. Collect/hash only on explicit export or verification, with streaming bounded I/O, progress and cancellation. No asset traversal during gallery browsing. Measure files, unique bytes, graph size, peak staging storage and copied versus reused assets. Preserve current source files and restore temporary scene/SDK state.

**Max 2027 acceptance:** export a multi-layer Paint example with shared models/materials/textures, duplicate basenames in different directories, Unicode paths and declared units. Test missing/changed-during-export files, unsupported plugins, cyclic references, denied writes, cancellation and budget exhaustion. Open the resulting demo scene in an owned profile with original asset search roots removed and verify dependency resolution. PG06 alone does not claim gallery asset import. **Exit:** independently verifiable self-contained packages for the declared export subset.

### PG07 — transactionally merge supported assets and bind recipes

**Artist outcome:** select a packaged example, bind its terrain, import its supported models/materials and add layers or create a setup in one reviewed operation.

**Implementation plan:** extend PG05's plan with transaction-owned asset staging and PG06 content identities. First support Merge/Clone with explicit duplicate handling; XRef/automatic sharing waits for PG09. Validate plugin/class support, units and dependency budgets before host mutation where possible. Stage in an owned namespace and record every created node/material/map and changed temporary SDK option. Resolve source/role remaps before committing. Never treat material/node names as unique identities. A failed import removes only transaction-owned content and restores prior state; Undo/Redo restores recorded assets/identities without rereading the package or rerolling. Source replacement on an existing layer must either remap all supported dependent Bands/overrides or reject; preserve Paint. No imported MaxScript hook executes implicitly. Qualify host merge side effects rather than assuming a hold rolls them back.

**Performance:** V04/V07. Import each dependency once within the transaction; bound staging by declared file/mesh/host-object budgets and measure actual peak memory. File parsing/hashing can run away from Max; all SDK capture/import/commit runs on the host thread. State that a noninterruptible SDK call can only cancel at the next safe boundary. No partially imported layer is published. B26 is an explicit gate: reproduce pressure and fix it or reject safely before destructive mutation; warm-heap success is insufficient.

**Max 2027 acceptance:** blank and populated destinations; Add/New; same-name unrelated assets; missing textures; unsupported class; wrong units; owner deletion; scene changes during review; failures before/during/after asset staging and authored commit; one Undo/Redo; save/reopen; source replacement with Bands; external dependents. Verify graph/asset inventory and old publication after each failure, then successful recovery. Remove original library availability before Redo to prove it does not reimport. **Exit:** a usable asset package with demonstrated ownership and rollback for the supported matrix.

### PG08 — distribute the library and qualify the EXE

**Artist outcome:** install the qualified Max 2027 plugin and bundled presets/thumbnails/demo content, retain personal recipes across updates, and uninstall without losing user work.

**Implementation plan:** keep versioned immutable bundled content and a writable user library. Use the exact qualified native/script pair and hash inventory. Build a runnable MZP per delivered version and a Windows EXE pilot after PG07's package contract. Detect supported Max installations, report the destination, handle locked/running Max safely and give restart guidance. Preserve licensing/activation. Exclude test transports, credentials and artist assets. Define install/upgrade/repair/uninstall ownership before writing destructive installer behavior. A pilot EXE is not the completed goal: rebuild and requalify the final installer after all included feature deliveries. Code signing without credentials remains explicitly unsigned.

**Performance:** V02/V08. Extract/copy by the inventory with disk-space checks and bounded work. Installation does not generate thumbnails, launch scatter calculations or search an entire user drive for assets. Startup/library discovery remains within the browsing budgets with all shipped content present.

**Max 2027 acceptance:** owned destinations only: fresh install, upgrade from the previous supported package, repair, cancellation, insufficient space/permissions, locked modules, uninstall and reinstall. Verify exact loaded pair after starting the owned Max host, library discovery, thumbnail display, package import, persistence and user recipe preservation. Test paths with spaces/Unicode and install from a copied distribution without development folders. Do not install or restart the artist host. **Exit:** tested shareable installer for its stated support subset; final renderer/feature scope remains explicit.

### PG09 — shared/XRef asset ownership and material variants

**Artist outcome:** deliberately reuse or reference large source assets and select a supported material variant without duplicate imports or unexpected changes to other setups.

**Implementation plan:** extend PG07's explicit Merge/Clone policy with Share/XRef only through qualified adapters. Track content identity, dependency revision, ownership claims and external dependents. Never delete shared assets solely because one Scatter setup was removed. Detect same-path replacement and nested-file changes at explicit relevant refresh/host notifications, without idle full-tree scans. Material variants use supported renderer/class IDs and dependency manifests, not name guessing. Define nested population variation separately from root variation; reject unsupported nested graphs. Shader conversion, proxies and renderer plugins remain explicitly qualified combinations under I17, not universal conversion. Restore imported SDK policy state on every exit path.

**Performance:** V01/V07/V09. Reuse unchanged assets only after supported validity checks; compile/prepare only changed variants. Bound graph depth, cache ownership and memory. Repeated unchanged Keep-style apply must not cause another import or solve. An explicit duplicate Add Layers operation still creates layers; it is not an idempotent command. Offline network/XRef failure must not hang ordinary catalog browsing.

**Max 2027 acceptance:** two setups sharing assets; delete one; external non-Cyrus dependents; XRef unload/reload/missing paths; same-path different bytes; nested changes; duplicate material names; variant switch with unchanged placements; clone/save/reopen/Undo/Redo; unit and cancellation cases. Verify source changes recompute final radii/collision when required. No current static Forest trace substitutes for these tests. **Exit:** explicit shared lifetime/freshness with a published adapter matrix.

### PG10 — authored Edit/radius and effect preset extensions

**Artist outcome:** preserve explicitly supported custom placements/radii and reuse typed effects without silently dropping edits or confusing an editing mode with authored records.

**Implementation plan:** split PG10a (I13 authored records) and PG10b (I14 effects). Introduce neither while its underlying service is absent. Reuse each service's codec, full-width stable keys, coordinate frame, dependency declarations and failure contract. Authored data has explicit Keep/Append/Replace plus source/owner remaps. Effect operations have Insert/Replace Selected/Replace Stack with separate definition/instance/parameter IDs, order, values/defaults/curves and bindings. Content/schema changes must invalidate compiled/bound state even if IDs/counts are unchanged. Compile and validate before commit; never serialize VM cursors, live host pointers or caches. Expression-language presets wait for I18; they do not authorize a new compiler in this step.

**Performance:** V04/V07/V10. Budget authored item/effect counts, bytes and evaluation work. Unchanged definitions reuse compiled programs/bindings; changed parameter values invalidate declared outputs only. Source/scale changes update final bounds before acceptance. Browser summaries do not hydrate custom collections or compile effects. Account for Undo memory and B26.

**Max 2027 acceptance:** maximum-width IDs, source reorder/deletion/remap, compatible/incompatible terrain, units, protected edits, effect ID collisions, current values different from defaults, same-ID changed code/schema, missing bindings, compile failure, pending Manual state, Undo/Redo/save/reopen/copy and repeated no-op style apply. Compare full authored records and resulting placements; injected post-staging failure must retain the previous graph/publication. **Exit:** separately qualified adapters; unsupported record types remain explicit blockers rather than partial saves.

## 5. Delivery decisions and non-goals

No version is reserved or bumped by this documentation update. Follow [version policy](../../Release_Versioning.md#choosing-the-next-version) when the complete scope of a future delivery is chosen. Small fixes may use the current-series patch; substantial deliveries may advance the program series. Recipe, asset, presentation and native capability versions change only when their own contracts change. Never rewrite a frozen qualification receipt to claim a later feature passed.

No separate executable is needed for saving recipes; the EXE is distribution packaging. Cloud accounts, ML recommendations, a separate web artist-review gallery, Forest-native object conversion, arbitrary third-party library script execution, automatic Paint projection onto different terrain, a new curvature engine and unsupported renderer conversion are outside this plan. They are not required for the existing six examples to work.

Before a future step is reported complete: inspect the then-current source, freeze behavior/caps, implement authoritative sources, run affected offline checks, qualify the exact pair in owned Max 2027 profiles, update evidence/TODO/artist documentation, build and verify the MZP, and perform Git actions within the current authorization. Current task: docs only, no new tests/build/install/push implied. B26, unperformed physical DPI/input, broader renderer coverage and final artist acceptance remain visible gates.


## 0.85.1 delivery checkpoint

The subsequent implementation request delivers PG01–PG08 for their closed static recipe/mesh/Standard/PNG/local-NTFS contracts, plus PG09 explicit scene-model reuse. See [the handoff](DELIVERY_0851.md), [exact qualification](QUALIFICATION_0851.json), [package identity](PACKAGE_0851.json) and [artist tests](USER_TESTING_0851.md). PG09 XRefs/nested/material variants and PG10 prerequisite-dependent adapters remain open; the original plan above is retained as requirements, not a claim they all passed. No additional Phase 6 work is included.
