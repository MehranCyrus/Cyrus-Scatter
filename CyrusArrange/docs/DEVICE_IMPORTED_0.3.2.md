# Complete device and imported receivers — 0.3.2

Status: the complete device/imported scenario now passes on the 184-input
`build/native-032-receiving-prep-host03` pair. All **21 native suites**, **39 actual
Max device checks**, six independent actual-mesh cases and seven invalid controls
pass. See [native receiving preparation](RECEIVING_PREPARATION_0.3.2.md) for the
production orientation fix, limits and exact receipts. The full fourteen-item
goal and final 0.3.2 installer qualification remain active.

The earlier 177-input `build/native-032-device-host10` pair passed twenty native
suites and 347 regressions but failed this device scenario after thirty checks.
Those failures and [receiving winding / packing evidence](RECEIVER_WINDING_0.3.2.md)
remain preserved. Subsequent quantity recovery and receiving preparation are
required for the current successful result; earlier partial tests or disposable
mesh corrections are not relabeled as complete acceptance.

## Ownership and recovery before implementation

Add a newly modeled complete coffee appliance: housing, tank, feet, tray,
controls, group head and handle. Test-only MAXScript factories author these meshes;
production capture, usable-space detection, fit, collision, priorities, state,
publication and scale calculations remain C++. No new artist control, popup,
persistent field, cache or scene/library schema is planned.

Use a modeled divided cabinet with genuinely different overhead clearances and
explicit external blockers above its caps. Prove preferred-size placement in the
tall compartment, then bounded fit in short compartments after occupying the tall
one. A forbidden minimum must leave honest unfilled copies. Also merge immutable
private copies of prepared Coffee_Table_05 and Coffee_Table_06: actual imported
glass/rim/leg geometry, including two levels in the former. Keep their source Max
and metadata hashes unchanged. These two prepared models declare no maps; do not
invent missing texture files or replace their original Corona materials.

All owned meshes stay below 20k vertices/40k triangles, all fixture nodes below
256 and the appliance below 32 indexed closed components. Export actual evaluated
source/output/receiver/obstacle meshes and native poses in world millimetres.
Independent verification derives bottom support from actual referenced triangles
and proves coverage by actual upward receiving triangles. It must tolerate
overlapping imported top triangles without double-counting their area. Verify
complete source transforms/topology, effective material IDs, smoothing and UV
corners. Check actual component envelopes against receiving/obstacle triangles,
literal cabinet interiors, final-scale output separation and support height.
Bound per-output proof work at 2m operations and remaining uncovered polygons at
2,048; admission failure must report failure, not silently pass a partial proof.

Actual Modify commands own source/receiver/obstacle binding and Generate drafts.
Check repeat/fresh seeds, the accepted shrink range, unchanged source/receivers,
invalid-draft retention, Undo/Redo and saved/reopened states. A source signature
must include authored appearance and geometry. Temporary Mesh/Bitmap values
are test-local and closed. Use only owned normal/Batch Max2027 private profiles,
the exact frozen source/native pair and fresh receipts; at most two owned hosts.
Do not install/restart an artist profile, touch their scenes or use computer use.

An optional actual Corona preview may use existing installed Corona renderer
and original material roots; bound its passes and disable VFB. It complements
the geometry proof and does not qualify render quality or other renderers.

If a scenario exposes a production defect, first record the actual witness and
its ownership/invalidation/peak/Undo/failure implications. Every failed successor
must retain the preceding complete result and saved seed. Preserve failed tests.
No release or full-goal completion claim follows from this scenario alone.

## First host evidence

`build/native-032-device-host01` built both modules and passed native20. Its
177-input pair loaded correctly in `build/host-032-device-imported01`, passed
four setup assertions, then failed the original-size cabinet expectation. Max
exited normally and all five identity/profile guards passed. The first test did
not preserve the actual result/status needed to distinguish a placement failure
from a scale or draft problem; no production diagnosis is claimed from that
assertion. The successor logs accepted settings, actual poses, visible status and
cache metrics for every Generate and saves the original-size failure scene and
actual meshes before stopping if that expectation fails again.

## Reproduced preferred-size search defect and native change contract

The second host (`build/host-032-device-imported02`) again exited normally with
all guards passed. It published one complete device at scale 0.631204, position
[-1812.2,53.2125,80], rather than original size. Its retained mesh/scene witness
and logged native settings show this is a missed preferred-size search, not an
invalid draft or failed transaction. An independently constructed original-size
pose [-1670,0,80], yaw0, passes the actual exported floor/roof/wall/blocker geometry:
complete component envelopes, 100% actual support and literal free-room bounds.
This diagnostic is a constructed candidate, not a native publication claim.

