# 03 — Compatibility and regression contract

**Purpose:** prevent a speed improvement from changing an artist's scene. This contract applies to every optimization and backend.

## Output classes

| Class | Required comparison |
|---|---|
| Placement/identity output | Same count, source indices, row order, transforms, IDs and fingerprints; bitwise equality against the frozen baseline within the same host/toolchain configuration is the default gate |
| Classification | Same inclusion/exclusion, chosen face/segment, boundary side, density decision, collision winner, and minimum-point behavior |
| Display-only output | Same selected instances/points, colors, modes, budgets and picking; a GPU-only coordinate tolerance can be proposed for nonpersistent preview values with a bounded visual error |
| Persistence | Existing scenes and CS Edit storage load, round-trip, undo/redo and clone correctly; no field or class-ID churn for performance work |
| Errors | Same accepted/rejected inputs and deterministic first error where observable; no partial publication |

Cross-compiler/host equality is not assumed. Establish a reference for each supported host version after the minimal compatibility port. Also run shared logical fixtures across versions to detect porting changes. A mismatch cannot be dismissed as “close enough” if it affects an edit fingerprint or threshold decision.

## Determinism details from this source

- Keep `mt19937`, stream seeds and the exact order/number of random draws. Anchors currently consume a sample before replacing its position. Rejection paths and early acceptance affect subsequent draws.
- `Sampler` uses double cumulative areas and selects the first cumulative value strictly greater than the target. Preserve the original indices of valid triangles and zero-area filtering.
- Full triangle scans choose the first valid triangle at equal comparison distance. Preserve the caller's `length` vs squared-distance comparator; their rounding can differ. Do not blindly replace these queries with the existing hint-first BVH semantics.
- Neighbor queries use fixed cell traversal and insertion order. Relaxation caps visited neighbors; a different order changes forces even when all the same neighbors exist.
- Keep the arithmetic order inside each point's force sum, transform, and interpolation. Parallelize rows rather than individual summands first.
- Keep iteration barriers and convergence checks. For finite values, a maximum reduction can preserve the result; prove handling of NaN/invalid inputs and threshold ties. Preserve ordered summation for totals that influence behavior.
- Falloff density depends on original row indices. Retain those indices through parallel evaluation; compact in original order.
- Analyzer element order, row-major raster tie winners, path order, global exclusion spacing, and minimum-points replacement matter. Parallel local work must merge serially in original order.

## Golden fixture format — implement in B02

Use a versioned schema with explicit fields, not raw C++ object memory or decimal-only rounded matrix text. Serialize integer fields with defined widths/endianness and float/double bit patterns without padding. Store stage outputs before/after bridge float conversion, plus human-readable differences.

Each fixture records input hashes, seed, units, settings, compiler/FP flags, host version where applicable, row/source IDs, matrices, counts, selected faces, and expected failure. Hash the canonical serialization. On failure print the first differing field/index and absolute/ULP difference; a single hash alone is insufficient diagnosis.

The reference path remains available in development builds throughout migration. Fixtures must be captured from the unchanged baseline; do not regenerate expected output automatically when a candidate fails.

## Required regression families

| Family | Required cases |
|---|---|
| Sampling | Zero/one/many outputs, fixed seeds, interleaved degenerate faces, extreme area ratios, CDF threshold targets, weight zeros and density rejection |
| Projection | Shared edges/vertices, equidistant stacked faces, anchor distance near `1e-4`, projected movement, face normals/UVs |
| Boundaries | Nested holes, reversed winding, tilted/stacked loops, zero-length segments, masks, straight ends, corner blending, large coordinates |
| Spacing/final | Neighbor cap, equal distances, multiple iterations, convergence threshold, duplicates, blockers and ordered collision winners |
| Falloff | Side/edge thresholds, original row hash, empty output, combined filtering and scale |
| Preview | Zero samples, budget below total, sparse sources, exact flattened stride sequence, proxy/full modes, face budget skips |
| Analyzer | Single/multiple elements, ring/corridor/branch, invalid mesh, minimum overrides, work-budget errors, resolution extremes, deterministic first failing element |
| CS Edit | Stack/reorder, input transform change without `editRevision`, active layers, delete/restore, selection, clone, save/reopen, legacy chunks |
| Render/lifecycle | Unchanged render reuse, changed source/material/transform, IR burst edits, abort, save/open/reset/merge and undo |

## Persistence rules

Preserve the scatter class ID, CS Edit class ID, existing parameter names/types/order, and native storage chunks. This snapshot reads legacy chunk `0x3901` and reads/writes `0x4001`. Keep legacy behavior unless a separately specified migration is required. Performance mode should be machine/session configuration initially; do not add a backend choice to scene identity or force resaving scenes.

`cyrusEditFingerprint` includes placement position bytes and source information. Small numeric drift can invalidate edits. Test real saved stacks, not only naked scatter arrays. Regeneration with identical input must not request Reset Edits.

## Generator and build controls

Modify [AminScatter/tools/ui](../../AminScatter/tools/ui/generate.cjs), then regenerate from that project's working directory. F04 must first establish deterministic generation in an isolated copy and compare LF-normalized output with the checked-in production script. If it differs before any change, investigate and freeze the actual baseline; do not overwrite silently.

Keep compiler optimization and floating-point settings fixed during an algorithm comparison. SIMD/FMA or fast-math changes are separate experiments. Check worker counts 1, 2, and several larger limits, repeat runs, and vary scheduling grain to expose order dependence.

## Gate and recovery

A placement, persistence, identity, error-order, or classification mismatch blocks default enablement. Fix it or retain the reference path for affected cases. A deliberately different algorithm would need an explicit product/versioned-mode decision and migration plan; it is outside this compatible-performance roadmap.

Cache invalidation failures, leaked render nodes, deadlocks, and host crashes block release regardless of speed. Keep a baseline installer/binary bundle and test with scene copies as described in [08](08_Manual_Test_Runbook.md).
