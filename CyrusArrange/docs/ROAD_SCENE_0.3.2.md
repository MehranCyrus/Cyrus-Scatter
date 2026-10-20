# Complete car / curved road acceptance — 0.3.2

Status: verified development checkpoint, not a release. The original fourteen-item
goal remains active. Previous exact source/receipts:
`build/status-032-progress01/progress.json` (171 inputs, 20 native suites, 310 Max checks).

## Ownership and scope before implementation

Add an owned Max2027 scenario with a newly modeled complete 4.52 x 1.9 x 1.5 m
sedan, shaped body/cabin, four tyres/rims, lights, explicit materials and UVs.
The asymmetric axle placement separates its wheel-contact center from its whole
body center. No downloaded/proprietary car or semantic category solver is used.
Test factories are MAXScript; all production sampling, scaling, lanes, support,
collision, state and publication remain the existing C++ implementation.

Use one curved Bezier centerline and five closed receiving road bands. Source
and receivers are newly owned scene geometry, bounded below 20k vertices/40k
triangles per fixture mesh. Geometry exports admit at most 256 nodes and existing
250k-per-mesh limits. Car copies use native placements and original source data.
No new production UI, cache, persistent field or library/scene schema is planned.
If a scenario reveals a defect, record its actual witness and ownership/Undo/
resource implications before changing production code.

The first exact-pair host, `build/host-032-road-scene01`, loaded both modules,
exited normally and passed all five identity/profile guards, but the test stopped
after its first assertion: the three factory functions loaded later by `fileIn`
were implicitly local in the compiled caller. Explicit global declarations fix
the test-only scope. This failed receipt is preserved and proves no placements.

The second host, `build/host-032-road-scene02`, passed 22 assertions, including
six full cars, appearance, variation, Undo/Redo, two actual renders and reopen,
then stopped on a protection expectation. Source inspection confirms Protect
selected deliberately captures the scene node's float transform; comparing its
yaw/scale bit-for-bit with the preceding double solver values was incorrect.
The successor checks capture precision against that preceding pose, then exact
preservation of the captured protected pose across a genuinely fresh seed.
Its model roof also removes the coplanar overlap visible in the first renders.
Partial failed-run geometry diagnostics passed for the original/variation exports
but do not qualify the current full fixture or supersede its failed receipt.
The settings parser now accepts MAXScript's `d` exponent spelling for doubles.

## Required evidence

- Actual Modify: three cars each way; align/reverse; repeated seed; local sideways
  and along-path spread; 80–110% scale; bounded narrow-lane fit; honest unfilled
  count at a disallowed minimum; quantity and spacing; protected placement;
  same native arrangement, no popup or separate Apply.
- Export actual complete source/output/receiver triangles and final poses in world
  millimetres. Check topology, per-face effective material, smoothing and authored
  UVs against the source. Source mesh, transform and material stay unchanged.
- An independent Python proof must derive support from actual referenced bottom
  triangles, prove coverage by disjoint actual road top triangles, and prove the
  entire body envelope stays inside the permitted curved lane. It must independently
  evaluate the authored Bezier, arc length, travel direction and offset. Do not
  validate using native fit flags, contact footprints or proxy geometry.
- Validate final scale and complete body separation; reject deliberately lifted,
  wrong-side, wrong-scale and overlapping controls. Include warm repeat, passive
  panel/selection behavior, Undo/Redo, save/reopen and conversion from the owned
  millimetre scene into centimetre/inch system units. Preserve failed receipts.
- Save an inspectable matching-development scene plus actual Scanline overview
  and detail PNGs. Inspect rendered files without computer use. Render pixels
  complement the independent geometry proof; they do not replace it.

All SDK/Max work uses fresh private profiles and the exact current source/native
pair, at most two owned hosts at once. Following the preceding startup fault,
start this first new host alone and retain startup diagnostics on failure. No
artist installation, restart or attached-scene editing.

## Resource and recovery boundaries

Factories/exports/proofs own only test-local arrays/files. Keep Bezier reference
sampling and polygon proof work bounded (at most 4096 stations/2m proof operations
per output by explicit admission). Close temporary Mesh/Bitmap values and use
`vfb:false`. Save only under the owned run directory. The native transaction and
Undo contract remain authoritative: failed successors retain accepted settings,
seed and complete output; no partial scene publication is acceptable. Native cache
metrics and host timings distinguish capture/solve from startup/render/proof cost.

