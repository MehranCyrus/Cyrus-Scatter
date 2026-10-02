# 09 — Results and decision ledger

**Status on 2026-09-28: NOT RUN.** No measured speedups, validated device support, or performance-qualified Max versions exist from this documentation pass. Replace empty fields only with actual evidence.

**October 1 update:** a measured Max 2027 CPU candidate is implemented. The [implementation report](../Performance_Implementation_2026-10-01.md), [persistent evidence](../Performance_Evidence_2026-10-01.json) and [upgrade test](../Performance_Upgrade_Test_2026-10-01.md) are the current engineering record. The original requirements, broad case table and design decisions below retain their historical context.

## Measured local candidate — 2026-10-01

**Scope:** synchronous CPU calculation and preview preparation in a saved heavy scene. Five warm measured full refreshes per state. This excludes automatic event scheduling, Analyzer duration, GPU frame completion and Corona rendering. Reference measurements are preserved from `build/scene-benchmark-v2-final`; the final binary is measured in `build/scene-benchmark-v4-final` after verifying the identical scene/recipe, trial count and frozen engine/script identities.

| Operation / state | Original median ms | 0.60 median ms | Time reduction | Ordered preview/render parity | Decision |
|---|---:|---:|---:|---|---|
| Controller refresh / base | 4,053.01 | 1,060.39 | 73.8% | Exact | Local test candidate |
| Controller refresh / right +150 cm | 4,022.92 | 1,095.00 | 72.8% | Exact | Local test candidate |
| Controller refresh / one Undo right | 4,020.33 | 1,169.07 | 70.9% | Exact | Local test candidate |
| Controller refresh / left −150 cm | 3,975.95 | 1,030.58 | 74.1% | Exact | Local test candidate |
| Controller refresh / one Undo left | 4,025.55 | 1,007.98 | 75.0% | Exact | Local test candidate |
| Clover placement / base | 1,605.39 | 131.76 | 91.8% | Exact | Retain source processing/CPU changes |
| Native 64k cluster / automatic | 38.54 | 19.70 | 48.9% | Exact double fields | Retain bounded parallel query |

All 60 saved-scene preview/render outputs match, including their row order, transforms and source indices. Every timed native output in the 17-case sweep matches the frozen reference at limits 1/2/4/8/12/0. Eight Scatter native suites, one Analyzer suite, Max source/worker/batch and save/reopen fixtures, recorder exports and 14 Python report regressions pass. Full refresh maxima across the five states are 1.04–1.22 seconds for the candidate; process peak memory was not captured by this harness. See the implementation report for raw sample paths, hashes and limits.

| ID | Measured decision | Remaining gate / reopening condition |
|---|---|---|
| D07 | Accept stable native source policy filtering and source transforms for 0.60 local testing | Artist appearance/point-policy/Corona retest; other hosts |
| D08 | Accept prepared closed-band constants and remove per-point LineBand copies | Larger boundaries, full orientation/CS Edit/lifecycle matrix |
| D09 | Use a private synchronous executor, automatic maximum four total participants | Corona contention and other CPU configurations; higher limits remain testable |
| D10 | Reject cluster cell caching and intermediate serial-return regressions | Only reopen with a demonstrated complete-operation benefit |
| D11 | Coalesce redraw within each Scatter node-event batch | Verify actual preview counts per edit; Analyzer batches can still trigger extra work |
| D12 | Defer OpenCL/CUDA compute; investigate remaining host/display costs and supported viewport instancing | New trace identifies a sufficiently large independent stage; GPU transfer-inclusive gate |

This completes useful parts of C01/C04/T01/T02 and the local benchmark infrastructure. It does not complete the entire M0–M4 host, renderer, memory or lifecycle qualification. Near-real-time interactive editing remains the next measured target.

## First artist retest of 0.60 — 2026-10-01

Recording `20261001-104244-f41dc684` uses the intended native module, recorder 0.2.2 and automatic CPU mode. Its saved scene hash, starting settings and initial counts match the earlier saved-scene recording. All 654 stages pair correctly with zero trace errors/loss; four named edit windows and 292 resource samples finish normally. See the [artist retest review](../Performance_Artist_Retest_2026-10-01.md) for the raw report and limits.

Clover preview median is **304.74 ms versus 1,496.30 ms** in the earlier manual session. Analyzer inclusive median is **1,108.31 ms versus 3,589.39 ms**, while child-excluded medians remain approximately 70 ms. These are observations from different movements/output populations, not an identical-edit speedup qualification. The artist reports an immediately noticeable improvement.

There are 111 layer previews across nine Analyzer calls, with additional repeated passes during revert. Final generated counts are 62,646 versus 52,143 at start; the unspecified Undo sequence does not verify return to original geometry. **Retain this useful exploratory recording and investigate dependency/rebuild ordering next.** Fixed three-repeat interactive edge/Undo, renderer contention and longer lifecycle/memory qualification remain open. Sampled peak private memory is 6.60 GiB; it is not a 32 GB qualification result.

## Subsequent viewport investigation - 2026-10-01

