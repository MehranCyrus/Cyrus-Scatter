# Compact Modify and Max path checkpoint — 18 October 2026

Verified development checkpoint; not a qualified release or completed full goal.
Max2027.1 / 29.1.0.11426 only. No computer use, artist installation, restart or
commands sent to an artist Max session. Every host ran in its own disposable
profile with the frozen native/UI pair.

## Exact evidence

The 149-file source map matches current CMake/include/src/scripts/tests/tools/
installer/third-party files. Documentation is maintained outside that source map.
The verified digest index is
`build/path-host-032-progress01/progress.json`.

| Run | Result | Receipt SHA256 |
| --- | --- | --- |
| `native-032-path-host03` | Both SDK modules; 15 native suites passed | `d0ce1624f300b2738eacbaeff08fe2e3d04dc166c59a78fd02781ed5ee8a040e` |
| `host-032-path-ui02` | Normal Max; 78 mounted Modify checks passed | `e94bc0c95c603045f7ecb0e245b3185c1b806a4240c86d3b58b2715b0462daaf` |
| `host-032-path02` | Max Batch; 26 path API checks passed | `63e3ac79ccdd3f24a45241d65bf130365dd5eb31c31c09cb13d03f580e6b2cb3` |
| `host-032-geometry05` | Max Batch; 19 geometry/fit checks passed | `c8990137b4fc8499db57a67d2a518c90111809fdafdc256072c7366a0d55dd1f` |

All host processes exited normally with code0. Each verified the loaded main
module, loaded storage module, unchanged copied binary hashes, private INI and
unchanged checked artist profile hashes. The actual reports start SUCCESS with
zero failures. The total is **123 Max checks**, in addition to the native suites.

## What the checks establish

The native icon/modifier mounts one transient presentation CA for the same C++
Document. The five sections are Cyrus Arrange, Props, Scale, Protected placements
and Path. The first two start open. Path includes lanes and variation, showing
only relevant fields and compacting rows. Real mounted controls fit the measured
command-panel width. Generate applies visible amount, scale and path drafts
atomically; there is no Apply step or settings popup. Passive mounting/section
opening does not solve.

The fixture covers bulk props, copied reusable groups, unchanged originals,
pending-draft restoration across Max's group-context closure, stale-view guards,
owner ambiguity, pinned-stack focus, native initialization and toolbar creation.
Path controls cover quantity/spacing, two-way defaults, hidden unused fields,
six actual car outputs, spread, source-forward mapping, Undo/Redo, clear-path
Undo, save/reopen and automatic spline selection through Create.

The API fixture measures actual straight-road car bounds, base-center positions,
opposite headings, support height, full lane/end bounds, materials and pair
nonoverlap after final random scale. A rotated/nonuniformly scaled Bezier uses an
independent dense world-curve length oracle for centers and headings. It also
tests fresh/repeated seeds, real path edit/deletion/Undo, clone independence,
schema6 roundtrip and explicit path-only placement height.

The geometry regression independently checks 100 actual outputs on a board,
their scale range, contact, footprint, pair nonoverlap, materials and unchanged
source. A 450mm device fails at original size beneath 280mm clearance, succeeds
with bounded uniform fit, and correctly remains unfilled when the scale floor
prevents the reduction. Failed drafts retain the prior accepted result.

## Failures retained and repaired

`native-032-path-host01` failed compiling assignment of the wrapper path result;
the bridge now extracts its ArrangementResult. Diagnostic CTest also exposed an
outdated unsupported-version value and footer offset in the codec fixture after
schema6 was introduced. The corrected tests still reject unknown schemas,
malformed data, truncation and trailing bytes.

`host-032-path-ui01` passed 55 checks before its path-binding assertion failed.
An isolated unqualified diagnostic established that native binding succeeded but
the UI called a refresh function before its lexical declaration. Moving the
binding helper after that definition fixed the fault. The successful compact
interface was rebuilt and tested from a fresh source map; failed receipts were
not edited into passes. Intermediate diagnostic profiles are not qualification.

## Limits and remaining acceptance

These tests use actual Max processes and controls, but invoke control/shared
handlers rather than a viewport mouse gesture. They do not certify visual
quality, mouse picking or mouse-create interaction. The road cars are primitives;
100 copies are on a board, not a dense real imported shelf. The broader real-model
shelf/stair/road campaign, units/performance coverage, irregular-fit refinement,
packing priorities, specific failure/highlight feedback and independent inline
override controls remain open. No 0.3.2 installer has been qualified or installed.

The [full requirement ledger](GEOMETRY_WORKFLOW_0.3.2.md) remains authoritative.
The [user workflow](GEOMETRY_USER_WORKFLOW_0.3.2.md),
[Modify implementation](UNIFIED_MODIFY_0.3.2.md) and
[path API](PATH_API_0.3.2.md) describe the current development behavior.
