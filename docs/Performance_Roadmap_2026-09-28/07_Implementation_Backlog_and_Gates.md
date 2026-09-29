# 07 — Implementation backlog and release gates

**All tasks below are NOT STARTED.** The documents and source snapshot are the completed planning deliverable. Task IDs describe future work; no listed feature switch, benchmark command, or export API should be assumed to exist.

## M0 — Reproducible builds and host support

| ID | Work / principal files | Dependencies | Done when |
|---|---|---|---|
| F01 | Locate/provision compiler, Max SDK/runtime and build outputs; record exact versions and hashes | None | Reference core builds and tests execute; no silent toolchain substitutions |
| F02 | Host-year CMake configuration, separate SDK/libs/artifacts, version adapters and both installers/uninstaller | F01 | Minimal source-compatible builds load in 2024/25/26/27; see [11](11_Platforms_and_Minimum_Requirements.md) |
| F03 | Add Analyzer core-only option around its Max module; keep scatter core-only path | F01 | Both native suites build without a Max SDK; host builds still work |
| F04 | Verify generator output in an isolated filesystem copy; make regeneration reproducible | None for Node check | Baseline difference is understood; generated source has a reproducibility check |

**Gate M0:** freeze immutable baseline bundles. Start measurement on 2026 if it is available first. Keep other host qualification explicitly pending; do not advertise full support yet. Missing host installs block host claims, not source-level fixture design.

## M1 — Measurement and behavior baseline

| ID | Work | Dependencies | Done when |
|---|---|---|---|
| B01 | Bounded native/script span timers, counters, cache reasons and JSON export | F01/F03/F04 | Inclusive/exclusive totals reconcile; disabled overhead is negligible and enabled overhead measured |
| B02 | Golden native fixtures and optional benchmark targets | F01/F03 | Stage outputs, edge cases, first-error behavior and serialization hashes are frozen |
| B03 | Versioned Max scene builders and manual test pack | Available F02 hosts | S/V/E/R/L/M cases from [02](02_Baseline_and_Benchmarks.md) are reproducible |
| B04 | Reference runs and priority decision | B01–B03 | Raw samples and top cost fractions entered in [09](09_Results_and_Decisions.md) |

**Gate M1:** choose the first measured bottleneck. No performance patch is accepted using only intuition or a microbenchmark unrelated to the production path.

## M2 — Independent CPU workstreams

Implement small experiments separately. Each compares against the frozen baseline and the last accepted build.

| ID | Work | Dependencies / gate |
|---|---|---|
| C01 | Prepared boundaries and eliminate per-query copies/repreparation | B04; exact boundary/error parity |
| C02 | Indexed anchors/projected movement with compatible face ties | B04; exact projection/normals/UV parity |
| C03 | Distance and containment acceleration, anchor membership if justified | C01 and B04; plane/parity/tolerance tests |
| C04 | Evaluation-scoped native data reuse and bounded scratch | B04; no stale data, GC or API compatibility regression |
| A01 | Analyzer boundary/raster/path preparation | B04; mode/order/global spacing parity |
| V01 | Actual point-preview reservation and stable grouping | B04; exact budget selection and display output |
| V02 | Bounded geometry shading cache; assess draw backend cost | B04; [12](12_Viewport_Implementation_Plan.md) gate |
| E01 | Complete CS Edit visible-cache invalidation | B04; stack/input/activity/undo/picking matrix |
| R01 | PFlow grouping, key costs and explicit node ownership improvements | B04; [13](13_Render_Preparation_Plan.md) gate |
| R02 | Incremental render updates only if supported and measured | R01; renderer identity/count/lifecycle parity |

**Gate M2:** retain only demonstrated improvements. An index that slows small inputs gets a measured crossover or is removed from that path. A cache that breaks invalidation is disabled until corrected.

## M3 — Multithreading

