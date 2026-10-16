# Preset/gallery performance and Max 2027 acceptance

Companion to the [PG01–PG10 plan](README.md). **Required acceptance, not a blanket pass.** Executed candidate results and remaining gaps are recorded in [PROGRESS_0851.md](PROGRESS_0851.md). [I03](../improvement-program/I03_08261.md), [I05](../improvement-program/I05_0840.md) and [I06](../improvement-program/I06_0850.md) remain the evidence for their exact historical deliveries.

## Evidence and host setup

Use Max **2027 only**, a fresh owned profile and disposable copies of scenes. Never reset, install into, restart or use the artist's host as a fixture. Record source HEAD plus dirty scope, native/script hashes and actual loaded paths, Max/SDK version, settings, system/display units, machine, display scale, renderer and source asset identities. Rebuild/restart the private host for a changed native pair. Serialize host mutations and inspect completion before retrying a timeout.

Use existing `tools/library_08261/`, `tools/recipes_0825/`, `tools/variation_0840/` where present and `tools/grid_0850/` after checking their current assumptions. Historical fixtures may assert an older inventory/version: select the intended cases and freeze new successor fixtures instead of overwriting old receipts or weakening assertions. Verify exact available harness paths before invoking. Pure tests alone do not prove actual UI handlers or SDK transaction behavior.

Do not change artist heap preferences or clear Undo to make tests pass. B26's low-headroom 60,000→90,000-row copy/update is an explicit failure reproduction, not a recommended user workflow. Warm-headroom runs are a comparison, not its fix. An importer must either preserve history through that boundary or enforce a demonstrated safe admission before mutation; arbitrary process-memory guesses are insufficient.

## Reusable fixtures

| ID | Fixture | Purpose |
| --- | --- | --- |
| C6 | Six bundled recipe/scene/PNG sets, copied with their original hashes | Current authored settings/Paint/variation/grid regression; actual images |
| L128/L2K/L10K | 128, 2,000 and 10,000 entries with mixed tags, categories, Unicode and duplicate labels | Bounded index, search, paging and image reuse; synthetic entries clearly marked test data |
| LBAD | Missing sidecars, bad PNG, wrong hash/size, unsupported versions, oversized documents and hostile relative paths | Typed errors and no unintended filesystem access |
| S | Small plane/mountain, three independent layers, Paint with holes/Bands, explicit spacing pair, shared source | Expected state changes and dependency isolation |
| H | Frozen 55,778-grid-row / 180,000-face I06 fixture and separate 60,000-row orientation/variation fixture | Comparable UI and stage timing; don't compare different controls as the same benchmark |
| U | Pending Manual edits, relevant/unrelated Live animation, controlled seed/domain changes | Publication semantics and passive work |
| A | Permitted static models/materials/bitmaps, shared dependencies and duplicate basenames | Package collection, staging, reuse and reference ownership |
| AF | Missing/cyclic/unsupported dependencies, same-path changed content, locked files and injected SDK failure | Recovery, content freshness and ownership cleanup |
| D | Owned 100%/150% Max UI layouts; later actual 4K/mixed-monitor/pointer fixtures | Bounds, text, focus, scrolling and real-device limitations |
| X | Isolated install destinations and owned Max profile without development asset roots | Fresh install, upgrade, activation boundary, portability and uninstall |

Use scene copies, not edited original demos. Keep C6 historical files and receipt hashes unchanged. Add future avenue/formal-garden fixtures only after their actual implementations; thumbnails must correspond to their saved results.

## Measurements and proposed budgets

Measure complete authored state, all placement fields and publication epoch separately from work counters. Include geometry extraction, map preparation, candidates, filtering, transforms/radii, acceptance, publication, preview preparation and uploads. Add file scan/read/hash/decode counts, asset import counts, affected owner IDs, Undo entries, process memory, native/cache bytes and GDI/USER handles where relevant. Reading diagnostics itself must remain passive.

Separate cold launch/index/decode from warmed operations. Use at least 30 observations for median/p95 on interaction handlers, document the percentile method and report the maximum. Use a fixed workload/order, then check a second order to expose cache dependence. Report scan/decode completion separately from the time to return control to the user. No redraw duration is presented FPS; no process-memory value is VRAM.

Historical comparison points, not new passes or universal performance promises:

| Recorded witness | Result | Correct comparison |
| --- | --- | --- |
| I03 L10K, 30 searches | median/p95 50.07/81.21 ms | Same local library, query set and host; new tile layout adds separate image work |
| I03 complete open/scan/decode/close, 60 cycles | median/p95 288.44/354.28 ms | Same full cycle, not just the open handler |
| I03 warm resource observations | GDI/USER stable from cycle 10 to 60; private memory rose ~7.8 MB after collection | Do not relabel as zero growth or multi-hour proof |
| I06 H, warm Layout toggles | 94.47/136.85 ms at 100%; 84.41/140.91 ms at 150% | Preserve unrelated panel responsiveness; these are not gallery timings |
| I06 heavy initial Update | 1,345 ms, 55,778 rows / 180,000 faces | Same scene/settings/pair; stage totals overlap and do not sum to total |

