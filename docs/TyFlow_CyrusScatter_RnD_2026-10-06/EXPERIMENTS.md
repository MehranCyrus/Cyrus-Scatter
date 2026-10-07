# Executed experiments and next measurement protocol

6 October 2026. CPU-only source experiments; no computer-use, Max/Houdini/tyFlow execution, scene edits or package builds. Raw local diagnostics are in `build/rnd-072-20261006/`; curated receipts are [core probe](evidence/core-probe.json), [build commands](evidence/core-build-commands.json) and [Python tests](evidence/python-tests.json).

## Fresh correctness evidence

The pure core was built from current source with `AMIN_BUILD_MAX=OFF`, Release, MSVC 14.38.33130 and Windows SDK 10.0.19041.0. All **14/14** existing suites passed, including procedural, spacing, Brush/reference picking, threading, diagnostics, weighting and preview sampling. This does not test a renderer, driver or host callback. **140 Python tests** passed with zero errors/failures/skips; they cover typed contracts, transport, passivity, publication/diagnostic pages, offline study/ranking and metadata boundaries.

A new independent all-pairs oracle compared accepted indices, protected conflicts and rejection scope with `resolveVariable` in **500 deterministic randomized cases** (80 candidates, two external scopes, varying pins/target/XY-versus-3D/zero multipliers and gaps), plus three exact contact-boundary cases. All **503** pass. The oracle uses exhaustive pairs, no grid; it checks collision results rather than matching an implementation-specific data structure. It does not independently prove layer cleanup/refill or every host eligibility/transform path.

Twelve Brush fixtures additionally compare indexed replay with the existing full-replay reference at 25 locations each: **300 queries**, zero observed difference. This is partial differential evidence on flat connected meshes, not a new curved/occlusion/nonmanifold qualification. The existing native suites cover additional geometry cases.

## E1 — Radius variation collapses grid selectivity

Fixture: points spaced ten units apart on a line, radii 0.5, planar self rule factor 1/gap 0. Change only the last point to position `1e12`, radius `1e9`. It does not actually overlap any other point. The far outlier still changes the grid width globally.

| Candidates | Uniform: visits / ms | Far outlier: visits / ms |
| --- | --- | --- |
| 1,000 | 0 / 0.386 | 498,501 / 4.770 |
| 3,000 | 0 / 1.150 | 4,495,501 / 42.282 |
| 10,000 | 0 / 3.860 | 49,985,001 / 465.061 |
| 12,000 | 0 / 4.984 | Explicit failure at 50-million work limit / 467.579 |

Below the cap all rows are accepted; correctness agrees with the independent oracle. The last case intentionally verifies the bounded failure. It does not assert a Max publication rollback; that behavior has separate historical host evidence. Exact visit counts are the stronger result; single wall-clock samples vary with load/hardware. At larger output counts, this worst-case admission can fail even though no candidates physically collide.

Smallest next experiment: separate exceptional large radii from ordinary buckets or use deterministic radius bands, compare every result/reason to the all-pairs oracle, and count grid construction as well as neighbor visits. Do not remove the work cap or silently change contact/ordering behavior. See F2 in [findings](FINDINGS_AND_ROADMAP.md).

## E2 — Projected movement scales with receiver triangles

Fixture: 1,000 stable candidates on a 100×100 plane, offset `[0.25,0,1]`, projection off/on; surfaces contain equal-area subdivisions. Three runs per condition, median below. Every result remains finite, retains its candidate ordinal and has the expected Z. This is not an equivalence oracle for a future BVH's seam/tie choice.

| Receiver triangles | Projection off, ms | Projection on, ms |
| --- | --- | --- |
| 2 | 0.171 | 0.164 |
| 200 | 0.163 | 1.938 |
| 1,800 | 0.244 | 14.537 |
| 7,200 | 0.469 | 55.275 |
| 20,000 | 1.028 | 146.985 |

Source inspection confirms the exhaustive candidate×triangle loop. This path is executed by the product core despite the header comment calling it a reference and suggesting host acceleration. A count/work cap on later collision does not cap this earlier work. Reuse the existing nearest-surface BVH only after testing exact nearest-face/tie/normal/UV/anchor semantics against the exhaustive path. See F1.

## E3 — Brush preparation depends on footprint area

Fixture: 512/2,048/8,192-face connected planes; 64 or 256 stored non-path dabs; radius 2 versus 200 (covers the complete plane). Times include Field construction, not Surface construction or a Max gesture. No resampling expansion occurs in this fixture.