| ID | Work | Dependencies / gate |
|---|---|---|
| T01 | Optional serial/oneTBB executor, packaged runtime and limits | M1, F02; loader/teardown coexistence pass |
| T02 | Parallel native point transforms and/or a measured independent row stage | T01 + matching M2 task; exact output and size crossover |
| T03 | Parallel relax with fixed neighbor/order/barrier semantics | T01, B02; collision/final stay ordered |
| T04 | Bounded Analyzer raster or local-element work with ordered merge/errors | T01, A01; memory and first-error parity |
| C05 | Optional SIMD on a remaining measured kernel | Accepted relevant CPU task; scalar fallback and feature dispatch |

**Gate M3:** compare serial optimized vs threaded with several limits; no race/lifetime/persistence failures. Freeze a conservative default that passes renderer-contention tests. Broad threading of every loop is not the deliverable.

## M4 — CPU beta and full qualification

Deliver version-specific reference and candidate bundles, exact installation instructions, scene builders, raw diagnostics and a one-page change summary. The tester uses [08](08_Manual_Test_Runbook.md); record results in [09](09_Results_and_Decisions.md).

Required release coverage: all four host versions, 32 GB baseline hardware, Intel and AMD CPU configurations, CPU execution without OpenCL, intended render integrations, load/save/edit/undo/lifecycle checks. A developer-local beta may cover fewer hosts if clearly labeled; that is not completion of the requested support range.

**Gate M4:** all correctness gates pass; nominated user operations improve; required-case regressions are resolved or explicitly deferred with the affected optimization disabled. Do not hide small-scene regressions in an aggregate speedup.

## M5 — OpenCL experiment

| ID | Work | Dependencies / gate |
|---|---|---|
| G01 | Optional loader, device report and CPU fallback | B02 and accepted CPU comparison build |
| G02 | Standalone point-transform kernel and Max integration | G01; [06](06_GPU_OpenCL_Feasibility.md) correctness gate |
| G03 | Transfer-inclusive benchmarks, fault handling, renderer contention | G02; no mandatory GPU dependency |
| G04 | Conditional GPU beta and tested-device qualification | G03 passes total-time gate; otherwise close experiment with evidence |

M5 can be researched once the CPU comparison is stable, while outstanding host test access is being arranged. Default GPU enablement requires full host qualification for the claimed configurations. GPU progress must not delay useful CPU releases.

## M6 — Remaining responsiveness, only if needed

Measure remaining host stalls. If delay is event coalescing, tune it under render/update-storm tests. If synchronous compute remains the cause, write and implement the separate asynchronous job/lifetime design in [05](05_Multithreading_Architecture.md). If draw submission dominates, investigate a supported viewport display backend under [12](12_Viewport_Implementation_Plan.md).

Neither async updates nor a viewport backend rewrite is a prerequisite for accepting the earlier gains. Each needs its own input-to-display, correctness, memory and shutdown gate.

## Definition of a completed work item

1. Source target and behavior change are recorded; generated output is reproducible.
2. Meaningful relevant regressions pass, including captured old-scene behavior where applicable.
3. Before/after raw measurements use the same workload, build configuration and host.
4. Memory, failure behavior and small-input crossover are recorded.
5. An isolated switch or previous package permits rollback without altering scenes.
6. The result ledger records accept/revise/defer, the reason, and next step.

## First coding handoff

Start with F01/F03/F04, then F02's version configuration and B01/B02. Preserve current algorithms. Deliver core test logs, per-host build status, baseline fixture outputs, generator comparison and the first stage-timing report. Then build B03 scenes and run B04 to choose the first optimization. Do not start licensing changes in the same comparison build.

## Estimation policy

Estimate each accepted experiment after M1 identifies stage cost and F02 reveals compatibility changes. The research report's multi-week ranges are not a schedule commitment. Record actual effort alongside performance results; stop an experiment when remaining achievable total-time benefit no longer justifies its complexity.