Proposed future acceptance targets, to freeze against an exact fixture before coding:

- **Passive actions:** zero new terrain extraction, map preparation, placement/filter/attribute/acceptance work, unchanged-buffer uploads or scene Undo. Cached presentation redraw is allowed. If a legitimate explicit operation needs work, classify it separately rather than weakening this gate.
- **Identical effective settings/style apply:** zero authored revision/Undo, controller replacement, dirty scheduling or full-panel rebind. New variation and duplicate Add Layers are not no-ops.
- **Cached metadata search/page/selection handlers:** p95 <=100 ms on L10K in the defined local warmed host. Measure image completion separately; use bounded background preparation and placeholders rather than hiding blocking work inside the metric.
- **Regression gate:** no reproducible >10% p95 regression against the same baseline fixture for unchanged interactions. If measurement noise overlaps the threshold, repeat bounded runs and report distributions; do not turn noise into a speed claim. A justified tradeoff requires an explicit recorded decision, not an unreported threshold change.
- **Gallery resources:** existing metadata caps retained; initial proposed decoded-thumbnail cache <=64 MiB, at most two decode jobs with individually bounded image inputs. Count transient decoded copies and UI/native handles separately. Freeze the final byte/pixel accounting before implementation; this is not a total-process-memory guarantee.
- **Cancellation:** request handlers should return within 100 ms in local controllable fixtures; record time until terminal cancellation separately. Noninterruptible SDK/remote I/O boundaries must be stated. Never advertise immediate interruption when only a later safe checkpoint can cancel.
- **Idle:** after deferred initial work settles, observe at least 120 seconds in Live and pending Manual with event-loop processing and compare complete counters/state. Repeat after browsing, import, Undo and close/reopen where applicable.
- **Lifecycle:** 60 open/decode/close or capture cycles; inspect resource slope after the first 10 warm-up cycles and after natural/explicit diagnostic collection. No monotonically accumulating owned images, worker threads, staging objects or claims. Follow with a 30-minute mixed-use soak for gallery delivery and 60-minute import/reuse soak for PG07/PG09. These bounded tests do not establish arbitrary session reliability.
- **Asset work:** freeze graph-node/depth/file/byte, evaluated geometry and peak staging limits before implementation. Measure cold/warm import/export separately. No generic millisecond promise for arbitrary asset files; cancellation, admission, ownership and zero idle traversal remain mandatory.

## V01 — passive browsing and lifecycle (PG01–PG03; regression all steps)

1. Load S and H in Manual with pending edits and separately in settled Live. Freeze authored/placement fingerprints, publication epoch and work/Undo counters.
2. Drive real dialog controls: open, search, category, list/grid, thumbnail size, page, select, folder choice, refresh and close. Refresh may read metadata/images, never scene geometry/Paint payload hydration or assets.
3. Exercise rapid changes while work is pending; delete the captured owner, change active layer, then close. Obsolete callbacks must not bind another owner or publish a stale image.
4. Perform 120-second idle and lifecycle resource checks. Confirm unchanged scene state and exact zero passive-work deltas. Record cold and warm times separately.

## V02 — catalog/filesystem robustness (PG02/PG04/PG06/PG08)

Test L128/L2K/L10K/LBAD; one supported root and a declared custom/network root separately. Cover uppercase suffixes, Unicode, empty query, duplicate names, same-size/same-time replacement, stale scan token, corrupt thumbnail, missing Paint payload, denied/locked folder, offline share and admission limits. Catalog metadata may remain readable when full import must reject corrupt Paint. Explicit Refresh detects content changes; passive idle does not poll. Cancel/close must release worker and file/image handles without touching scene state. Unsupported network guarantees stay open.

## V03 — actual gallery layout and image lifetime (PG02/PG03)

Test all affected controls at 100%/150% Max UI scale with long translated/Unicode labels, empty/error/populated states and smallest supported window size. Allow queued layout to settle across event-loop turns before bounds checks. Inspect owned full-window captures, focus/tab order, scroll reach and disabled-state explanations. Test rapid resize/zoom/scroll with a capped cache and corrupt/oversized images. Physical 4K, mixed-monitor transitions, mouse/tablet interaction remain separate acceptance until actually exercised; do not infer them from scripted DPI.

## V04 — settings/style/import semantics (PG01/PG05/PG07/PG09/PG10)