Primary references: Autodesk [renderer control](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Interacting-with-the-3ds-Max/Render-Scene-Dialog/GUID-9175301C-13E6-488B-ABA6-D27CD804B205.html),
[Scanline renderer](https://help.autodesk.com/cloudhelp/2021/ENU/3DSMax-MAXScript/files/GUID-D4C5C5DF-7447-485F-9802-2E5328037EBE.htm)
and [scene unit handling](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/3ds-Max-Objects-and-Interfaces/Interfaces/Core-Interfaces/Core-Interfaces-Documentation/M/GUID-48C5E2F2-DE34-4EA3-A84C-4DBD463DBF90.html).

## Complete road scenario acceptance

`build/native-032-road-host03` built both modules and passed all **20 native
suites**. Its 174 frozen inputs differ from the preserved 171-input status
checkpoint only in the runner's normal-host allowlist and three new test/proof
files. No production C++, UI, saved schema or library field changed here.
`build/host-032-road-scene03` passed **37 actual normal-Max2027 checks**, exited
normally and passed all five loaded-module, binary, private-INI and artist-profile
guards. The full regression campaign also passed against this same pair.

The modeled sedan has **1,138 vertices / 2,216 triangles**, 15 individually closed
parts, six materials and explicit UVs. Its literal size is 4,520 x 1,900 x 1,500mm.
Its wheel-contact center is 100mm ahead of its complete body center; the test
therefore distinguishes base-centered placement from whole-body centering.
The receiving road is five closed bands along one 37,511.597mm Bezier curve.

The independent verifier reads actual exported source/output/receiver triangles,
not native footprints, success flags or collision proxies. It proves complete
source-box containment inside separately evaluated curved lanes and tyre-base
area coverage by the actual disjoint road triangles. It also checks every actual
transformed vertex, topology, material ID, smoothing, per-lane quantity, arc slot,
offset, direction, final scale and complete-box separation. The Max fixture checks
every UV corner and material root directly. This is conservative geometric support
and collision evidence, not gravity, vehicle dynamics or center-of-mass stability.

| Case | Actual cars | Independent result |
| --- | --- | --- |
| Original size | 3 + 3 | Complete bodies inside 3,200mm lanes; wheel bases centered on offsets |
| Random variation | 3 + 3 | 80–110% scale; 300mm sideways / 2,000mm along spread; physical checks after variation |
| Fit | 3 + 3 | Uniform sizes inside 1,600mm lanes, within the permitted 60% minimum |
| Center spacing | 6 + 5 | Separate 6,000 / 6,500mm spacing and opposite travel directions |
| Centimetre system units | 3 + 3 | Same physical settings, full geometry and source preservation |
| Inch system units | 3 + 3 | Same physical settings, full geometry and source preservation |

All six actual-base coverage ratios are 1 within floating arithmetic. Maximum
source-to-output vertex error is **0.0112mm** across these cases, including unit
conversion. The smallest independently proved complete-box separation is
267.579mm, above the authored 100mm gap. Five deliberately lifted, wrong-lane,
wrong-scale, wrong-heading and overlapping controls were correctly rejected.
Receipt: `build/host-032-road-scene03/independent-road-scene.json`.

Actual Modify handlers also verify fresh/repeated seeds, one-step Undo/Redo,
save/reopen, protection of a captured real car while the other cars vary, and
six honestly unfilled copies when 1,200mm lanes cannot admit the allowed minimum.
Fit feedback identifies the lane limitation. Passive Modify refresh performs no
generation. There is no extra Apply button or settings popup.

Observed host timers were 298ms source binding/capture, 64ms first Generate and
80ms repeat Generate. Geometry reuse was disabled in this fixture, so the repeat
is **not a cache-hit speedup**. Reported native accounted peak was 3,809,816 bytes;
that is not total Max/process RAM. Startup, mesh-export verification and rendering
are excluded from those generation timers. These are single-run observations,
not throughput or latency guarantees.

The owned saved scene is
`build/host-032-road-scene03/CyrusArrange-TwoWay-Cars-032.max`. It requires this
matching development pair; do not open it with installed 0.3.1 modules. The
Scanline overview (1600x1100) and detail (1400x1000) PNGs in the same directory
were actually rendered and visually inspected from disk. Both show opposed cars
following the road; the roof overlap from the earlier failed fixture is gone.
These newly modeled functional fixtures do not qualify photoreal asset quality,
other renderers, sloped/banked roads, rigid-body animation or mouse-pick gestures.
The earlier unidentified startup crash and full installer gates remain open.

## Complete matched-pair regression and remaining work

Nine successful owned hosts passed **347 Max checks**: Modify123, status31,
base26, fit31, geometry19, path37, shelves26, compound17 and complete road37.
All nine exited normally and passed exact loaded-pair/private-profile guards.
The refreshed base, shelf/stair and compound proofs also passed; their eleven
exports remain byte-identical to the previous checkpoint. Together with the road
proof, eighteen deliberately invalid controls were rejected.

`independent-lane-domains.json` additionally proves that the independent lane
area sum cannot double-count overlapping triangles. A bounds sweep checks every
candidate pair in each 1,024-triangle reference lane domain, within the unchanged
2m work admission. Maximum intersection area is numerical noise below 1e-8mm2.
An earlier all-pairs version exceeded its declared work admission; its failed
console receipt is retained. This audit is separate from the frozen production
source/test pair and its exact script is preserved with the checkpoint.

The exact 174 source inputs, documentation snapshots, private scene/render hashes,
native and nine host receipts, four independent proofs and supplemental lane audit
are recorded in `build/road-032-progress01/progress.json`. The original 0.3.1
archives remain byte-identical. No artist installation/restart or computer use
occurred. Scene schema7, asset library2 and transient Modify CA9 are unchanged.

The fourteen-item audit still requires expanded imported receiving geometry and a
complete oversized device, legacy book-row/minimum interaction, and final exact
installer/owned automatic-startup qualification. Nine new successful starts do
not identify or fix the earlier null-address worker-thread startup crash; keep
that diagnostic investigation open. Do not mark the overall goal complete from
this scenario or its single-run performance observations.
