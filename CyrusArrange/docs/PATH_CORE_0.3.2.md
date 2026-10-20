# Native path implementation decisions — 0.3.2 development

The full goal remains active. The previous goal turn was progress: the exact
142-file source map passed thirteen native suites, 52 actual Modify checks and
19 actual geometry checks. This document defines the next path component before
implementation; a design is not acceptance evidence.

C++ owns a copied world-millimetre cubic Bezier chain, bounded adaptive
subdivision, arc-length inversion, seeded offsets, orientations, scale, lane
containment and placement validation. Host-thread capture will use the evaluated
Max ShapeObject Bezier representation and transform all four control points to
the arrangement frame before measuring. Line segments must honor Max's line type.
No host pointers enter numeric snapshots; no passive UI action captures a path.

The sampler must handle nonuniform speed even on a perfectly straight cubic.
Chord length alone plus linear parameter interpolation is insufficient. Each
accepted interval must have a monotone projection onto its chord; inversion uses
bounded bisection of the original cubic. Control-polygon/chord length bounds
track aggregate arc-length uncertainty. Sampling also bounds geometric deviation.
Source curves, sources and materials remain unchanged.

Frames keep objects upright: XY heading follows the source curve tangent, and
the horizontal left vector is perpendicular to it. Curve Z defines the base
height. Reverse changes travel/heading while preserving the authored source-side
meaning of lateral offsets. Native full-bounds base center is on the chosen
path/offset, including sources with an authored off-center contact anchor.
Vertical or degenerate XY directions must fail explicitly rather than inventing
a heading. Closed curves wrap jitter and must not duplicate their seam placement.

A bounded sampled ribbon defines an enabled lane's permitted XY area. It has
flat open caps and continuous joins; closed lanes preserve their inner hole.
It is a numerical approximation of an analytic offset curve and must be
documented as such, with its path tolerance. Containment uses the complete
transformed bounds rectangle and a conservative quantization guard, including
edges/interior; checking only the anchor or corners is insufficient at concave
bends. Clipper input/output/work limits apply before expensive operations.
Sharp reversals that cannot form an admitted ribbon fail explicitly.

One or two lanes have stable IDs, independent requested totals or spacing,
source-relative offsets, widths and opposite directions. Seeded lateral and
longitudinal variations precede validation. Output collision/spacing and any
supplied physical support/obstacle query see the final pose and scale. Preferred
sizes are tried first; optional bounded uniform fit is a fallback. Locked output
is validated and retained; unlocked output may be regenerated. Failures do not
publish partial state.

The pure component owns vectors/polygons under explicit segment/sample/output/
work limits and is synchronous, immutable after construction. Publication, native
references, dirty scheduling, Undo, clone, scene codec and the inline Path rollout
require subsequent host integration and current Max2027 evidence. A native-only
pass will not complete items 10–12. The final scene schema must persist typed
path settings plus a real path reference and include that reference in current
input observation. Failed staging retains previous settings, seed and output.

Primary references checked again on 18 October 2026:
[Autodesk ShapeObject](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_shape_object.html),
[SideFX Resample](https://www.sidefx.com/docs/houdini/nodes/sop/resample.html),
[SideFX Copy to Curves](https://www.sidefx.com/docs/houdini/nodes/sop/copytocurves.html).

## First implementation and diagnostic evidence

The native component now owns copied cubic chains and immutable sampled ribbons.
Default geometric deviation is at most 0.1mm, with a 1mm total arc-length bound;
stricter length bounds are supported and tested independently. A 1mm bound over
a road-scale curve avoids needlessly multiplying ribbon vertices. Straight
nonuniform-speed cubics invert by projection bisection, not linear parameters.

Lane construction canonicalizes bounded quantized polygons with Clipper. Queries
then run in linear time in the canonical ribbon vertices: corners and center
must be permitted, and no canonical boundary may enter the open full-bounds
rectangle. This catches enclosed holes and off-center concave gaps, not just
corner overhang. A 0.002mm conservative guard covers 0.001mm quantization. Folded
lane offsets/widths are rejected explicitly. The ribbon is still a sampled
approximation of analytic offsets, and object bounds remain conservative.

`build/native-032-path01` compiled production sources but failed compiling the
new test fixture's nested aggregate initialization. That receipt remains pending/
failed at build, not accepted. The corrected fixture and subsequent changes were
examined with explicitly unqualified targeted diagnostics in
`build/path-diagnostic01`. Each run retains source/library hashes and separate
compile/link/run logs. A malformed historical eligibility mask in the first
fixture was corrected to a valid Kitchen-only tag; valid tags never restrict
path placement. The curved two-lane case then exposed a real stable-ID defect:
XOR-combining independent lane/slot hashes was commutative. Ordered hash chaining
now distinguishes those roles and preserves independent seeded variations.

The final targeted diagnostic passed 7,615 checks. These include an independent
Simpson arc-length oracle under nonuniform world scaling, full rectangle holes
and concave notches, six cars with opposite headings, an off-center source anchor,
local jitter/random scale/repeatability, preferred-size slots before fit,
real native road/roof physical queries, scale floors, output collision/gap,
closed seams, protected output and bounded errors. The 100-car closed two-lane
case checks all 4,950 ID pairs and independent same-lane distances while keeping
the fixed 50M work limit. These are native numerical checks, not actual Max path
capture/publication/UI acceptance.

The fresh full SDK/native campaign is `build/native-032-path02`. The source now
differs from the previously Max-tested 142-file UI baseline. Previous 52/19 host
receipts remain evidence only for their frozen pair. Path settings/reference
persistence, host capture/publication, inline controls and actual Max road scenes
remain mandatory next work; the full goal is active.

The first frozen SDK campaign, `build/native-032-path02`, compiled both Max2027
modules and passed all fourteen native executables, including 7,615 path checks.
A subsequent memory-admission review found that limiting Clipper's output only
after union could still allocate too many crossing/intersection nodes. The
successor preflights all nonadjacent edge bounding-box overlaps, conservatively
reserving four possible output vertices per overlap before calling Clipper.
The existing quadratic build-work admission bounds this preflight; canonical
lane queries remain linear. A crossing-ribbon regression with a deliberately
small output bound proves the rejection occurs at preflight, not after union.
The focused successor passed 7,616 checks; `build/native-032-path03` is its new
frozen full SDK/native campaign. The path02 receipt remains unchanged.

`build/native-032-path03` passed the full Max2027 SDK build and all fourteen
native test executables, including **7,616 path checks**. No compiler warnings
were reported for this campaign. The verified 145-file source map and receipt
hash are in `build/path-032-progress01/progress.json`. No actual Max path capture,
publication or UI acceptance is claimed: those changes are next under
[the host integration contract](PATH_HOST_INTEGRATION_0.3.2.md). The full goal is
active, and no artist installation or qualified 0.3.2 package was produced.

The subsequent [Max path/Modify checkpoint](MAX_PATH_MODIFY_VALIDATION_0.3.2.md)
now records schema6, real spline references/capture/publication, the compact
Path rollout and 123 matching actual Max checks. The numerical-only receipt above
retains its historical scope; use the newer checkpoint for current host evidence.

The later [shared minimum-copy extension](PATH_MINIMUMS_0.3.2.md) supersedes that
checkpoint for current source: seventeen native suites, including 8,199 path
checks, and 170 actual Max checks on the identical frozen 154-file map. It adds
required/large-first demand, bounded optional fallback, schema7 policies and
safe mode switching in the same five Modify sections. Earlier pure-numeric and
host receipts remain historical; full release acceptance is still open.
