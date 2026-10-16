# Cyrus Scatter 0.85.1 — preset and gallery handoff

16 October 2026. **Ready for artist testing for the declared adapter subset.** This is a development handoff, not completion of every PG roadmap item or production certification. The [iteration ledger](PROGRESS_0851.md) preserves failed predecessors and their successors. Max 2027 only; the artist's running Max/profile has not been installed into or restarted.

## What this version adds

- A resizable collection tree and thumbnail gallery, following the user's Forest browser reference. Search, collection navigation, thumbnail size, list view and paging remain passive. Loading, saving and binding review have separate dialogs. Reopening a smaller saved window fits its actual restored client area.
- Explicit viewport thumbnails, Save Copy, Update Existing and metadata maintenance. Complete supported recipes retain ordered layers, values, curves, roles, spacing and receiver-bound Paint, including holes and fading. Pending Manual settings cannot acquire a falsely current captured preview.
- Selective Apply Style for supported setting groups. Destination terrain/models/Paint and identities stay intact by default. Identical effective numeric/style application creates no additional authored change or calculation.
- Portable packages for the declared static mesh, Standard/Blinn and PNG adapter. Export verifies copied dependencies; import stages independent source assets or explicitly reuses reviewed scene models/materials. Authored changes are transactional; Undo/Redo and saved scenes do not rely on the original package folder. Terrain/path roles remain explicit bindings.
- Eight original procedural example sets with actual-result thumbnails and matching editable Max scenes. Four garden rooms and Valley moss and rocky crests join the original six without rewriting their source data. These are replaceable demonstration models, not a vegetation asset collection.
- A common transactional installer engine for the MZP and unsigned Windows EXE. Both contain the exact same script/native/library payload and preserve personal recipes, activation and versioned recovery files.

No further Phase 6 work is included. PG09's XRefs, nested populations and material-variant browser remain unimplemented. PG10 depends on the separate I13/I14 authored-data/effect work; expressions require I18. This is a bounded library delivery, not completion of every PG or I roadmap item.

## Identity and contract changes

Baseline: `9f8cc157279b6e257f1f4a0eb6280fc75b0ea58c`, `codex/workflow-0.75`. Version 0.85.1 was explicitly selected by the user for this delivery. Scene schema **58**, 242 authored recipe fields, numeric-settings format **3**, grid/orientation capabilities **1** and calculation model `CyrusUnified1` remain. Complete recipe format/capability is **5**, library capability **3**, portable package capability **1**. Analyzer 0.14, MCP package/plan 0.73.0/0.73 and team licensing remain independently versioned.

Delivered script: `f695bf51f2a335140ad9fe82fe6e86fa7246b0e1f7d563d24c59e4aabf2338bf`. Native build `native-lifetime-04` is unchanged by the subsequent scene-cache and initial-window script corrections; its native inputs are separately rehashed. Main native: `015a21c8b82d71a634754919aef1da20d703007402ee966ee278df06fbc03fc2`. Managed gallery: `4dc4809b6b7b0e86dc69a2bcfb5d217a199b8567ec51f91e358c61610e2324f5`. Installer core: `6651533cf07f0e5035223274614528170693a2c150802859df296195eac82b4b`.

Contracts: [format 5](FORMAT_5.md), [style](STYLE_CONTRACT.md), [asset package and memory admission](PACKAGE_CONTRACT.md), [installer](INSTALLER_CONTRACT.md), and F01/F04–F11 in the [engineering foundation](../../ENGINEERING_FOUNDATION.md). Local NTFS is the qualified file-publication scope; arbitrary network/filesystem atomicity is not claimed.

## Performance and lifetime changes

The browser indexes metadata and saved images only. Collection summaries are cached by content revision; page/collection counts are bounded. At most 128 tiles appear per page; decoded images are limited to 64 MiB and two pending decode jobs. Refresh is explicit. Closed galleries release their decoded cache, and scanning/decode timers stop after work.

Memory testing exposed retained arrays after imported New Setup creations were undone and discarded, and after Max detached a departed scene. The native Undo lifetime hook now releases transient caches only when an undone new creation is discarded and its owners have no scene-node users. Scene-departure callbacks capture owners before detachment and clear only departed owners afterward. Active owners and usable Undo/Redo retain their data. Cached schema conversion avoids repeated temporary allocations. Large explicit import/update operations can reject before unsafe allocation while preserving the previous publication and history; no heap preference increase or full MAXScript GC/Undo flush is used.

These fixes and guards qualify the measured library workflows. They do not close general B26, Add Layers lifetime pressure or every arbitrary host-allocation failure. A rejected heavy Update is visible rather than silently changing the result.

## Executed acceptance