| Faces / dabs | Radius 2 build, ms | Whole-plane radius build, ms | Whole-plane link payload lower bound |
| --- | --- | --- | --- |
| 512 / 64 | 0.072 | 4.329 | 0.375 MiB |
| 512 / 256 | 0.277 | 16.472 | 1.5 MiB |
| 2,048 / 64 | 0.133 | 16.599 | 1.5 MiB |
| 2,048 / 256 | 0.484 | 64.422 | 6 MiB |
| 8,192 / 64 | 0.276 | 68.671 | 6 MiB |
| 8,192 / 256 | 0.983 | 265.964 | 24 MiB |

The lower bound is analytically `faces × dabs × (4-byte patch face + 8-byte face link)`. It excludes vector capacities, documents, centers, BVH/adjacency, allocator overhead and other retained generations; it is **not measured RSS**. Existing serialization/per-stroke limits do not establish a small aggregate derived-field allocation. Disabled strokes are resampled before their enabled check too. Large-radius history is a distinct workload from tiny-footprint painting. See F3.

## Test-fixture failure retained

The first probe stopped after completing the spacing experiments: it incorrectly expected raw `amin::scatter` rows to already have the host's `keyed` anchor flag. The raw core assigns `candidateKey`; `placement_identity.inc` attaches the flag/anchor in the bridge. The assertion was corrected to check the actual core contract. No product source changed. [First log](evidence/first-probe.log) remains; it is not a product regression or final pass.

The corrected fixture was linked to the same freshly built library; its SHA-256 is in the receipt. Existing native suites were not needlessly rebuilt/rerun after this fixture-only correction. Timing tables come from the corrected run. All wall-clock samples are local descriptive measurements, not a statistical performance guarantee.

## Reproduction

Run in a fresh ignored output directory with the installed pinned compiler:

```powershell
python docs/TyFlow_CyrusScatter_RnD_2026-10-06/reproduce/run_core_probe.py F:/Cursor/_Cyrus_Apps/CyrusScatter F:/Cursor/_Cyrus_Apps/CyrusScatter/build/rnd-review-repeat01
```

Do not replace a prior receipt directory. A future implementation must repeat only the affected fixtures plus meaningful contract/failure tests. The helper's `--reuse-core` is for this review's unchanged freshly tested library; it must not be used to qualify modified production source against an old binary.

## Next host/performance matrix — not executed here

1. Pin executable version, script payload, every loaded module's path/file hash, viewport backend, renderer, hardware, source complexity, units and geometry fingerprint. File hashes alone are not proof of immutable loaded memory if an on-disk file was replaced after loading.
2. Use disposable identical scenes. Compare disabled/Manual/Live with unrelated car animation, then separately animate a receiver/source/map. Select/unselect Scatter; selected-layer pages/popup closed/open; Point/Mesh/Proxy/centers; inside/outside/partly inside the frustum. Warm resource realization before counting unchanged uploads.
3. Measure generation, geometry extraction, keys/container scans, Brush preparation, collision/grid/cleanup/refill, CPU publication, UI construction/binding and draw submission separately. Record median/p95 plus raw samples and stalls. Measure presented frames independently; a synchronous `completeRedraw` sample is not FPS.
4. Vary instances, source faces, source/material groups, receiver faces, radius spread, dabs/coverage and refill rounds independently. Record rejection/shortfall and both retained and peak process memory. Include old+new generation overlap and GPU fallback/device recovery.
5. For a fair tyFlow comparison, use a static/history-independent placement workflow and the same actual geometry, visible instance count, camera, shading and output cap. Record free/pro license/thread restrictions. Compare build and warmed draw separately; comparing a reduced tyFlow Display mode with full Cyrus Mesh is inconclusive. No relative speed ranking exists yet.
6. Qualify actual DPI/resize/scroll/pointer behavior, docked/floating IR, renderer edits/save/reset and supported hosts as distinct gates. If computer-use remains excluded, report pointer/perceived-latency gates unavailable rather than replacing them with API calls.

Useful primary measurement models are tyFlow's [separate simulation/upload diagnostics](https://docs.tyflow.com/tyflow_objects/tyFlow/debugging/) and SideFX's [separate cook/script/thread/draw/frame sampling](https://www.sidefx.com/docs/houdini/commands/performance.html). They inform the protocol; no Houdini runtime dependency is proposed.