The current random preferred pass admits 64 probes per small demand across all
regions. Its optional support-outline center ignores overhead distribution; the
single floor continues under several cubbies. It therefore misses the tall
space and enters fit search. Add a bounded deterministic preferred-size supplement
before the fit pass: inspect existing immutable usable cells with enough sampled
headroom, propose their bounding center and then nearby actual cell centers.
Every proposed pose must pass the unchanged full physical validator; headroom is
only a proposal filter. This adds no semantic furniture rule.

Ownership/invalidation/peak: per-solve counters and one temporary vector of at most
8,192 existing Cell pointers (64KiB on x64), plus bounded sort stack; no geometry
copy, cache, host access, persistent field or new UI. Scan at most 8,192 cells and
try at most 1,024 new poses per solve, charging scans, sorting, probes and physical
queries to the existing work/candidate limits. Large cell arrays are sampled at
a deterministic stride when the remaining scan admission is smaller. Allocation,
global work or candidate failure follows the existing atomic transaction; prior
complete placements/settings/seed remain. Reaching the local proposal cap does
not certify absence of space. The new order is deterministic and part of the
existing one-step Generate Undo. Ordinary successful random proposals are kept.

The 8,192/1,024 local admissions apply to each Arrange invocation. Regional Fill
delegation runs single-region child invocations and charges their complete work
and candidate totals to the existing outer limits; the local cap must not be
reported as a new whole-command total. Its temporary pointer vector still does
not coexist with another such vector at the parent level.

Add a native physical counterexample with the same literal cabinet and a device
body/feet envelope. Prove a full-size pose is physically valid, demonstrate the
old search failing that preference, then require preferred-size success across
multiple seeds, repeatability and unchanged source metadata. Re-run native/Max
acceptance from a fresh exact pair after implementing the supplement.

The native counterexample in `build/native-032-device-repro01` confirmed this
before the production edit: a manually probed original-size pose passed the
native physical query, then the old Arrange search failed its preferred-size
assertion after 5,277 space-workflow checks. Nineteen other native suites passed;
the failed twenty-suite receipt is preserved. Exact 177-input failed-host sources
are reconstructed and hash-checked in `build/device-original-032-failed02/source_inputs`.
`build/host-032-device-imported02/independent-original-size-witness.json` binds the
constructed-pose geometry proof to its original failed Max export/receipt hashes.

The first corrected SDK build (`build/native-032-device-host03`) passed the
expanded **5,331-check** space workflow, including sixteen cabinet seeds and
exact repeats, plus eighteen other suites. Only the exact golden comparison
failed. Review of its full six-scenario dump found all placements, targets and
warnings byte-identical; only the always-reject scenario's probe/rejection and
charged work counts increased from the additional bounded search. The golden
update changes just those two reviewed counter lines. Its failed receipt and
actual dump remain preserved; a fresh complete build is required.

`build/native-032-device-host04` stopped at its first compilation with C1085,
no space left on F:. This is an infrastructure failure, not a test pass.
An audited cleanup removed 1,990 reproducible `.obj` files only from verified
owned `build/native-032-*/CMakeFiles/` paths, after confirming no Arrange compiler
was active. It reclaimed 2,543,544,226 bytes. Source snapshots, native binaries,
PDBs, executables, scenes, archives and receipts were retained. Exact file paths,
sizes and result are in `build/device-object-cleanup01{,-result}.json`. Earlier
build directories now need recompilation if reused; use fresh directories for
subsequent qualification.

The successor `build/native-032-device-host05` passed native20. Its exact Max
run passed 27 assertions, including the actual full-size appliance at
[-1667.5,0,80], scale1, successful short-compartment fit, forbidden minimum,
Undo/Redo and imported upper support. The constrained lower-table case then hit
the existing polygon work limit and retained the prior complete result/settings.
The failed receipt and all guards are preserved. Additional preferred probes
must not consume the work needed for the fit phase: stop starting new such probes
after 1m charged proposal/query units (or one eighth of the configured solve limit,
whichever is lower). A last in-flight query still uses the existing global limit;
this is a soft supplementary allowance, not a smaller physical-query contract.
Keep all global limits and complete validation unchanged. The lower-table failure
now also exports its exact meshes/settings and saves its scene before stopping.