- Native Max 2027 SDK: **39/39 suites**, 18.27 s; generated-source check: **296 controls**; final Python: **166 tests**, 14.30 s. Native evidence is not relabeled as a new build after the script-only successors. All 35 Python fixture files also parse successfully after the harness changes.
- Exact current script in owned `reopen-01`: all eight consecutive example loads, complete Paint and placement-row equality, departed-cache release, no stranded holds and Undo/Redo pass. The complete functional suite passes no-op/curve/style, persistence, 60 captures, pending/stale capture handling, mesh/PNG fidelity, Scanline pixel equality, explicit reuse, rollback, preparation/cancellation and memory-pressure rejection.
- Owned copied-EXE recipient `dbb3c981`: actual Install handler, installed startup/native paths, eight examples, the exact MZP wrapper and import review pass. Save, Details, Load and Style bounds/passive checks pass at 100% and 150%. Direct managed-control renders and separate native bounds verify compact reopen at both scales.
- Installer core: 22 owned inert-payload filesystem cases plus six actual process-exit/lock/cancel/upgrade cases. The last six repeat against the current payload in `installer-crash-d225f09722b545158458c63b6ab8bc49`. Actual EXE Install and core unregister are different witnesses; the EXE Unregister confirmation was not operated against the artist's profile.
- Current-pair sustained tests: **2 separate 30-minute/60-cycle gallery soaks** (copied EXE recipient and the 20,000-row terrain), plus **60 import/reuse cycles over 3600 seconds**. Full publication/work witnesses stay unchanged during browsing; closed owned image caches are empty. The post-terrain probe has matching preparation keys and no layer errors. [Qualification](QUALIFICATION_0851.json) pins each receipt; global process resources are not reported as zero-growth.

Whole-process GDI/USER/private-memory observations are recorded separately from the gallery's owned decoded cache. A bounded soak does not prove arbitrary session reliability, and scripted redraw timings are not presented FPS. Earlier script hashes retain their own results.

The heavy boundary remains explicit: with an unchanged 100-MiB MAXScript heap, the settled 60,000-row Update requests a conservative 137-MiB allowance and rejects before replacing the last result. It is not qualified as a successful 60,000-row editing workflow. The separately labeled 20,000-row/180,000-face fixture has matching preparation keys and no layer errors before and after the soak; its passive 120-second Manual/Live checks and 30-minute gallery lifecycle pass. The new conservative guard can reject work the previous build attempted; it is a safety tradeoff, not a capacity increase. The revised witness uses the native hash of all ordered placement fields instead of creating large numbers of temporary Python/Max wrapper values, and does not force Updates as part of browsing.

Thirty-query L10K metadata search measurements on the current pair: copied recipient at configured 150% has median/p95/max **44.48/71.90/81.69 ms**; the separate 20,000-row terrain fixture at 100% has **26.36/43.51/48.08 ms**. Both stay within the declared 100-ms p95 target with unchanged full publication and work/upload counters. These runs differ in scene, scale and process state; they are not a controlled speedup comparison. Thumbnail completion is asynchronous and is measured separately.

## Artist acceptance and remaining scope

Follow [the artist testing checklist](USER_TESTING_0851.md) and [library workflow](ARTIST_WORKFLOW.md). Check real mouse/keyboard navigation, actual Windows 150% scaling, 4K/mixed-monitor moves, your renderer and your production models. The current rendered material witness covers Max 2027 Scanline/Standard only; it does not qualify Corona, V-Ray, Arnold or their proxies/shaders.

Unsupported asset/controller/format combinations reject rather than silently discard data. Complete saving of authored Scatter Edit/per-instance radius records awaits its adapter. Paint is saved but remains bound to compatible receiver geometry/frame/units; it does not automatically transfer to arbitrary terrain. Imported texture retention and previous recipe revisions intentionally occupy disk until a separately designed cleanup workflow exists.

Physical disk-full/ACL behavior, non-NTFS/network installation, signing, arbitrary locale/profile layouts and additional Max versions remain unqualified. Website source updates/builds are separate from publication. Ignored installers, binaries and `.max` scenes are not stored by Git.


## Installers and testing

- [Max 2027 MZP](../../../dist/CyrusScatter-0.85.1-20261016/CyrusScatter-0.85.1-Max2027.mzp): **5,090,432 bytes**, SHA-256 `4ec70254dce2bce44a72b8db2ce1a984c76b16faf97563e2fbe8f30e5aee4b24`.
- [Unsigned Windows EXE](../../../dist/CyrusScatter-0.85.1-20261016/CyrusScatter-0.85.1-Max2027-Setup.exe): **5,126,144 bytes**, SHA-256 `172abbe59f4209949154367501a9be89879daa483de91c61153f1ad4411c9a34`.
- [Exact payload/package record](PACKAGE_0851.json) and [qualification record](QUALIFICATION_0851.json).

Save your work. Choose **Scripting > Run Script** for the MZP, or use the EXE with an initialized Max 2027 profile. Then restart Max 2027. Both routes install the same complete pair and eight examples; choose one. Neither was run against the artist profile. Open **Layers > Recipes > Bundled examples**, then follow [the artist checklist](USER_TESTING_0851.md). The EXE needs Windows .NET Framework 4.8; no separate executable is required for everyday recipe saving.

Website `docs:sync`, `docs:check` and the TypeScript/Vite production build pass. Static checks cover 77 reviewed sources, 296 controls, 44 generated links and 42 navigation destinations; the 12 library documents have 81 valid local links. Vite reports its nonfatal >500-kB chunk advisory. This builds local website output only; nothing was published.

All three final owned Max hosts were closed after their checks, with closure markers and process absence verified. The artist PID 26972 remains running. A read-only check of its on-disk startup/macro wrappers matches the supported preceding 0.85.0 hashes; this is not an installation or a loaded-engine requalification.

Raw owned-host receipts, `.max` scenes, binaries and installers remain ignored local artifacts; Git contains source, contracts, example data/images and hash-pinned evidence summaries. Preserve the distribution separately when sharing or backing up the repository.
