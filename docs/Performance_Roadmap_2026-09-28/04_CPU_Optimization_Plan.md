# 04 — CPU algorithm and memory plan

**Entry:** F/B foundation tasks complete; baseline fixtures and timings available. Priorities below are a source-informed starting order. Change order when profiling identifies another dominant stage.

## C01 — Prepare boundary queries once

**October 1 implementation:** evaluation-owned preparation now covers closed Analyzer band kinds 1/2; boundary orientation no longer copies an entire band for each row. Native source policy filtering and source transforms also moved out of per-row MAXScript calls. See the [implementation report](../Performance_Implementation_2026-10-01.md) for measured scope. General segment indexing and projected movement acceleration remain future tasks.

**Files:** [scatter.cpp](../../AminScatter/src/scatter.cpp), [final.inc](../../AminScatter/src/final.inc), [orientation.inc](../../AminScatter/src/orientation.inc), [edge_border.inc](../../AminScatter/src/edge_border.inc), [boundary_falloff.inc](../../AminScatter/src/boundary_falloff.inc).

Introduce immutable prepared metadata owned by the current evaluation: validated loop ranges, bounds, projected coordinates, normals, edge masks and original segment IDs. First remove `outwardAt`'s full `LineBand` copy using a kind override that does not mutate the caller. Cache `AreaMask` preparation where predicates repeatedly reconstruct it; the present object references its area rather than copying it.

Preserve lazy validation where an unused invalid band currently does not fail. Eagerly validating every unused band is a behavior change. Preserve first-band selection and original segment tie order.

Start with per-call reuse. Cross-call caching comes only after a complete dependency key exists: geometry/topology, transforms, time, loop/mask/settings revisions and ownership lifetime. Measure prep cost and query count separately.

**Exit:** boundary/invalid-input fixtures match; fewer preparations/copies are demonstrated; total affected operation improves without excessive retained memory. **Fallback:** bypass prepared data in development for differential comparison.

## C02 — Accelerate projected movement and anchors

**Files:** `scatter.cpp`, [spacing.inc](../../AminScatter/src/spacing.inc).

Use one immutable index per surface snapshot and reuse it across the relevant queries. Preserve valid triangle filtering and return both closest point and original face ID. Give the new call sites an explicit compatibility query policy; existing relax/final callers may depend on their current hint behavior.

For scan-compatible queries, use original face order to break comparator ties. Pruning must conservatively retain equal or numerically ambiguous candidates; anchor queries compare rounded lengths while movement compares squared lengths. Use strict bounds and a fallback candidate scan around ambiguous bounds if needed. Simply choosing the lowest ID under a newly changed metric is insufficient.

Benchmark index construction plus queries on small and large meshes. Keep linear scanning below the measured crossover. Reuse the snapshot only while all topology/geometry/transform/time dependencies are unchanged.

**Exit:** projection fixtures, normals and UV effects match; fewer triangle tests and total-time improvement in S02. **Fallback:** per-call scan mode.

## C03 — Index segment distance and containment separately

Build a deterministic segment BVH or equivalent for nearest distance in prepared boundary data, preserving original segment IDs and caller projection plane. Implement an independently verified containment accelerator (for example y-interval edge buckets that visit candidates in original order). Preserve crossing endpoint rules and boundary tolerances. Nearest distance does not answer parity.

Apply first to the measured dominant caller: edge rows, facing, final predicates, falloff `areaSide`, or Analyzer raster. Do not force one coordinate model on all callers: some use world XY, others loop-local planes. Preserve their existing behavior.

Kind-5 anchor membership queries can also scale with points times anchors; instrument and consider an exact spatial lookup using the current tolerance if this dominates.

**Exit:** tilted, nested, stacked, masked and threshold cases match; include index cost/memory. **Fallback:** direct segment traversal.

## C04 — Reuse native data and reduce allocations

Profile bridge mesh conversion and settings/Matrix3 packing across the real placement pipeline. Prefer an evaluation-scoped native context holding immutable mesh and prepared data before introducing persistent opaque handles or changing MAXScript APIs.

Keep existing 31-argument advanced and 10-argument fast entry points compatible. A new internal context must not hold unrooted MAXScript values or stale scene pointers. Validate source/time changes, recursive final evaluation and lifetime on errors.

Reuse bounded scratch arrays by evaluation or executor ownership; reserve from validated sizes with overflow checks. Avoid retaining stress-scene capacity indefinitely. Report scratch, cached and output bytes separately. Do not reserve `count * 100` candidates merely because rejection may attempt that many.

**Exit:** unchanged output and API behavior; measured allocation/conversion savings. **Fallback:** ordinary per-call ownership.

## A01 — Optimize Analyzer preparation and raster

**Files:** [analyzer.cpp](../../CyrusSurfaceAnalyzer/src/analyzer.cpp), [elements.cpp](../../CyrusSurfaceAnalyzer/src/elements.cpp), [bridge.cpp](../../CyrusSurfaceAnalyzer/src/bridge.cpp), [CyrusSurfaceAnalyzer.ms](../../CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms).

Measure element splitting, planar basis, boundary scans, raster, thinning, path fitting and final sampling independently. Prepare loop-local edge data and exact clearance queries once per element. Remove repeated plane conversion in `elements.cpp`'s `fits` predicate where safe.

Keep current automatic-mode choice, row-major largest-clearance tie, rectangle selection, ring construction, pruning thresholds and work guards. Parallel raster and per-element analysis follow [05](05_Multithreading_Architecture.md). Keep thinning pass barriers and ordered global spacing; the minimum-point override restores the prior global spacing state and force-inserts replacement points.

Bound simultaneous per-element raster allocations. If a later element fails during speculative analysis, report the earliest failure that the original serial pipeline would encounter, including earlier global-spacing/budget errors.

**Exit:** S05 and existing Analyzer tests pass; mode/path/count outputs match; no new automatic reanalysis during unchanged redraw/render activity.

## C05 — Optional SIMD after the preceding work

Inspect compiler vectorization diagnostics only for a measured hot loop. Candidate operations include packed preview transforms and independent distance arithmetic. Preserve scalar implementations and dispatch by CPU capability. Do not compile the entire plugin with a new AVX2/AVX-512 requirement.

Treat changes to fused operations, reciprocal/sqrt approximations or reassociation as compatibility risks. If exact placement behavior cannot be retained, restrict the experiment to display-only data under an approved tolerance. Accept only a measured gain after marshaling and packing costs.

## Work outside this file

Point/geometry preview and CS Edit caching are specified in [12](12_Viewport_Implementation_Plan.md). PFlow and render preparation are specified in [13](13_Render_Preparation_Plan.md). Threading is [05](05_Multithreading_Architecture.md). Do not optimize unused `pointCloud()` as a substitute for improving the live preview path.