Actual imported-mesh measurements then found a fixture mistake in that failed
lower-space attempt: its upper blocker began 40mm below the model's maximum,
intruding into the lower shelf. The actual lower support is z74.822021mm and the
upper glass underside is about z368.1916mm; a 280mm-tall 50% appliance can fit.
The blocker began at z341.230713mm, making that same minimum impossible. Correct
the blocker to begin at the actual tabletop maximum z381.230713mm, and retain
the 50% minimum. The proof must use actual obstacle bounds and triangle clearance,
not an invented 40mm cutoff. An independent constructed four-device witness
against the actual imported mesh and corrected blocker passes full support,
component-envelope clearance/closed-solid containment and 110mm output separation
within 803,418 proof units per output. It is a capacity diagnostic, not a native
publication: `build/host-032-device-imported05/independent-lower-capacity-witness.json`.

`build/native-032-device-host06` passed native20 with the supplementary work guard.
It was not launched in Max because the measured fixture correction needs a new
exact-source pair. Both the genuine original-size search defect and the later
incorrect test blocker remain distinguished in this record.

The corrected `build/native-032-device-host07` pair passed native20. Its actual
host passed 30 assertions, including four devices on the imported lower level
(observed 334ms), then rejected the second imported table during query construction
with `Degenerate furniture triangle; clean geometry before arrangement.` Its
immutable private input Max and exact 177 source inputs are preserved in
`build/device-degenerate-032-failed07/source_inputs`.

## Mixed degenerate receiving faces: contract before the edit

Align query construction with inspection: omit receiving/obstacle faces whose
3D squared cross-product area is below the existing 1e-18 threshold. They contribute
no support/collision surface. Preserve all captured/scene geometry, material IDs
and maps. Invalid indices/non-finite vertices, collapsed nonzero edges and bodies
with no usable triangles still reject. Valid faces must retain closed occupancy.

Temporarily reuse TriangleData.component for its original input face index during
construction, then remap valid triangles to components. No extra per-face vector,
cache, persisted field, UI or retained buffer is introduced. Existing aggregate
input/DSU/edge-map bounds remain; charge each skipped-face decision. Publish only
a completely built immutable query. Failure, Undo and invalidation behavior stay
unchanged. Inspection already counts degenerate faces. Add native mixed-face,
occupancy, real-obstacle, all-degenerate and invalid-data regressions before the
production edit. The independent verifier must derive/record degenerate receiving
faces itself and omit them only as zero-area geometry; full source/output topology
and appearance still include every authored face. Export imported input before
Generate and save later failure scenes.

The focused portable regression linked against the preserved pre-filter native07
core reproduced exactly the mixed-zero-area constructor failure; all eighteen
other named query tests passed. Its source/library/producer hashes and compiler
command are preserved under `build/degenerate-native-repro01`. This is a focused
old-core reproduction, not a full SDK qualification. The implementation now
skips zero-area derived triangles and remaps only surviving face keys without a
new per-face buffer. The independent missing-support control removes just the
floor's upward triangles, retaining its sides/bottom, so it tests support coverage
rather than malformed-body admission.

## Sub-micron real edges: contract before the edit

The native08 pair passed all twenty suites. Its Max run passed thirty checks,
then Table06 failed with `Furniture contains sub-micron collapsed edges.`
The preserved actual input has 84 zero-area faces and twelve nonzero faces
whose endpoints merge on the query's 0.001mm topology grid. One measured edge
is 0.000244140625mm long; its triangle has nonzero doubled area 0.011447mm².
These are real collision surfaces, not zero-area faces. Preserve every such
triangle, support contribution and authored face. Exact failed08 sources are
under `build/device-tiny-edge-032-failed08/source_inputs`.

Keep normal topology welding for unaffected bodies. If it collapses an edge of
a nonzero face, rebuild only that body's topology with exact finite coordinates.
Reuse the existing vertex-ID vector, disjoint-set storage and cleared edge/weld
maps. A tuple of three doubles replaces the same-size three-int64 topology key;
normal keys remain integer-valued quantized coordinates. Clear maps before
rebuilding so no second full topology map exists at peak. Charge reset, vertex
and triangle processing to the existing build budget. No retained storage,
cache key, persistent field, schema or UI changes. Actual triangle coordinates
and support clipping precision do not change. Exact seams remain connected;
genuinely distinct endpoints remain distinct in the affected body. Open or
nonmanifold components stay open and do not gain closed-solid containment.

