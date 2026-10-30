# Findings and repair closure

All entries apply to the tested 0.87.6.3 source snapshot. The files causing these findings still matched at the final check, while other source files changed concurrently; those changes have no inherited runtime qualification. Exact affected-file SHA-256 values, machine-readable fields and closure records are in [findings.json](findings.json); the complete input identity is in [source-hashes.json](evidence/source-hashes.json). P0 is critical, P1 major, P2 normal actionable risk, P3 minor. Severity is separate from confidence and evidence status.

## FS-01 — P2 — Scene-load staging is never recognized as abandoned

**Type:** persistence/recovery. **Confidence:** high. **Status:** reproduced in the real managed implementation with a disposable child process. **Origin:** preexisting Scene-preset path, not introduced by the R1–R7 repair.

**Trigger:** prepare a native Scene preset for loading, then lose the owning Max process before merge/cancellation cleanup. Run Library storage recovery later.

**Expected:** recovery can identify and remove a dead owner's private load copy while keeping active loads, unknown folders and published assets. **Actual:** the copy has no ownership marker and is retained as unverified forever. Ordinary successful load/cancel cleanup still works. Each supported `.max` attachment can be up to 2 GiB; repeated interruptions can accumulate substantial disk usage. No published-content loss was observed.

**Cause:** `AminScatter/shared/SharedLibrary.Scenes.cs:61–63`, `PrepareScene`, creates `staging/scene-load-<guid>` and copies the file without calling `MarkStage`. `SharedLibrary.Management.cs:135–147`, `RecoverStaging`, intentionally retains directories without `.cyrus-operation.json`. This is a reachable mismatch between creator and recovery, not a reason to make recovery delete arbitrary folders.

**Reproduction:** `drivers/run_supplemental.py` compiles the unchanged managed sources and `drivers/library_probe.cs`. The child calls `PrepareScene` and exits without discarding the completed copy. The parent runs `RecoverStaging`. [Raw output](evidence/library-probe.log): marker false, zero recovered, one retained, 524,288 bytes remain. This fixture injects the native validator and uses inert scene bytes; it tests file lifecycle, not Max scene validity. The independent [actual Max Scene test](evidence/library-host.json) verifies the native-validator/save/merge path separately.

**Minimal repair:** call the existing `MarkStage` immediately after creating the load stage, within a cleanup-protected block. Keep the PID plus process-start identity and conservative recovery policy. No scene/recipe schema change or geometry recalculation is needed.

**Acceptance:** kill a disposable child after preparation; recovery removes its copy. A still-running child's stage and an unmarked foreign directory remain. Successful merge/cancel removes its stage. Repeat 20 cycles with unchanged published preset/asset hashes and no accumulated owned load directories. Risk is low if marker-creation failure also cleans its private directory.

## FS-02 — P3 — Saved provenance and license guidance name obsolete releases

**Type:** usability/maintainability. **Confidence:** high. **Status:** Scene metadata reproduced in managed and actual Max tests; licensing strings statically demonstrated. **Origin:** preexisting.

**Trigger:** save a new native Scene preset or open the license dialog/missing-native guidance in 0.87.6.3. **Actual:** the Scene writer claims `0.87.5.5`; license UI/guidance says `0.80.0`. **Expected:** current writer identity, or intentionally version-neutral licensing wording.

**Cause:** `AminScatter/shared/SharedLibrary.Scenes.cs:44–46` hardcodes `scatterVersion`. `AminScatter/tools/ui/templates/licensing.ms:3,13,22` hardcodes UI/package wording. `AminScatter/include/scene_preset.h:20` currently validates this field as text, not as an executable compatibility decision. Therefore this review does **not** claim that the wrong value caused incompatible geometry or rejected loading.

**Evidence:** [actual Max save/merge/reload](evidence/library-host.json), [managed reproduction](evidence/library-probe.log), and exact source hashes. The saved preset has five dependency nodes and retains the expected 1/500 placement counts after merge.

**Minimal repair:** feed the writer the verified build identity through an existing bounded interface, and use the same identity or neutral wording for licensing messages. Keep independent licensing-foundation versioning separate. Do not replace historical metadata when reading old presets.

**Acceptance:** a newly saved preset reports the loaded current version; source/generator/package guards agree. Older presets still load under their existing host/unit/schema rules. License messages do not direct artists to an obsolete package. Risk is low; support provenance improves without changing simulation or placement.

## OPT-01 — P2 opportunity — Local edits still copy and scan retained scene state

**Type:** performance. **Confidence:** high. **Status:** measured opportunity, not a new correctness regression or universal frame-rate bottleneck. **Origin:** preexisting; the previous review already identified global bookkeeping. This run adds a controlled scaling witness.

