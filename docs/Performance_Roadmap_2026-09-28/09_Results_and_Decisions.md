# 09 — Results and decision ledger

**Status on 2026-09-28: NOT RUN.** No measured speedups, validated device support, or performance-qualified Max versions exist from this documentation pass. Replace empty fields only with actual evidence.

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
| 2027 | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | Pending |

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

## Comparison table — no values entered yet

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
