# Scatter 0.86.8.3 / Analyzer 0.14.1

22 October 2026. **Max 2027 test delivery; scoped qualification.**

Implements the six authorized refinements in the
[approved order and scope](IMPLEMENTATION_PLAN.md). Scatter is 0.86.8.3;
Surface Analyzer retains its independent version, 0.14.1. New SDK builds and
host tests target **3ds Max 2027 only**. Schema 59, recipe format 8, internal
registration identities and the CyrusUnified2 calculation model are retained.

## Changes

### R1 — Analyzer compatibility and installation

The Analyzer package contains the current freshness implementation and matching
native validity support. Its contract primitive guards script/native mismatches
before redefining classes or callbacks. Scatter's compatibility message now
distinguishes installing software from recalculating an existing Analyzer.

The installer verifies payload hashes, writes an immutable script/native runtime,
then switches its owned registration/startup bindings. Failed publication restores
the previous bindings. Startup finds the script beside the native module actually
loaded by Max. Repeated installation uses the same verified runtime. A unique
backup makes the atomic startup replacement work with Max's .NET argument binding.

Analyzer analysis remains explicit in Manual mode. Relevant real-time changes
settle through the existing dispatcher. This release does not turn the planar
Analyzer into a general curved-surface analyzer.

### R2 — Optimized Paint spline exports

Painting > Export spline opens a captured export view with **Optimized** and
**Exact snapshot**, a world-unit maximum deviation, and output knot/error feedback.
The initial Optimized tolerance is 1 mm. Attached-surface exports default to Exact.

Reduction operates in native C++ on copied closed planar contours. It preserves
corner anchors, verifies original spans, tests contacts and nesting, and certifies
the final Max single-precision knots after the receiver transform. Ambiguous,
nonplanar or proof-limited cases retain Exact geometry with a reason. The optimizer
admits at most 200,000 input vertices, a 64 MiB conservative scratch envelope and
50 million proof/query work units.

**The original Paint remains unchanged.** Export does not publish placements or
write Paint. A changed receiver is refreshed through an independent native
capture, avoiding a source revision/cache change. The export dialog validates its
captured controller, Area, document, receiver and transform before creation.
Reset/open closes it and releases captured scene references. Node creation has
one Undo/Redo transaction. Original Exact/reimport metadata remains on Exact
attached snapshots; optimized ordinary splines do not pretend to contain that data.

### R3 — Dense spline Bands

The former quadratic clipping admission estimate is replaced by an explicit
per-operation work/storage governor. Derived points, records, intersections,
offset cleanup, output and traversal are charged before growth. Detached points
and partially linked allocations have unwind ownership. Limits remain finite;
the reported storage is a conservative admission envelope, not measured heap use.

Rounded queries share an immutable segment index. Narrow-phase distances and
EvenOdd membership retain their existing arithmetic. Sharp retains its separate
accuracy/offset limits. Exact redundant collinear points can be removed from
newly admitted dense clipping representations.

Bands use a bounded Bezier-control key, avoiding the legacy Area sampler's
16-samples-per-piece limit. Shared Path references are deduplicated: multiple
Bands on one Path do not multiply the aggregate knot count. The ceiling remains
8,192 total sampled vertices across unique active Paths, with separate field,
construction, query and outline limits. Dense geometry can still exhaust a real
limit; failed successors retain the previous complete result. Ordinary Area-mask
sampling and general curved-surface Bands are separate capabilities.

### R4 — UI/lifecycle regression infrastructure

The maintained [owned Max suite](../../../tools/quality_validation/README.md)
records loaded paths/hashes, unique run/request/scenario identities and required
assertion IDs. Missing, stale, malformed, duplicate, incomplete or empty results
fail closed. Timeouts preserve the original request for observation. Explicit
fixture successors preserve their preceding metadata; loaded product bytes remain
frozen. A changed product pair requires a fresh process.

Fixtures cover source/owner binding, reset, deletion/Undo, Point replacement,
clearance/Relax controls, visibility, Manual pending state, save/load, preflight
failure/retry, Bake and material access. An additional schema-58 fixture exercises
the actual Upgrade control, Undo/Redo, identity preservation and schema-59 merge.
Native control messages exercise handlers; they are not physical mouse/DPI proof.

### R5 — Maintainability

