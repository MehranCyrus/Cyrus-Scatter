# Native migration validation plan

**Required future tests, not passes.** No Max runtime, fault injection, performance test or compile ran during this planning task. Reuse the [0.85.4 receipts](../memory-0854/README.md) as historical witnesses, then establish a comparable N01 baseline. The active 17 October goal resumes implementation; the fresh pre-migration regression receipt is [recorded separately](BASELINE_0854_20261017.md). Required tests below are not passes by inclusion in this document.

## Test discipline and measurements

Use owned disposable Max 2027 profiles and scene copies. Verify the loaded script fingerprint, native hashes/paths, capability versions, Max/SDK version, build configuration, units, seeds, source assets and renderer. Never use the artist session for reset/low-memory/fault tests. Do not install the candidate in the artist profile.

Baseline and successor must use the same receiver, sources, Count/density, retry settings, display mode/limits, source point count, camera and Undo history depth. Use both simple low-cost sources (to isolate pipeline cost) and separately qualified heavy sources (to expose display/geometry costs). Do not compare point preview to full Mesh and call the difference engine performance.

Record separately:

- Stage wall time, end-to-end Update time, host main-thread blocked intervals, actual input-to-response latency and display preparation/upload time.
- Generated/attempted/accepted/shown/exact-output counts, complete ordered semantic fingerprint and stage keys/reuse counters.
- Script heap size/free and growth; script row/matrix/string materializations; native live/capacity/peak bytes by allocation owner; shared/pinned bytes and reasons.
- Process private commit, working set and available system commit, sampled during stages. Net before/after heap change is not peak allocation; working set is not owned storage or VRAM.
- History labels/depth, Restore/Redo calls, native bytes pinned per operation, released bytes after abandoned Redo and actual host history trimming behavior.
- Retained CPU display resources and upload counts; graphics estimates remain distinct from measured driver allocations.

Warm up separately, run at least ten equal warm repetitions for normal timing comparisons, report median/p95 and retain outliers. Record cold startup/first-use independently. For expensive 500k/1M cases use at least three repetitions and report each sample; do not label three samples a reliable p95. Keep diagnostics bounded and measure their overhead. Fingerprint/log work must be outside timing windows, or reported separately.

## Fixture matrix

| ID | Scene and action | Acceptance |
| --- | --- | --- |
| V01 | Empty/new controller, zero sources, zero candidates, disabled/hidden owners | Correct empty/pending display and ownership; no invalid native access |
| V02 | Plane and mountain; 5k→50k→90k→200k→5k, repeat; default 100 MiB script heap | Exact ordered output/radii/stats against baseline at each count; earlier unrelated Undo survives; no per-placement script expansion on completed native path |
| V03 | Two/three receivers, insertion/removal, reorder, fixed Count vs density, variation/copy | Correct quotas and preserved identities within existing conditional stability contract; no renumbering through compaction |
| V04 | New wrapper, copied handle, light GC, rooted native consumer, scene departure, DLL capability mismatch | No use-after-free/double-free/wrong-owner reuse; buffers remain only while legitimately pinned; fail before mutation on mismatch |
| V05 | Paint union/holes, inside/outside feather, density/scale curves, mesh R/G/B channels, UV mask, multiple Areas and Bands | All full transforms/IDs/anchors and accepted order match; Paint canonical bytes untouched; no seed-domain or filter-order drift |
| V06 | Rectangular/staggered/hex grids; initial/final Relax; three spacing scopes; protected edits; Auto/manual/override radii; accepted-target repair | Stable grid cells and protected ordering; same retry/neighbor counts, cleanup results and shortfall; explicit over-limit rejection |
| V07 | Two 30k layers → copy to 90k; Add Layers, reorder, disabled sibling; ready presets | Same ownership and Manual/Live behavior; all eight ready presets Load/Undo/Redo/save/reopen with complete source/Paint/channel dependencies |
| V08 | Ordinary parameter Undo, Manual pending, explicit Update, preset Load Undo, Edit/Paint interleaving | Correct settings and complete result according to each operation; no extra accidental Undo item or unrelated-history loss; ready-preset Undo/Redo needs no file reads |
| V09 | Open/close all main panels, change selection/layer, resize, scroll/drag, library browse, unrelated animation; 100% and 150% scaling | No placement/preparation/source extraction/upload from passive actions; correct input/navigation; warm latency no regression |
| V10 | Undo/Redo creation/deletion, abandoned Redo, Max history eviction, scene reset, reopen/merge, shutdown | Release derived native/script state after legitimate last owner; retain required history; no accumulating live generation leaks |
| V11 | Budget rejection and injected allocation faults at each named stage and commit site | Previous complete epoch/output/Undo survives; no mixed-layer publication; repeat normal Update recovers; rollback does not require large allocations |
| V12 | Point/centres/Mesh/three proxies; color-only edit; mode switches; sibling reuse; radius overlay | Same source frame, style and subset; retained buffers reuse unchanged content; staged failure retains prior display |
| V13 | Exact output/PFlow, render cancel, IR begin/end, time changes, source scale/offset/material/proxy, save/reset | Full transform/source/output count parity; one pinned publication per evaluation; no persistent full script transform arrays; release on lifecycle boundaries |
| V14 | Cached publication pages, stale page token, Bake/Undo/Redo, failure after partial node creation | Bounded page allocations and no solve on reads; detached rows; exact Bake transforms and single authored operation; cleanup and previous baked result behavior retained |
| V15 | Sustained Count/copy/Edit/preset cycles and idle | Stable memory ownership at equal final history states, preserved Undo, no periodic recalculation; no claim of zero growth while retaining deliberately increasing history |