The [viewport guideline and evidence](../Viewport_Performance_Investigation_2026-10-01.md) records 3,900 measured steps across main, display-budget, profiling, prototype and control suites: 3,540 have no preview error; 360 Point Cloud steps retain a known BushesCenter sampling failure and incomplete display. In the main matrix, original Real-time and Manual modes measured 90.52 ms and 88.98 ms median per navigation step, with zero preview, Analyzer or PFlow rebuilds. Disabling only Scatter drawing measured 11.23 ms. A matched-count world-space batch prototype retaining original script plumbing measured 31.56 ms. Prioritize bounded proxy batching and a prepared redraw snapshot before GPU placement compute. These measurements include message processing and are not GPU-completed FPS; no production viewport fix was installed. Renderer and broader lifecycle qualification remain open.

## Requirements recorded from the user

| Requirement | Decision |
|---|---|
| Performance areas | Cover scatter/editing, viewport, Analyzer, render preparation and large scenes |
| Host versions | 3ds Max 2024 through current release, 2027 at this date |
| RAM | 32 GB minimum support/qualification target |
| GPU | Optional; document capability requirements and retain CPU operation |
| Current test assets/tools | User has not prepared the requested test setup/scenes yet |
| Workflow | Documents now; coding follows; no Git or subagents |

## Locally observed environment, not a qualification result

Read-only Windows hardware queries reported AMD Ryzen 5 5600X, 6 physical cores / 12 logical processors, approximately 95.9 GiB RAM, NVIDIA GeForce RTX 3090, and driver version string `32.0.16.1047`. This is one available host, not the minimum product requirement. OpenCL capabilities, available VRAM, renderer compatibility and actual performance have not been probed.

Earlier inspection found CMake 3.31.6, Python 3.11.13 and Node 22.14.0. A core CMake configure attempt could not find a Visual Studio instance. The default Max 2026 SDK header was absent. This does not establish that every possible compiler/SDK path or Max installation is absent; F01 must locate or provision the actual tools.

## Build and support matrix

| Host | Baseline builds | Candidate builds | Native tests | Max smoke/lifecycle | Performance on 32 GB | Release status |
|---|---|---|---|---|---|---|
| 2024 | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | Pending |
| 2025 | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | Pending |
| 2026 | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | Source target only |
| 2027 | Frozen reference | 0.60 local candidate | Scatter 8 / Analyzer 1 passed | Max 2027.1 batch passed | NOT RUN | Artist retest / broader qualification pending |

## Experiment card — copy for each task

```text
Experiment ID / backlog task:
Date / operator:
Question and nominated workload:
Expected mechanism (hypothesis):
Baseline build and source/binary/script hashes:
Candidate build and source/binary/script hashes:
Compiler, toolset, SDK, flags:
OS / Max update / renderer version:
CPU / cores / RAM / GPU / driver:
Scene or native fixture ID/hash / units / seed:
Requested and emitted counts / sources / triangles / segments:
Display mode / budgets / viewport size:
Backend / total concurrency / fallback reason:
Cold or warm-recompute or warm-cache:
Number of warmups and measured samples:
Baseline median / p95 / peak memory:
Candidate median / p95 / peak memory:
Raw sample file paths:
Stage breakdown and inclusive/exclusive interpretation:
Correctness fixture result / first mismatch:
Persistence / CS Edit / lifecycle result:
Small-case regression / renderer contention result:
Known evidence gaps:
Decision: ACCEPT / REVISE / DEFER
Reason / next action / person making decision:
Actual engineering effort:
```

## Broader qualification case table — still pending

| Case / operation | Baseline ms median / p95 | Candidate ms median / p95 | Total-time reduction | Peak memory before / after | Output parity | Decision |
|---|---|---|---|---|---|---|
| S01 scatter | — | — | — | — | NOT RUN | Pending |
| S02 projection/anchors | — | — | — | — | NOT RUN | Pending |
| S03 boundary work | — | — | — | — | NOT RUN | Pending |
| S04 spacing/final/layers | — | — | — | — | NOT RUN | Pending |
| S05 Analyzer | — | — | — | — | NOT RUN | Pending |
| V01 points build/navigation | — | — | — | — | NOT RUN | Pending |
| V02 geometry build/navigation | — | — | — | — | NOT RUN | Pending |
| E01 CS Edit | — | — | — | — | NOT RUN | Pending |
| R01 first/unchanged render prep | — | — | — | — | NOT RUN | Pending |
| R02 interactive rendering | — | — | — | — | NOT RUN | Pending |
| L01 lifecycle | — | — | — | — | NOT RUN | Pending |
| M01 32 GB combined scene | — | — | — | — | NOT RUN | Pending |

## Initial design decisions

| ID | Decision | Evidence / reopening condition |
|---|---|---|
| D01 | Measure and optimize CPU before default GPU enablement | Existing host/native mix and no timings; reopen order only if baseline identifies a strong GPU workload |
| D02 | Preserve existing placement/edit identity semantics | Fingerprint and ordered algorithm dependencies; see [03](03_Compatibility_and_Regression.md) |
| D03 | Synchronous bounded threading first | Existing synchronous API; add async only for measured remaining stalls |
| D04 | OpenCL point-transform prototype first candidate | Independent live path; change candidate if CPU baseline shows insufficient cost |
| D05 | Separate Max-year builds | Current 2026 assertions/installers and per-year SDK/toolchain needs |
| D06 | 32 GB is the test floor | User requirement; define practical scene envelope from M01 results |

Append measured decisions here, with links to raw artifacts. Do not silently convert a hypothesis into a supported-product claim.