**Trigger:** move one collider slightly in a population where every distant plant already has a retained pose. **Expected optimization goal:** local fitting stays local and unchanged obstacle/pose metadata is shared where practical. **Actual:** one affected plant/two contact queries, but cost grows with total retained state.

| Already-posed plants and separate colliders | Median total, 8 warm samples | Instrumented cumulative allocation |
|---:|---:|---:|
| 128 | 0.0287 ms | 208 calls / 27,547 bytes |
| 1,024 | 0.1457 ms | 1,104 calls / 192,450 bytes |
| 8,192 | 1.36645 ms | 8,272 calls / 1,511,362 bytes |

At 8,192, the instrumented fit was 0.0142 ms. Allocation is requested cumulative `operator new` traffic, **not peak live memory**, RSS or GPU traffic. This fixture grows both persistent poses and separate colliders; it does not isolate their individual coefficients.

**Cause:** `interactions_engine.cpp:156–163` copies previous pose/count/warning containers and reconstructs `worldObstacles`; `:285–298` aggregates retained pose statistics and scans reuse. The fixed R3 path now borrows overrides and builds spatial indexes once; it is not the old quadratic map-copy defect. Preview and render packet paths also enumerate retained output and need separate host profiling before attributing their cost to this number.

**Reproduction:** `drivers/run_native_probe.py --benchmark`, fixed seed/shape/units, case `local-posed` in [benchmark.csv](evidence/benchmark.csv). One warm-up, eight ordinary samples, then a separately instrumented sample. Serial mode, unchanged current library.

**Minimal direction:** first retain unchanged obstacle slots and maintain statistics deltas; then evaluate chunked/shared pose-map metadata if profiling still justifies it. Preserve immutable previous snapshots, deterministic merge order and failure rollback. Avoid introducing a generic persistent-container framework without a measured need.

**Acceptance:** identical full-recalculation results, disabled/restore behavior, render/preview tickets and retained old snapshots; materially lower allocation growth (target at least 50% in this fixture) with no regression in small batches. Include an unchanged-evaluation control that returns the previous snapshot. Benefit to the real garden must be measured separately. Effort/risk: medium.

## GAP-01 — P2 qualification gap — Pose payload limits are not peak-memory admission

**Type:** test gap/resource accounting. **Confidence:** high about the boundary, unknown about failure frequency. **Status:** statically demonstrated, no OOM/leak reproduced. **Origin:** explicitly open in the previous review, not newly introduced.

`interactions_engine.cpp:253–298` constructs per-job poses, merges them while the previous snapshot exists, then tests aggregate pose payload against 256 MiB. `results`, old/new maps, worker temporaries, render requests and GPU generations have different lifetimes. Other admission checks are useful but do not make this post-construction payload test a process-memory ceiling.

**Artist risk:** unusually large prepared plants/contact populations can have a higher construction peak than the result limit suggests. This review did not trigger that condition and does not claim an observed crash. The bounded garden check is not a multi-hour leak test.

**Next acceptance:** instrument old/new/result/scratch lifetimes, add predictable pre-allocation reservations, and run controlled allocation-failure tests plus a bounded repeated-edit soak in a disposable host. Keep the previous complete publication on rejection; do not silently lower Count. An unaffected modest scene must keep identical output and comparable latency. Treat this as a release-qualification task, not permission to raise a cap.

## Previous R1–R7 disposition

| ID | Current conclusion | Fresh evidence and limits |
|---|---|---|
| R1 roles/neighbors | Fixed for reproduced transitions | Native Off/Collider/React cases and five Max transitions; retained neighbor preference no longer accesses a missing rig |
| R2 coverage reach | Fixed for tested modes | All four responses, Inside margin and Under-overhead; move-away restores; independent 288-case matrix adds neighbors/disable/moves |
| R3 map-copy churn | Fixed for original scaling witness | 1,024 edited neighbors: 39,856 calls / 1,358,775 cumulative bytes, instead of the historical >2.1M calls / ~286MB |
| R4 pose admission vs draw limits | Implemented and bounded host tests pass | Shared planner, idle/navigation/fallback union; 500 posed Max rows under five limits preserve pending Manual Count=777 and solve generation. No extreme-buffer/OOM/device-loss campaign |
| R5 fixed visibility | Fixed for mixed-source witness | Eight fixed vertices and 12 fixed triangles retained with covered roots; CPU/compact parity |
| R6 fixed render bounds | Fixed numerically | All fixed vertices including x=5.035m contained in envelope; small Scanline posed render succeeds, but does not render that entire distant-fixed fixture |
| R7 full-row copying | Fixed for tested consumers | One patch into 1M rows requests 208 tracked bytes; 500 edit/select/compact checks preserve identities and predecessors; ordinary Max Edit/selection checks pass |

Do not reopen these as current failures using the old formulas or old binary. Historical metrics and current measurements have different timing conditions; allocation counts establish the removed work more strongly than unmatched elapsed-time ratios.