Keep existing slope/altitude settings and formulas unchanged. Include their enabled and disabled fixtures only to prove transport parity and protected-edit handling. This is not slope/altitude improvement work.

## Failure injection points

Inject within owned nonshipping builds, without exhausting system RAM:

1. Request/size arithmetic and system-commit admission.
2. Evaluated input/snapshot acquisition.
3. Candidate buffer allocation and receiver combine.
4. Paint/transform/prepared successor creation.
5. Edit derived-state staging and authored history recording.
6. Radius/schedule lookup, spatial index, refill and cleanup scratch.
7. Accepted compaction and publication metadata/history sealing.
8. First and later owner display preparation, render-item allocation and known buffer failure paths.
9. Root/leaf install tail, Edit publication and post-commit observer notification as separate cases.
10. Output adapter acquisition, partial Bake and release/cancel.

At each failure capture prior and resulting full publication hashes, epoch, source/radius tables, Undo/Redo labels, authored pending values and owned bytes. A preflight failure is insufficient evidence for late atomicity. True OS allocator exhaustion, renderer/device loss and arbitrary third-party callback failure remain separately qualified limits; do not claim them from a custom exception test.

## Undo stress detail

Run with an unrelated scene edit before Cyrus operations, and verify it remains usable after undoing the Cyrus commands. Compare at fixed history depth as well as growing history. Repeat with Max's normal history configuration; never increase preferences or clear history to make the acceptance sequence pass.

For ordinary parameters: actual Count spinner callback, actual Update button, Live release scheduling, Manual pending Undo/Redo and cold copy. Coalescing must preserve the final value and intended number of artist commands. A scripted callback pass is not physical spinner-drag latency.

For CS Edit: select/move/rotate/nonuniform-scale/delete/copy 1, 100 and 10,000 instances; also select all. Repeat Undo/Redo, cancel a gesture, shrink Count then restore, remove/re-add a receiver, change topology and restore the original, clone the controller/modifier and abandon Redo. Verify exact copied GUIDs, source/anchor correspondence, transforms, protection and dormant state. Sparse commands should not retain population-sized copies of derived matrices; large commands can legitimately cost proportional memory.

For presets: Add to an existing setup and New Setup, Paint sidecars and native publication restoration. Remove/move the source package after Load in the owned test directory: Undo/Redo must not need to reread it. Abandon the undone creation and verify its derived buffers are released without clearing unrelated history.

Test `Restore(false)`, repeated Restore/Redo, nested/super holds and restore-record destruction. Validate `Size()` policy against actual Max 2027 history behavior. Record both conservative history attribution and unique physical allocations; do not mistake the sum of shared references for unique bytes.

## Performance acceptance and capacity

Required structural gates:

1. Completed native Update/preview paths allocate **zero full-population MAXScript row/matrix arrays**. Script cost scales with authored metadata and bounded query pages, not candidate count. Test counters must detect accidental array expansion.
2. 200k Count and multi-area Paint fixtures show a lower measured transient peak than the N01 baseline, beyond observed noise. Proposed engineering target: at least 25% less plugin-attributed placement/scratch peak; this is a goal to validate, not an advertised saving. Report process commit separately and investigate if it increases despite local savings.
3. Ordinary sparse Edit operations retain history proportional to changed authored state plus explicitly accounted shared pins, without copying every derived transform. Preset before/after snapshots may legitimately retain whole generations; measure them honestly.
4. Warm unchanged Update reuses output; passive panels/selection/idle have zero placement, preparation and unchanged-buffer upload increments. Test 120 seconds of idle and a 60-minute mixed editing soak, including at least ten preset/copy lifecycle cycles.
5. No systematic regression beyond the larger of 10% or 50 ms in matched warm Update/panel tests; rerun noisy comparisons before judging. Cold UI construction is measured separately. A 200k solve lasting seconds must be reported as such even if faster than before.
6. After abandoned Redo/scene reset and legitimate last-owner release, tracked live bytes return to the corresponding baseline within known bounded caches. Allocator capacity or OS working-set persistence alone is not a leak.

Capacity progression: 5k/50k/90k/200k first, then 500k and the existing one-million root bound with simple sources. Test sparse masks/high retry demand, ten populations sharing the cap, high receiver face counts and protected edits at zero quota. Above-cap requests must retain prior complete output and show the existing work-limit explanation. This migration does not raise any cap. Test larger cases only when the measured memory model admits them safely in the private host.

## Packaging and completion

Run the documented generated, native and Python checks against the final source. Runtime tests require the matching frozen script/native pair; restart only owned hosts after native changes. Qualify test fault builds separately and prove fault controls are excluded from shipping artifacts.

Create a runnable Max 2027 MZP and EXE with exact payload hashes/CRC, version/host guards and embedded payload verification. Provide **Scripting > Run Script**, then restart instructions. No artist installation is part of this work. Archive acceptance receipts with complete fixtures, identities, failures and exclusions. Update B26 only for the exercised boundaries; do not close unrelated renderer, long-history or physical-input gates on code completion alone.
