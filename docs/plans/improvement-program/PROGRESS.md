# Remaining improvement program — execution ledger

Active goal: [complete user objective](OBJECTIVE.md). Enrolled 15 October 2026.
Baseline: `b23ed93f97af347b98b92b355660bdc3eeb0ef19`, branch `codex/workflow-0.75`, delivered Scatter 0.82.6. The user explicitly resumed Phase 6 for this program. Work begins with presets; no later feature is complete by enrollment.

## Current delivery

**I03 / 0.82.6.1 — delivered. I04 / provisional 0.83.0 — contract/source investigation.** I03 commit `f030fb33ea6eaed1815cc3cd561877cd9aadff67` is pushed on `codex/workflow-0.75`; `git ls-remote` matches. Search/categories/tags, stored thumbnails, cancellation, clear content/dependency summaries and owner-specific Save Everything failures preserve recipe fidelity, Paint bindings and passive browsing. Four procedural examples and their compatible scenes are included. See [delivery and acceptance](I03_08261.md), [exact qualification](QUALIFICATION_08261.json) and [package identity](PACKAGE_08261.json). Next: define and implement I04 direction controls and normal blending.

Contracts: F01, F04-F08, F09-F11. Native library scans operate on copied filesystem paths and metadata only, never Max scene objects. Explicit Refresh rereads content, even for same-size/same-time file replacement. Browsing never hydrates Paint. Search/page operations use the bounded in-memory index; no filesystem polling while idle. Thumbnail loading is explicit for the selected entry with byte/pixel bounds and resource disposal.

First version rationale: user-selected four-part development label 0.82.6.1 for the preset/browser follow-up. Scene schema/evaluation contract stay unchanged unless a reviewed authored-data change requires otherwise. Native capability and recipe-format decisions are recorded with implementation. Analyzer/MCP remain independently versioned.

## Required outcome ledger

| Item | State / next evidence |
| --- | --- |
| I03 browser/search/tags/thumbnails and clear preflight | Implemented and scoped Max 2027 qualification passed; see I03 handoff; physical artist acceptance remains |
| At least eight usable presets and accurate thumbnails | Four qualified examples delivered: meadow, woodland, mountain, painted spline borders. Four or more remain for later features |
| I04/P07 direction and normal blending | Started: inspect native basis construction, ownership/dependencies, final-radius acceptance and persisted recipe/settings inventory; no feature implementation yet |
| I05 copy/import variation policy | Pending; ownership/random identity and Undo audit |
| I06/P06 rectangular/staggered/hex grids | Resumed, pending; bounded domain and stable-cell oracle |
| I07/P08 paths/sequences/references | Pending; arc-length and seam/identity contract |
| I08/P09 transform and assignment maps | Pending; shared samples and final-radius acceptance |
| I09 shared terrain snapshots | Pending profiling trigger; record decision and extraction/memory evidence |
| I10 finer intermediate-result reuse | Pending profiling and dependencies; preserve masks/spacing/publication |
| I11/P11 adaptive viewport/lifecycle | Pending final feature matrix, heavy assets, memory and actual host evidence |
| I12 UV patterns/projection | Pending; domain/seams/overlap policy and numeric oracle |
| I13 authored Edit/radius recipes | Pending; exact authored correspondence and transactional transfer |
| I14 typed effects | Pending; bounded ordered operations and dependency rules |
| I15 asset packages | Pending; permitted content, dependency manifest, transactional import |
| I16 source animation/LOD | Pending; copied samples, time validity, bounded cache and renderer scope |
| I17 renderer adapters/edge trimming | Pending; explicit supported renderer/version/material/source matrix |
| I18 bounded expressions | Pending I14; grammar/types/units/fuel and failure retention |
| Max 2027 MZP for every delivered version | 0.82.6.1 archive verified and ready, not installed; continue for subsequent deliveries |
| Final EXE with presets/thumbnails/demo content | Pending; isolated fresh install/upgrade/failure/uninstall acceptance |
| Final docs, Git remote, supported matrix and user checklist | Pending complete program; per-delivery checkpoints required |

## Preservation and qualification

Unrelated pending work: landscape row in docs/README.md, LOGO.psd, Landing Page Design/, docs/plans/landscape-presentation/, presentation-studio/, website/prototypes/. Preserve these. Artist scenes/profile/installed modules are untouched. Use owned Max 2027 profiles only; no Max 2026, website deployment or external distribution.

Knowledge index remains stale; reuse direct current source evidence. Original 0.82.6 hashes and receipts remain historical. At enrollment no new host/native pass was claimed. Subsequent I03 progress is recorded below.

## Resume here

Read this ledger and actual Git state. I03 is committed/pushed, with its scoped receipt and package. Define and implement the I04 orientation contract using the original Forest-improvement specification. Do not mark later features complete from the preset delivery. Preserve the exact delivered script/native pair and historical receipts.

## I03 implementation evidence — 16 October 2026, active candidate

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

Artist guide, installation/build instructions, architecture, current navigation/backlog and curated website content now describe I03. Website docs:sync, docs:check and local build passed (existing large-chunk advisory retained); nothing was deployed. Commit `f030fb3` is pushed and verified. Final owned hosts 44208/49052 exited after guarded quitMAX; close markers exist. Their request waiters time out because process exit precedes a completion reply; observed exit, not timeout, establishes closure. Only artist PID 15780 and unrelated camera-task PID 42536 remained at verification. I04–I18/P06–P11, the remaining examples and final EXE remain incomplete.
