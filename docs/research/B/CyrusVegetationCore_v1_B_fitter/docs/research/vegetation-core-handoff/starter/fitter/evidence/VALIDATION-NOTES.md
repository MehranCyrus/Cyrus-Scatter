# Actual verification and evidence boundaries

Date: 2026-10-24 UTC. Owner B, edition `CyrusScatter_Vegetation_Core_Handoff_v1`.

## Retained runs

| Profile | Result | Receipt |
|---|---|---|
| GCC 13.3.0, C++20, Release | Configure/build exit 0; 19/19 CTests pass; CTest exit 0 | `executed/execution_summary.json` and associated logs |
| GCC 13.3.0, Debug, ASan+UBSan, leak detection enabled | Configure/build exit 0; CTest exit 8, 19 runtime failures with LeakSanitizer process-inspection fatal errors | `executed/sanitized_ctest.log` |
| Same sanitized executables, leak detection disabled | Configure/build exit 0; 19/19 CTests pass; CTest exit 0; no ASan/UBSan error reported | `executed_sanitized_without_leaks/execution_summary.json` and logs |

The failed sanitizer log includes inability to open `/proc/.../task` and
LeakSanitizer's note that it does not work under ptrace. This is an observed runtime
qualification failure; the handback does not claim a leak-check pass or infer a
specific host configuration beyond those messages. The successful rerun changes
the leak-detection environment option, not solver code, compiler instrumentation
or fixture acceptance assertions. All commands, environment overrides and exit
codes are retained. Leak checking remains unqualified.

The original combined runner therefore records
`all_invoked_commands_succeeded=false`; this is intentional. The subsequent
explicitly qualified rerun records true. The two records must not be collapsed
into a claim that every attempted execution passed.

The `compiled_input_hashes` arrays bind both execution summaries to the exact
production/test source, CMake files and frozen header. Documentation and packaging
changes after those runs do not change compiled code. Test timing lines are
ordinary CTest bookkeeping, not controlled throughput/latency benchmarks.

## Findings corrected before the retained runs

- Numeric/frame/unsupported-mode admission occurs before solver-sized allocation.
  The tight-memory admission-order test requires rejection without a query.
- Unknown residuals and contact counts use explicit infinity/max-value sentinels,
  including the outer fallback. JSON emits null for unknown values.
- Incoming response capacities are checked before per-string inspection, with
  cancellation between issues; sorting has bounded cancellation checks.
- The local contact denominator is scaled to distinguish a tiny positive mobility
  from an actually immovable endpoint gradient. The `u=1e-200` fake row ends as
  WorkLimit in the recorded run and does not claim a physical feasible scene.
- Length direction normalization divides components instead of forming an
  overflowing reciprocal for very small finite lengths. This removes an avoidable
  arithmetic hazard; it does not establish arbitrary subnormal-scale support.
- The deformed nonzero-roll test independently checks every 0.08-radian increment
  using vector/Rodrigues transport. It passes in both successful profiles.

The independent source-review notes retain their own review boundary. Where a
review says a new test was pending, the later receipts above establish its actual
execution. Reviews are not test logs and contain no newly executed engine result.

## Meaning of the tests

18 fitter test groups and one analytic-oracle group are registered. Multiple
subcases occur within groups; 19 groups is not a claim of 19 production scenes.
Every designated feasible solver test requires `ConvergedCandidate` and checks
root equality, original span lengths, actual full-segment primitive clearance,
unit tangent-aligned frames, source/generation/guide identity, immutable inputs,
reported residuals and budgets. The tests fail if those fixtures return any
failure status. Rejection tests deliberately expect their documented failure.

The authored 45-degree pose is an analytic existence/positive control and records
`fitter_executed=false`. It is never a solver initial guess or hardcoded answer.
The toy world's independently computed whole-span distances qualify those local
fixtures only. They do not certify another owner's backend or C's visible mesh.

R11–R14 original/report evidence remains report-local historical evidence.
Synthesis chapters 01/03/04/05/07/08/09 informed this module's scope and boundaries.
This handback does not relabel any earlier Python/Jolt/DCC/research result as a new
owner-B execution. No source-preparation, guide extraction, production rendering,
Max host or performance test was performed.

## Resource metric scope

The numerical records report high-water accounted payload bytes. They include
private buffer requests, explicit result capacity, inspected query return capacity
and declared fixed allowance. They are neither a measured process peak nor an
instrumented peak inside an opaque collision backend. The oversized-capacity fake
deliberately shows post-return WorkLimit. Frozen v1 cannot prevent the backend
from allocating that payload before B sees it. `CONTRACT_CHANGE_REQUEST.md`
proposes the coordinated resource interface needed to close that gap.

## Not executed / not qualified

- A's collision implementation, Jolt and combined A+B+C integration: unavailable
  to this independent module and intentionally not dependencies.
- C's canonical evaluator and independent visible-mesh validator: mandatory later.
- Max 2027, Windows/MSVC, production renderer, Bake/export and viewport delivery:
  outside this module; no host pass or image is claimed.
- Production asset library, broad scale/origin qualification, threaded orchestration
  and controlled performance/allocator instrumentation: not executed.
- SoftFrame and full-turn twist: unsupported, not silently approximated.
- Successful LeakSanitizer qualification: attempted but blocked as recorded above.
