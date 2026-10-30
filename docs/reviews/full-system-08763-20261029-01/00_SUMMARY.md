# Independent full-system review — Cyrus Scatter 0.87.6.3

29 October 2026 · Max 2027 only · review and validation, no product changes

## Verdict

**The previous R1–R7 problems are addressed in the tested 0.87.6.3 snapshot, and the executed regression cases pass.** I did not reproduce the previous role-transition crash, hiding failures, fixed-part visibility mismatch or full-population transform copy. There is no newly demonstrated P0/P1 failure in this review. This is a scoped engineering pass, not exhaustive production certification.

**Concurrent-change boundary:** the final hash check detected later workspace edits to picking, native integration and several script templates. These are listed in [identity.json](evidence/identity.json), with old/new hashes. The completed runtime tests qualify the recorded build/test payload, **not those later edits**. Finding sources remained unchanged at that check. The final control inventory labels rows whose source differs from the tested snapshot.

The architecture is appropriate for this product: native placement storage and numerical work, shared prepared sources, immutable result ownership, native workers isolated from Max, and retained instanced graphics. MAXScript and managed code primarily own authoring, host coordination and UI. Replacing these boundaries wholesale, increasing limits, or moving contact fitting to CUDA is not justified by the evidence.

Two smaller defects remain:

1. **FS-01 / P2 — abandoned Scene-load copies escape staging recovery.** `PrepareScene` omits the process ownership marker; `RecoverStaging` consequently retains the copy after its owner exits. A disposable child-process reproduction retained a 524,288-byte copy. Published assets remained intact.
2. **FS-02 / P3 — current output reports obsolete product versions.** A new Scene preset created in the actual current host records `0.87.5.5`; the license dialog and missing-module messages still name `0.80.0`. These are provenance/support defects, not a demonstrated load incompatibility.

There is also a measured optimization opportunity: an edit affecting one plant among 8,192 already-posed plants takes **1.366 ms median**, while that plant's fit takes about **0.014 ms**. Whole snapshot bookkeeping and obstacle reconstruction still scale with retained state. The instrumented sample requests **8,272 allocations / 1,511,362 cumulative bytes**. This is much smaller than the repaired quadratic map-copy problem and should be prioritized against real scene costs.

The previous peak-memory qualification gap remains: the 256 MiB pose check describes result payload, not old/new generations plus worker scratch or process RSS. No OOM or leak was reproduced.

## Fresh evidence

| Check | Result | Boundary |
|---|---|---|
| Clean native Release build and CTest | **62/62 suites pass** | Max 2027 SDK, current source |
| Generated UI and generator tests | **379 semantic controls accounted; pass** | Source/mapping, not physical UI acceptance |
| Python tools / selected MCP boundaries | **155 + 84 tests pass** | Tools and mocked service boundaries |
| Managed Library | **244 transaction assertions pass**, supplemental unsafe-archive checks pass | Temporary stores; injected validator for standalone tests |
| Signed licensing | **10 groups / 954 assertions pass** | Ephemeral synthetic authority, no real grants |
| Native settings/geometry | **648 cases / 6,480 face comparisons**, max compact/CPU error **3.26901e-9 m** | Prepared two-blade fixture; not every topology |
| Incremental contact | **288 cases equal full recalculation** | Moves, disabled rows, neighbors, hiding, artistic responses |
| Sparse transforms | **500 cumulative edits pass** | Selection, compaction, immutable predecessor, receipt invalidation, invalid inputs |
| Fresh Max checks | Role transitions, hiding, display limits, selection, Scene save/merge/reload pass | Scripted private hosts, test-only trust configuration |
| Delivered garden copy | **6 controllers / 18,229 placements**, picking/navigation/held-input replay pass | Original scene hash preserved |
| Rendering | Small **192×192 Scanline** automatic posed-output render succeeds | Eight posed plants; not external renderer/material certification |
| Existing MZP | CRC, manifest, every payload hash and Max 2027 guard pass | Archive inspected; not installed |

The garden's 24 navigation submissions preserved placement epochs and retained stream counters. Twelve Edit moves and twelve scene-collider moves advanced plugin-reported displayed tickets without repeating source capture, preparation, collider cooking or layout construction. These are not physical mouse latency or GPU-presented FPS measurements.

## Identity and limits

Branch `codex/workflow-0.75`, HEAD `75c60d54dbfd736ffef135d211863516a63543a7`, plus the existing dirty/untracked working tree. The **638 build-input hashes** are preserved. The fresh build snapshot matches the earlier qualified source; the generated script used for testing and shipped MZP hash match the 0.87.6.3 qualification. The later working tree differs as described above; no fresh pass is claimed for that successor.

Host testing deliberately used the same product source with a **different ephemeral public licensing authority**. No owner key/token was read, no real grant was changed, and the shipped owner-trust binaries were not launched. Every private host's loaded paths/hashes and unchanged artist INI are recorded. There was no Computer Use, product implementation, version change, install, commit, push, knowledge refresh or website publication.

[Findings](01_FINDINGS.md) · [Coverage and architecture](02_COVERAGE.md) · [Performance](03_PERFORMANCE.md) · [Library](04_LIBRARY_AND_RECIPES.md) · [Licensing](05_LICENSING_AND_SECURITY.md) · [Reproduction/test report](06_TEST_REPORT.md) · [Recommended sequence](07_RECOMMENDED_SEQUENCE.md).

Physical controls/DPI/tablet use, an exhaustive settings cross-product, true device loss, process OOM, long-session soak, arbitrary plant topology, external renderers and other Max years remain unqualified. They are not silently included in the pass.
