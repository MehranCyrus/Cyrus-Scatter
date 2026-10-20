# Native receiving preparation — implementation contract

Status: implemented and qualified for the documented current-pair scenarios. The complete
fourteen-item goal remains active. [The actual Table06 failure](RECEIVER_WINDING_0.3.2.md)
and [qualified quantity recovery](PACKING_RECOVERY_0.3.2.md) remain preserved.

## Ownership and atomicity before implementation

Prepare copied receiving geometry at capture, before both inspection and precise
query construction. Do not alter scene nodes, source assets, materials, UVs,
captured coordinates, face identities or saved schemas. Only swap the winding of
eligible faces in private native receiving copies. Source/obstacle capture keeps
its existing semantics. Mirror parity compensation remains part of host capture.

Extract existing topology welding, exact-coordinate fallback, DSU and oriented
edge counting into one native owner used by preparation and query construction.
Each body remains a separate topological scope; ambiguity checks span all selected
receiving bodies. Shared edges cannot merge independently selected scene nodes.
The inspector and precise query consume the same prepared assembly.

Use centered compensated signed-volume sums only for consistently closed edge
components. Reverse a robustly negative component only when it has no potentially
nested/intersecting closed receiving component. Bounds are a conservative ambiguity
screen, not proof of actual intersection. Open/nonmanifold, zero-volume and
ambiguous components retain authored winding; this does not repair arbitrary
self-intersections, cavities or inconsistent face orientations. Emit contextual
inspection warnings for actual reversed or ambiguous closed components. No new
artist option or popup is introduced.

All analysis, allocations and work admission finish before any winding swap.
Precharge the entire final face pass so an error cannot leave even private inputs
half-prepared. Reject null/duplicate mesh ownership, invalid indices/nonfinite
vertices and aggregate input/work overflow before mutation. No broad exception
swallowing. Failed capture leaves the existing host arrangement untouched; native
preparation itself also leaves its supplied copies unchanged on failure.

## Storage, budgets and invalidation

Admit at most 4,096 bodies, 3m vertices and 1m faces across the selected scope.
The shared topology owner reuses its DSU vector as final face-to-component labels;
zero-area faces have a sentinel. Temporary maps clear before exact-weld fallback.
Query retained component/triangle layout and native accounting remain unchanged.

Preparation temporarily owns at most one size_t label per face, one existing
component record per valid face, 32 bytes of compensated-volume state per
component, bounded orientation flags/order indices and body descriptors. Per-body
weld/edge scratch is released between bodies, not retained in a cache. No second
complete topology map is kept concurrently. Positive-only assemblies skip the
ambiguity search. A few negative components use a bounded direct screen; larger
sets use an X sweep, with all comparisons/active scans charged to the allowance.
No unbounded pair list is allocated.

Normal arrangement capture already owns bodies and combined inspection soup.
Standalone Inspect additionally stages per-node copied meshes; for one node move
that mesh directly into the combined owner. For multiple nodes, bound this extra
staging by the same admitted geometry (at most an additional 84MB raw vertices/
indices at ceiling, excluding vector capacity/allocator overhead). Release staged
meshes after combination. Never duplicate host/render geometry or textures.

Preparation shares the existing inspection work limit; pass only the remainder
to sampling and report their combined work. For paths share the query-build
allowance instead. Timings include actual preparation. Geometry dependency keys
are unchanged because preparation depends only on the captured receiving mesh;
the prepared bodies live in the existing immutable geometry bundle. No new
persisted field or cache. Generate remains one transaction and Undo/reopen retain
the normal complete saved state.

## Acceptance

Add maintained tests for outward/inward closed boards, mixed polarity, hard-edge
duplicates, zero-area faces, real sub-micron edges, concave closed geometry,
open/inconsistent/nonmanifold input, flat closed shells, nested/intersecting/
touching bodies, translated/mirrored geometry, multi-body ambiguity, both ambiguity
search paths, limits and atomic failure. Prove raw inspection/query agree after
preparation. Retain the original complete captured-mesh failure and require the
unmodified actual Table06 scene to generate both devices in Max.