For each supported action, capture owners, IDs, receiver/source roles, Paint bytes/frame, enabled/dormant fields, unit values, variation, relationships, layers, published rows and asset inventory. Verify the exact declared diff and retained state. Exercise seed policies, curve editor domains, effective no-op, one real change, owner deletion/replacement, stale review, missing/ambiguous role and unsupported controller. Undo/Redo restores recorded choices once without re-reading disk or reseeding; save/reopen preserves them. In Manual the old publication remains; in Live one consolidated relevant update occurs. Test independent layers and relevant/unrelated animation. A complete imported recipe can change accepted placement through changed sources/collision context even with Saved variation: use identical inputs for exact-row comparisons.

## V05 — capture correctness (PG03)

Capture a known published C6 result; verify the image dimensions/hash and inspect it against the actual scene. Save/reopen/import the associated recipe to validate its content provenance. For pending Manual state, confirm no silent Update and no falsely current thumbnail. Exercise explicit Update-and-capture, cancellation, failed write, owner/content change during capture and any temporary camera/selection/material/render state. Check restoration on every exit. Render captures qualify only their tested renderer/method. Images remain optional; missing images do not corrupt the recipe.

## V06 — file transactions and recovery (PG04)

Use owned directories and injectable failure boundaries. For Create/Update/Copy/rename: fail after each staged payload/image, before manifest publication, after publication and during cleanup. Simulate a second writer changing the old hash; test interruption/restart recovery. Verify either the old or new complete entry is available under the supported storage contract, never a mixed revision. Confirm no modification to externally selected PNGs/shared payloads or bundled examples. Metadata-only changes preserve scene/Undo/placement. In-memory index errors cannot undo or corrupt a successfully committed file. Obsolete metadata/attachments follow a documented owned-file retention/cleanup rule.

## V07 — export/import ownership and atomicity (PG06/PG07/PG09/PG10)

Use A/AF in blank and populated destinations. Cover shared files, duplicate node/material names, missing/cyclic/unsupported edges, same-path changed bytes, units, path traversal/case collision, out-of-budget input and temporary global SDK options. Validate archive/document input without executing content. Inject failure before staging, mid-import, after reference binding, during authored commit and during later preparation/publication. Distinguish preflight rejection, authored rollback and later solve failure. Compare whole scene inventory plus previous published rows, not merely the number of layers. Owned staging must be gone; existing/shared assets untouched. Retry a valid operation afterward. Remove source package access before Redo. Exercise B26 headroom pressure and record admission/failure behavior rather than suppressing Undo evidence.

## V08 — installer and independent recipient (PG08)

Build a hash-pinned MZP and EXE from the exact qualified pair. In verified owned destinations test fresh install, upgrade, repair, interrupted/cancelled copy, locked/running Max, insufficient disk/permissions, uninstall and reinstall. Preserve user recipes, modified user copies and unrelated plugins. Verify installed hashes, actual loaded modules/script in a fresh private Max 2027 host, activation behavior, preset search/PNG decoding, opening demo scenes and package import with development folders unavailable. Inventory must exclude private transports/secrets and permitted-content declarations must match shipped assets. Record unsigned status if applicable. This test does not authorize normal-profile installation or external distribution.

## V09 — sharing/XRef/material adapters (PG09)

Verify two owners and external dependents before deleting one; shared assets survive until all legitimate claims are released under the declared contract. Test clone, save/reopen, Undo/Redo, missing/reloaded XRef, nested file change and same-name different content. Change only a supported material variant and compare placements/collision work; change source dimensions and require correct final radii/acceptance. Freeze renderer/plugin/material/proxy versions in the adapter matrix. Missing dependencies fail predictably; arbitrary network/renderer combinations remain unsupported until witnessed.

## V10 — custom records and effects (PG10)

Verify full-width keys, source/owner remaps, coordinate frames, protected records, Keep/Append/Replace, effect Insert/Replace Selected/Replace Stack and definition/instance ID separation. Test changed code/schema with identical IDs/counts, reordered parameters, values different from defaults, curves and binding deletion. Compile/type/units/fuel errors reject before commit where possible; post-staging failures recover. Numeric-only changes reuse compilation when valid; source/scale outputs recalculate bounds/acceptance. Browser summaries never compile or hydrate heavy records. Test both new and reused evaluation contexts. Execute only when the underlying I13/I14/I18 capability exists.

## Receipt and completion template

Every future PG receipt records: baseline and candidate identities; fixture hashes; declared changes/retained state; commands and actual handler invocations; cold/warm distributions; before/after work/Undo/resource counters; full authored/publication comparisons; failures and their successor fixes; 100%/150% captures; unperformed physical/renderer/network checks; package/hash; commit/remote identity when authorized; and next acceptance.

No PG checkbox becomes complete because a document exists, a screenshot looks similar or a test function was written. A scoped pass does not close B26, all original phases, final EXE or artist acceptance. This plan's own validation is limited to documentation links, scope/status consistency and preservation of product/historical files.