Add a closed, full-size cuboid with an extra sub-micron perimeter segment to
prove support, complete-face retention and closed occupancy, including hard
edge duplicates and translated/negative coordinates. Test the same geometry as
an external obstacle, bounded construction failure, and unchanged input. First
link that regression against the preserved native08 core to record the original
failure. Failed query construction publishes nothing; the existing accepted
arrangement, Undo and dependency semantics remain unchanged.

The focused new query regression against preserved native08 reproduced the
collapsed-edge rejection; the nineteen other named query tests passed. The
corrected full native09 SDK build passes all twenty suites, including the
closed tiny-edge regression at three coordinate origins. Its only new compiler
warning was the explicit integer-valued grid-key conversion to double; make
that bounded conversion explicit before the next frozen pair. Coordinates are
already limited to ±10km, so the quantized integers are exactly representable.

A diagnostic independent proof on five outputs from the failed08 host found
a separate verifier assumption: cabinet-fit housing extended 4.210419mm past
the open front y=-300 while all actual feet remained supported. That is valid
under automatic base support; there is no front wall. Require literal side/back
walls and roof, all base points inside the support front, full actual support
coverage and complete receiving-triangle/closed-solid clearance. Report housing
overhang explicitly. Add a coherent 150mm forward displacement as an invalid
unsupported-foot control. This corrects the test's imaginary front wall rather
than changing the solver or weakening real collision validation. Preserve the
failed partial diagnostic and distinguish it from successful-host qualification.

A focused constructor diagnostic links the unchanged native09 geometry library
to the actual failed08 Table06 export. It retains all 1,520 nonzero faces out of
1,604 (84 zero-area faces), classifies one closed and one open component, and
charges 112,255 build units. Observed constructor time was 1,936µs in this single
portable diagnostic; it excludes capture/inspection/placement/Max and is not a
performance guarantee. Exact input, producer/library and diagnostic-source hashes
are in `build/tiny-edge-actual-table-probe01/receipt.json`. This confirms the
captured constructor trigger is handled; actual Max generation is still required.

The warning-free native10 pair passes all twenty suites. Nine fresh Max hosts
pass Modify123, status31, base26, fit31, geometry19, path37, shelves26, compound17
and road37: **347 checks**. Four independent full-mesh verifiers pass all seventeen
cases and reject eighteen invalid controls; the separate road lane-domain audit
also passes. Source/receiver geometry in the compared exports remains unchanged.
Some accepted output layouts differ, so byte identity with the older pair is
not claimed: the new bounded preferred-size probes change fit search, and later
road cases deliberately inherit a fresh seed. Same-seed repetition is tested
within each exact pair. Current source/document snapshots and receipts will be
recorded in `build/device-query-032-progress01/progress.json`.

The exact full device Max10 run again passes thirty checks, including original
cabinet preference, short-compartment/random fits, invalid drafts, Undo/Redo,
actual imported upper support and four fitted appliances on the imported lower
level (observed 380ms). Table06 no longer throws either geometry-construction
error. It accepts generation with zero of two copies and honest unfilled status.
This is still a failed requested-capacity case, with scene and complete exports
preserved. No Corona overview or three-owner reopen checks were reached.

Independent geometry finds the supplied closed glass shell is inward-facing
(signed volume -17,762,900.138873mm³). A diagnostic copy with only its twelve glass
faces reversed admits two constructed full-size appliance poses with complete
foot support, 40mm output separation and complete envelope/triangle clearance.
This witness changes no scene or source asset and is not a native publication.
An additional isolated Max capture/diagnostic confirms object transform determinant
+1, native authored support at z241.672mm with 19.231mm overhead, and the copied
glass support at z260.904mm with open overhead after reversing those twelve faces.
Native generation on that disposable copy produces one full-size appliance near
the table center, blocking room for the second. Its diagnostic therefore also
fails the two-copy expectation. Winding alone is insufficient; packing recovery
also needs a reproduced correction. Both failures remain open and explicit.

After the frozen checkpoint, the complete captured source/receiver portable
diagnostic confirms both literal corrected-glass poses pass precise native
validation (including 15mm separation), while seven of sixteen solver seeds
underfill. Its exact source/input/library hashes and old results are preserved
in `build/receiver-winding-packing-repro10/receipt.json`. This strengthens the
next packing regression; it does not alter the frozen 347-check campaign or
claim either outstanding production fix.
