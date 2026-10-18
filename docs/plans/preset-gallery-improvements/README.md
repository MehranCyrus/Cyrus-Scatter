# Preset and gallery contracts

Current status and sequencing are owned by the [execution ledger](../improvement-program/PROGRESS.md). The declared PG01–PG08 subset and PG09 explicit scene reuse are delivered; PG09 broader Share/XRef/material adapters and PG10 authored/effect adapters remain pending. Ready preset loading adds new layers with included supported assets and preserves the existing setup. The [0.86.0 native delivery](../native-placement/DELIVERY_0860.md) requalified eight ready presets, Undo/Redo without package files and save/reopen.

| Maintained contract or evidence | Scope |
| --- | --- |
| [Artist workflow](ARTIST_WORKFLOW.md) | Save, browse, style, Add Layers and ready presets |
| [Format 5](FORMAT_5.md) | Recipe identity, revision and typed data |
| [Style contract](STYLE_CONTRACT.md) | Explicit selected groups and retained destination ownership |
| [Package contract](PACKAGE_CONTRACT.md) | Closed static mesh/Standard/PNG graph, dependencies and bounds |
| [Installer contract](INSTALLER_CONTRACT.md) | User/bundled library ownership and distribution |
| [Browser layout](BROWSER_LAYOUT.md) | Gallery navigation and presentation |
| [Validation](VALIDATION.md) | Required Max 2027 correctness, lifecycle, resource and failure gates |
| [0.85.3 ready loading](LOAD_0853.md) | Implemented asset-backed loading and retained Paint/terrain semantics |
| [0.85.2 UI correction](UI_CORRECTION_0852.md) | Historical Modify navigation and library sizing fix |
| [0.85.1 delivery](DELIVERY_0851.md) | Exact initial adapter qualification and limits |
| [Candidate history](PROGRESS_0851.md) | Earlier failures and iterations, not current instructions |
| [Actual Forest comparison](FOREST_RUNTIME_2026-10-16.md) | Bounded Lite 9.4.3 / Max 2027 observations, not proprietary implementation proof |

The supported subset includes action clarity/no-op numeric apply, bounded thumbnail browsing, explicit capture, revision-aware file maintenance, selective style projection, supported asset collection/import and MZP/EXE distribution. Unsupported authored Edit/radius/effects, arbitrary renderer graphs, automatic Paint transfer to incompatible terrain and broader XRefs do not become supported by being mentioned in a proposal. Contracts define required behavior; exact delivery reports define what passed.

The [archived original plan](../../archive/plans/preset-gallery-plan-0851.md) and [archived checklist](../../archive/plans/preset-gallery-checklist-0851.md) retain PG01–PG08 implementation detail and earlier statuses. Future acceptance below remains required and is not a pass. PG09/PG10 progress is updated only in the execution ledger.

## Remaining adapter requirements

### PG09 — shared/XRef asset ownership and material variants

**Artist outcome:** deliberately reuse or reference large source assets and select a supported material variant without duplicate imports or unexpected changes to other setups.

**Implementation plan:** extend PG07's explicit Merge/Clone policy with Share/XRef only through qualified adapters. Track content identity, dependency revision, ownership claims and external dependents. Never delete shared assets solely because one Scatter setup was removed. Detect same-path replacement and nested-file changes at explicit relevant refresh/host notifications, without idle full-tree scans. Material variants use supported renderer/class IDs and dependency manifests, not name guessing. Define nested population variation separately from root variation; reject unsupported nested graphs. Shader conversion, proxies and renderer plugins remain explicitly qualified combinations under I17, not universal conversion. Restore imported SDK policy state on every exit path.

**Performance:** V01/V07/V09. Reuse unchanged assets only after supported validity checks; compile/prepare only changed variants. Bound graph depth, cache ownership and memory. Repeated unchanged Keep-style apply must not cause another import or solve. An explicit duplicate Add Layers operation still creates layers; it is not an idempotent command. Offline network/XRef failure must not hang ordinary catalog browsing.

**Max 2027 acceptance:** two setups sharing assets; delete one; external non-Cyrus dependents; XRef unload/reload/missing paths; same-path different bytes; nested changes; duplicate material names; variant switch with unchanged placements; clone/save/reopen/Undo/Redo; unit and cancellation cases. Verify source changes recompute final radii/collision when required. No current static Forest trace substitutes for these tests. **Exit:** explicit shared lifetime/freshness with a published adapter matrix.

### PG10 — authored Edit/radius and effect preset extensions

**Artist outcome:** preserve explicitly supported custom placements/radii and reuse typed effects without silently dropping edits or confusing an editing mode with authored records.

**Implementation plan:** split PG10a (I13 authored records) and PG10b (I14 effects). Introduce neither while its underlying service is absent. Reuse each service's codec, full-width stable keys, coordinate frame, dependency declarations and failure contract. Authored data has explicit Keep/Append/Replace plus source/owner remaps. Effect operations have Insert/Replace Selected/Replace Stack with separate definition/instance/parameter IDs, order, values/defaults/curves and bindings. Content/schema changes must invalidate compiled/bound state even if IDs/counts are unchanged. Compile and validate before commit; never serialize VM cursors, live host pointers or caches. Expression-language presets wait for I18; they do not authorize a new compiler in this step.

**Performance:** V04/V07/V10. Budget authored item/effect counts, bytes and evaluation work. Unchanged definitions reuse compiled programs/bindings; changed parameter values invalidate declared outputs only. Source/scale changes update final bounds before acceptance. Browser summaries do not hydrate custom collections or compile effects. Account for Undo memory and the scoped native admission/history guarantees; broader B26 production limits remain in the backlog.

**Max 2027 acceptance:** maximum-width IDs, source reorder/deletion/remap, compatible/incompatible terrain, units, protected edits, effect ID collisions, current values different from defaults, same-ID changed code/schema, missing bindings, compile failure, pending Manual state, Undo/Redo/save/reopen/copy and repeated no-op style apply. Compare full authored records and resulting placements; injected post-staging failure must retain the previous graph/publication. **Exit:** separately qualified adapters; unsupported record types remain explicit blockers rather than partial saves.


Use the [version policy](../../Release_Versioning.md) when a future delivery is chosen. Save/load uses the existing plugin and data formats; the EXE packages distribution. Broader adapters require separately declared supported combinations and exact-pair Max 2027 evidence before artist documentation claims availability.