Independent support verification must infer physical facing from actual closed
geometry itself; do not read native prepared faces/proxies as proof. Continue
checking unchanged original receiver/source topology, material roots and UVs,
complete actual output transforms, supported feet, clearance and separation.
Finish the original six-case device campaign, real material preview, repeat,
Undo/reopen and fresh broad regressions before release claims. Ambiguous geometry
behavior and the earlier startup failure remain explicit, separate limitations.

## Native implementation and exact inputs

`build/native-032-receiving-prep-host03/receipt.json` records the warning-free
Max2027 SDK pair and all **21 passing native suites**. The new receiving suite
contains **31 checks** covering the acceptance cases above. Its 184 source inputs
are independently hash-verified in `build/receiving-prep-host03-source/source_inputs`.
The public preparation API is `include/cyrus_arrange/receiving_mesh.h`; shared
topology lives in `src/receiver_topology.h` and `src/receiving_mesh.cpp`.

Both arrangement receiver capture and standalone Inspect stage and prepare private
meshes. Path support capture uses the same preparation before query construction.
Aggregate capture limits are enforced before appending each receiving body, rather
than after retaining all bodies. Standalone Inspect moves a single staged mesh
directly; multiple meshes retain the bounded staging described above.

The immutable query-behavior fixture remains byte-identical. Explicitly charged
shared topology passes change its two-triangle constructor work from 55 to 82;
the maintained test checks that new exact value. Every geometry header field and
all twelve per-probe result/work rows remain identical. Review evidence is
`build/receiving-topology-work01/receipt.json`. The initial core-only run that
failed the old 55-work assertion remains preserved, not relabeled as passing.

`build/receiver-native-preparation01/receipt.json` uses the complete original
captured Table06 and device. Native preparation identifies one closed inward
glass shell (twelve faces), retains the open frame, and reports zero ambiguous
components. Preparation uses 49,070 work units. Original coordinates and the
other 1,592 faces remain unchanged; only the private twelve face windings reverse.
Both independently supplied original-size poses validate, and all sixteen seeded
native arrangements place both devices. This focused receipt links native01's
math library; it is not a substitute for native03 host qualification.

## Preserved qualification attempts

Native01 passed all 21 suites but was not launched in Max: source review added
early aggregate receiving-capture admission before native02. Native02 also passed
all 21 suites. Its full device host placed every case, including both original-size
devices on unmodified Table06, and passed source/material/UV/file preservation.
It then failed after 33 checks when the preview helper assigned an unsupported
Corona property. That failed host and its diagnostic six-case geometry proof are
preserved in `build/host-032-receiving-device02`; they are not full acceptance.
Native03 removes that unsupported helper assignment. A supported pass limit alone
bounds the preview; production geometry code is unchanged from native02.

The simultaneous native02 packing host failed during Max startup, before any
fixture entry or loaded-identity evidence. Its owned PID-verified dump and receipt
remain in `build/host-032-receiving-packing02`. No scene tests ran there. Offline
stack investigation is separate from placement qualification; paced subsequent
starts are not claimed as a startup fix. No artist profiles or sessions have been
changed to recover this attempt.
The [offline startup audit](STARTUP_FAULT_0.3.2.md) reconstructs the same
Corona/CEF worker chain in both preserved startup dumps; cause remains unresolved.

## Complete current-pair Max acceptance

`build/host-032-receiving-device03` passes **39 checks** and exits normally.
`build/host-032-receiving-packing03` passes **64 checks** and exits normally.
Both load the exact native03 main/storage pair, preserve its binary hashes, use
their own INIs and preserve the recorded artist-profile hashes. No artist scene,
installation, restart or computer use is involved.

The complete device scene exercises actual inline Modify handlers, native draft
publication, preferred size, fit and random size, impossible minimums, failed-draft
retention, Undo/Redo, original source/receiver appearance, save/reopen and repeated
Generate on all three restored arrangements. Its independent verifier derives
physical facing from the original exported closed triangles, not native prepared
faces or cached proxies.

