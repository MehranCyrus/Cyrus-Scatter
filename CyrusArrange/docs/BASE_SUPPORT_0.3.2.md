# Automatic source base support — 0.3.2 contract

Status: implemented and verified as development progress; not a release.
The full fourteen-item goal remains active.
Baseline: `build/feedback-032-progress01/progress.json`, with all 165 source
inputs preserved beside it. Existing release archives and artist assets stay intact.

## Ownership, invalidation, work and recovery

Automatic scene-source capture will derive a conservative convex contact envelope
from referenced nondegenerate triangles within a conservative 0.5mm base band
above the mesh minimum (the inspector's existing height resolution). Triangle
edges crossing the band are included. A separate 0.002mm referenced-contact
check certifies that the complete mesh minimum actually touches geometry. The
wider envelope avoids defining a warped book's base from a microscopic low edge;
it can reject extra placements, never omit true contact. This is
geometric contact; it is not gravity, mass balance or deformable simulation.
The complete source still supplies collision geometry and packing priority.
Upper overhang may extend beyond support only when the contact envelope is fully
supported and the complete body passes collision/clearance checks.

A pure synchronous C++ helper owns only bounded numeric scratch and returns at
most 64 footprint vertices, an anchor and charged work/fallback information.
It admits the existing per-asset 250k vertex/triangle limits before loops, charges
at most 8m charged work units, and uses at most 32 support directions and bounded convex
polygon clipping. No per-triangle/mesh-sized contact buffer or retained geometry
cache is added. Exact metadata/resource sizes and observed costs require tests;
this is not a total Max RAM claim. Work/precision exhaustion falls back to the
complete rectangular envelope after a complete bounded face/contact preflight.
A work budget too small for that preflight fails admission. A mesh minimum
unsupported by referenced faces cannot silently become a floating automatic base,
including when envelope refinement exhausts its budget.

The host's existing automatic contact policy owns the new computation. Explicit
authored/imported footprints remain authoritative. `prepare_asset` keeps its
portable-library fallback; no saved schema or library-format change is needed.
New computed footprint/anchor values use existing saved fields. Capture occurs
on source registration/explicit Generate, not panel browsing or callbacks. A
failed capture/validation leaves the previous complete document/output intact.
Normal native publication/Undo/source and material preservation remain unchanged.

Support sampling will use the stored contact dimensions so narrow bases do not
disappear behind upper-body dimensions. Fill demand must continue to account for
the body envelope, rather than request excessive copies from a tiny pot base.
Large-first priority remains based on complete body bounds. Path placement and
its fit feedback must share one definition of base center, derived from the
contact envelope; complete-body lane containment remains mandatory.

The first production narrow-round-support test reproduced a search miss: direct
physical validation accepted the centered original prop, while the sampled search
did not propose its true center. After ordinary proposals fail, the native query
may suggest the nearest outer support-outline bounding-box center at that height.
This is only a proposal: sampled-region membership, complete support, edge,
collision and all normal checks still run. Preferred sizes get these proposals
before the fit pass. Each solve admits at most 64 outline scans and 256 extra
probes, at most eight regions/eight orientations per batch/pass. Scans use existing
immutable union outlines, allocate no retained state and return copied values and
charged work. A scan is soft-limited to 200k work; partial scans supply no hint.
Exhausting the solve's smaller remaining global budget throws and retains the
previous complete result, consistent with the existing atomic-budget contract.
Default custom queries supply none. Holes/concave centers may fail normally; this
does not claim an optimal packing search. Existing invalidation/Undo are unchanged.

## Required acceptance

Native cases: symmetric/asymmetric overhangs, rounded bases, bottom-band edge
crossings, disconnected feet (conservative envelope), unused lower vertices,
degenerate/tiny geometry, bounded fallback, explicit metadata preservation,
contact dimensions versus complete collision, Fill accounting, path base centers,
random/fit scale, serialization and deterministic output. Preserve old goldens
and review intended behavior changes rather than overwriting old evidence.

Owned Max2027 cases: narrow support with overhanging top, actual source contact,
body/roof/obstacle rejection, unchanged original mesh/material/UVs, saved/reopened
computed footprints, Undo, draft/UI behavior, and a prepared real plant where
available. Independent verification must inspect actual referenced mesh contact
and full body geometry, not trust native footprint metadata. Existing book,
stair, cabinet, road and compound campaigns must use the final exact pair.
No artist installation, restart or computer use.

## Edge spacing in the single Modify view

New documents start at zero edge gap, allowing the computed base to use available
support. Saved documents retain their authored margin. Optional Edge gap (mm)
joins Keep clear in the existing modifier; it edits the existing native setting,
adds no schema or independent state, and applies atomically with Generate. Opening
that section must hydrate saved values without turning default widgets into drafts.
Subsequent refreshes preserve real pending edits. Browsing performs no geometry
work or native state mutation. Failed Generate/Undo retain the established atomic
document/output behavior. No new popup or Apply action is introduced.

## Verified development evidence

Exact SDK build: `build/native-032-base-host04/receipt.json`, with both Max2027
modules and all **20 native suites** passed. It includes **1,360 base checks**,
40 feedback checks and 14,314 compound checks. The native base suite exercises
actual production search, the round-foot/large-upper-body case, a blocking roof,
holes, bounded source/contact work, unused low vertices, authored metadata,
serialization, path centers and Fill accounting. Existing goldens are unchanged.

Seven owned Max processes exited normally with all five source/module/profile
guards: Modify123, base26, fit31, geometry19, path37, shelves/stairs26 and compound17,
for **279 checks**. The new base fixture used 266-vertex complete modeled props
and the complete **40,953-vertex prepared plant**. It checked uniform fit, varying
scale, original-size support, overhead rejection, true path base centers, Undo,
save/reopen, evaluated source preservation, effective materials at every plant
face and authored UV coordinates at every mapped corner. Original Max/metadata
and maps were hashed before/after; only private copies were changed.

Three independent actual-mesh reports passed and rejected **13 bad controls**.
The new proof derives a convex low-band hull from exported referenced triangles,
proves coverage by disjoint actual receiver triangles, checks complete vertex
transforms/topology, lane bounds and body separation. It reads no native support
footprint or collision proxy. Its five controls reject lifted/outside/incorrectly
scaled geometry, a missing receiving top triangle and an unused lower vertex.
Prepared-plant coverage was 1.0 and maximum world vertex error 0.000521 mm.
The book/stair verifier now reads an explicit source pose-reference anchor;
actual contact/solid/gap evidence remains independently calculated. It passed
100 full books on four shelf levels and 48 mixed props on six stair levels.

Observed single-run Max timings (not latency/RAM guarantees): synthetic capture
reported 0 ms at the host timer's resolution and Generate 5 ms; prepared-plant
capture 10 ms and Generate 77 ms. These exclude startup, map copies and independent
or material verification. Maximum-admitted contact-heavy native geometry exercised
the 8m work fallback. Full capacity/history/artist-response measurement remains open.

The first production-search test failed until the actual support center proposal
was implemented. Failed compile and later regression attempts remain preserved.
The prior-work-minus-one budget assertion was invalid for an adaptive conservative
query: diagnostic allowance 15,538 completed safely in 14,615 units versus prior
15,539. The corrected fixture uses genuine 1,000-unit exhaustion and checks
retained protected input; all suites pass. Physical collision assertions remain.

Reviewed compound-export differences: nested/static files change only the first
arch's stable ID, because the new checked center proposal supplies that fresh
placement. Their actual source/receiver/output vertices, faces, bounds, positions,
yaws and scales are identical to the prior checkpoint. Existing protected IDs
remain preserved. The path export is byte-identical. The shelf/stair exports
intentionally change source anchor records and placement results; their complete
independent physical proof passed.

The exact **170 source inputs**, maintained documentation snapshots, receipt and
archive hashes, private scenes, failed attempts and remaining scope are recorded
in `build/base-032-progress01/progress.json`. Scene schema7 and library version2
are unchanged; the transient view is CA9. The 0.3.1 archives remain byte-identical.
No artist installation, restart or computer use occurred. Broader complex imported
receivers/cars/units/performance/lifecycle and final installer/startup acceptance
remain open. Convex near-base envelopes can conservatively reject some valid
disconnected-foot or curved-support combinations. Packing is bounded; gravity,
mass balance and deformation are outside this component.

Primary language reference used when reviewing fixture point/array syntax:
[Autodesk Point3 values](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Language-Reference/Values/Basic-Data-Values/GUID-1564BD35-50EA-4140-9150-1AECC89F713C.html)
and [Array values](https://help.autodesk.com/cloudhelp/2023/ENU/MAXScript-Help/files/MAXScript-Language-Reference/Collections/Collection-Types/GUID-A5B54C67-BFDD-45C0-9D6B-E6869817282A.html).