Native clearance predicates are named without changing scope or distance rules.
The source-clearance authoring block is extracted into an authoritative template
fragment. Build-time assembly rejects malformed, missing, duplicate, cyclic and
outside-root includes. The initial extraction expands byte-for-byte to its frozen
input. There is no runtime include or new MAXScript scope.

Qualification compilation is clean even on retry. This corrects a validation flaw
observed after an interrupted incremental `.inc` compile retained an old object.
Ninja builds have explicit module import-library byproducts and bounded parallel
jobs. No fault-enabled native module is packaged.

### R6 — Scene source/material access

Models & Points > Source access adds **Show sources**, **Hide sources**, and
**Edit material**. Existing **Select sources** selects the registered scene nodes.
Show/Hide changes node visibility in one Undo and preserves renderable flags.
Layer/group/category restrictions still apply.

Edit material opens the assigned scene material in Slate for one valid model.
It preserves material instancing, hidden state, source registration and library
files. Point/Empty/mixed/missing selections are guarded. Commands capture logical
owner/row identities and validate node identity again after editor opening.

Unmapped Standard materials key their consumed diffuse/opacity values rather than
broad shader edit notifications. A glossiness-only edit therefore reuses unchanged
appearance. Mapped, Multi/Sub and unsupported branches retain conservative
invalidation. Appearance edits do not apply pending Manual population settings.

## Evidence and limits

Owned run: `build/refinement-08683-20261022/`. Original source/status evidence and
failed attempts are preserved. Final native source is built under `scatter-final04/`;
Analyzer's clean build is `analyzer-final01/`. Per-request JSON, loaded-module
records and package manifests retain full identities.

- Clean Max 2027 SDK build: **51 native tests passed**; Analyzer core passed.
- **190 Python tests passed**, including strict result-parser negative cases.
- Generated layout/catalog checks and the isolated template byte-parity check pass.
- **41 request-bound scenarios pass on the final script/native pair**, including
  the exact Analyzer installer. The seal is
  [`delivery-seal.json`](../../../build/refinement-08683-20261022/delivery-seal.json).
- Actual Max scenarios cover dense Paths through 8,192 vertices, transformed/holed
  exports, unchanged original Paint, Undo/Redo, Analyzer channels/freshness,
  library import/selection, shared materials, appearance/density roles and saved scenes.
- The multiple-Bands regression is preserved as a failing predecessor test.
- Exact Analyzer installation tests cover wrong host, repeat, tamper, rollback
  and recovery. Its installed runtime was loaded after an owned restart.
- Scatter installer core tests cover interrupted update/recovery, content reuse,
  zero new bytes on repeat and exact embedded MZP identity. Final archive checks
  are recorded by the package seal.

The final all-page repeated-view case completed within its expanded deadline;
the longest final-artifact scenario took 50.27 seconds. This is a bounded scripted
fixture duration, not a presented-FPS measurement.

The manifest's 61 target rows include broader subcases than the initial fixtures.
Passed subsets do not close unexecuted subcases. Full physical picking/brush focus,
high DPI, sustained artist-session/resource soaks, every commit-tail/observer fault,
production renderer/Particle Flow combinations and the full missing/unsupported
shader matrix remain acceptance work. Repeated all-page view tests completed
outside their initial 120-second deadline; that late completion is preserved as
functional evidence, without a responsiveness claim. No Max 2024/2026 qualification
is established by these new tests. No overall 10/10 code-quality claim is made.

## Install and scope

Artifacts are in `dist/CyrusScatter-0.86.8.3-20261022/`:

- `CyrusScatter-0.86.8.3-Setup.exe` — Max 2027 plugin update.
- `CyrusScatter-0.86.8.3-Max2027.mzp` — matching hosted installer.
- `CyrusSurfaceAnalyzer-0.14.1-Max2027.mzp` — independently installed Analyzer.
- `SHA256SUMS.txt` — full archive/EXE hashes.

Close Max before using the Scatter EXE. For MZPs use **Scripting > Run Script**
in Max 2027, then restart. Install the Analyzer MZP as well when using Analyzer
guides. Recalculate old guides with **Analyze / Update Analyzer**, then **Update
scatter** in Manual mode. Preserve original scenes and save upgraded copies.

Plugin-only updates reuse existing content; the 0.86.7 library is unchanged.
Recipients without content need its separate ZIP. Artist profiles/sessions,
`Test Scene/`, unrelated project work and private assets were not install targets.
No Git commit/push, artist installation, website build or deployment was performed.