| Actual case | Complete devices | Result |
| --- | ---: | --- |
| Tall cabinet, preferred original size | 1 | Original size before shrinking |
| Short cabinet compartments, tall compartment occupied | 2 | Bounded uniform fit |
| Cabinet with random size and fit | 2 | Final scale and complete geometry validated |
| Supplied two-level table, original size | 1 | Actual upper support |
| Same table, upper space occupied | 4 | Fitted devices on actual lower shelf |
| Supplied Table06 with original inward glass | 2 | Both original size, physical top support |

`independent-device-imported.json` passes all six cases and rejects seven controls,
including missing glass and the authored underside as false support. Every
actual base has complete proved support; maximum vertex error is below 0.000599mm.
`independent-packing-recovery.json` passes five more cases and rejects five controls;
its maximum vertex error is below 0.000631mm. The obstacle case remains explicitly
2 requested / 1 placed / 1 unfilled. The fixture's old scope message about an open
reversed-glass case predates this separate complete-device acceptance.

Observed fixture Generate times were 207/223/406/898/223ms for the original cabinet,
fitted cabinet, original two-level table, lower shelf and original Table06 cases.
These wall times include UI orchestration and host checks; they are observations
from this owned fixture, not general performance guarantees. Sixteen packing seed
pairs plus scripted topology/material/UV checks took 4,903ms.

The actual original-material Corona overview rendered at 1600×1000 with eight
passes in 67,540ms and was inspected from disk. Its right table is partly cropped,
so it is a supplementary visual preview, not a complete framing or render-quality
acceptance image. Full exported geometry is independently checked for both devices.
The scene is `build/host-032-receiving-device03/CyrusArrange-Device-Imported-032.max`;
it requires the matching development pair, not the historical installed 0.3.1 pair.

## Broad current-pair checkpoint

The same native03 pair now passes Modify123, status31, base26, fit31, geometry19,
path37, shelves26, compound17 and road37: **347 broader checks**. Together with
device39 and packing64 this is **450 qualified Max checks** across eleven owned
hosts. All qualified receipts have both exact loaded-module paths, unchanged
binary hashes, private INIs, unchanged recorded artist-profile hashes and normal
exit. This is current 184-input evidence; earlier 177/180-input campaigns retain
their original identities.

Six independent actual-mesh proofs cover **28 cases** and reject **30 invalid
controls**. A supplemental road audit proves the independently generated lane
triangle domains do not overlap and double-count area. All compared original
receiver/source geometry remains identical to the earlier 177-input campaign.
Base/shelf/stair/compound exports remain byte-identical. Original/variation road
exports also match; later unit cases inherit a deliberately fresh seed and differ
in six output poses, which pass current-pair repetition and physical checks.
Both new road PNGs were inspected from disk.

The first road03 run completed all 37 script checks but failed its artist-profile
guard. Its `Plugin.UserSettings.ini` hash changed; `3dsMax.ini` stayed identical.
The writer is unknown. The failed receipt, unchanged result and hash audit remain
preserved; no profile was restored or artist process controlled. A fresh road04
run passes all 37 checks and every guard. Only road04 counts in the qualified
450 total. Original campaign03 remains explicitly failed rather than rewritten.
See `build/receiving-road-profile-guard03-audit.json`.

`build/receiving-preparation-032-progress01/progress.json` seals the 184 source
inputs, documentation, exact receipts, original model/archive identities, scenes,
render hashes, independent proofs, comparison audit and preserved failed attempts.
The complete fourteen-item goal remains active. Remaining release work includes
[legacy row/minimum behavior](LEGACY_ROW_MINIMUMS_0.3.2.md), current workflow
performance/lifecycle evidence and exact package/private install/autostart. The
old cache benchmark explicitly pins 0.3.1 and is not current performance proof.
No 0.3.2 installer has been delivered.
