# Path native API and scene state — 0.3.2 development

Implementation under validation; not a release. All numeric placement work is C++.
MAXScript reads typed native values and presents one transient Modify view.

The subsequent [path-minimum extension](PATH_MINIMUMS_0.3.2.md), frozen in
`build/native-032-path-min-host02`, passed seventeen native suites and **37 Max
path API checks**. It honors global minimums across both lanes and clears a
Quantity path into the combined surface Copies total. Spacing clear uses the
current output count. Its mounted Modify run passed **88 checks**, and matching
shelf/stair26 and geometry19 runs passed, all with normal exit and all five
identity/profile guards. The older temporary
nonzero-path restriction in the historical checkpoint below is superseded.

The next schema7/packing pair `build/native-032-packing-host02` passed seventeen
native suites, 26 path API, 83 mounted Modify and 19 geometry/fit checks, with
normal host exits and all identity/profile guards. It appends per-source minimum
policies after schema6's path footer; older input schemas3–6 remain supported.
`caGeneratePathMinimums owner values10 values19 minimumRows freshSeed` stages
minimum drafts alongside path fields. Nonzero path minimums are still being
integrated at that checkpoint and explicitly reject; they are not silently
ignored. See [the packing report](PACKING_PRIORITY_0.3.2.md). Historical schema6
evidence below retains its original scope.

## Commands

`caBindPath owner spline curveNumber` binds one independent evaluated Bezier-capable
shape and a one-based curve index in1..256. It evaluates/admit-checks the shape but
does not construct the numeric sampler or solve. It allocates both stable lane
IDs natively once, and installs the typed layout and real path reference in one
Undo transaction. `caClearPath owner` explicitly removes that binding; current
output stays visible pending a successful Generate. Protected output may reject
an incompatible mode change instead of being silently discarded.

`caPathSettings owner` is read-only. It returns undefined in surface mode, else
`#(pathNodeOrUndefined, values19, #(firstPlaced,secondPlaced))`. Missing source
references remain explicit rather than being replaced with arbitrary geometry.
`caGenerateAlongPath owner values10 values19 freshSeed` stages visible placement
and path values together with generation. The existing `caGeneratePlacement`
route also honors an already bound path using its saved path settings.

The ten main placement values retain their order: seed, amount mode, first-lane
quantity, fill value, object gap, edge margin, random scale, fit scale, minimum
scale, maximum scale. For a bound path, mode2 means Quantity and mode1 means
center spacing. Fill is not used for path calculation. Generate controls the seed
and commits accepted fields/output atomically; binding itself is an explicit
separate authored command. Failure retains previous accepted state and output.

| 19-field index | Meaning |
| --- | --- |
| 1 | One-based curve number |
| 2 | One or two lanes |
| 3 | Align upright heading to tangent |
| 4 | Source forward angle in degrees |
| 5 | Reverse first lane |
| 6 | First offset in mm, positive toward source-curve left |
| 7 | First width in mm |
| 8 | First center spacing in mm |
| 9 | Limit first lane width |
| 10 | Second quantity |
| 11 | Second offset in mm |
| 12 | Second width in mm |
| 13 | Second center spacing in mm |
| 14 | Reverse second lane |
| 15 | Limit second lane width |
| 16–17 | Native start/end insets, retained but not exposed as extra artist controls |
| 18 | Random sideways spread in mm |
| 19 | Random along-path spread in mm |

One inline Path rollout contains direction, lane and variation controls, sharing
the same native owner/serial guards as Props/Scale. Without a path it shows only
the picker. Second-lane controls appear only with Two-way enabled; center-spacing
inputs appear only in spacing mode, and width inputs only when constrained.
The rollout compacts the visible rows. Two-way constrains both widths and offers
an Opposite direction toggle. Source front uses four axis choices and preserves
a saved custom angle. Insets retain native values; ordinary end fit is calculated
automatically. Path mode uses Quantity/Center spacing in the main amount dropdown.
No extra settings popup. This compact presentation passed 78 mounted-Max checks
in `build/host-032-path-ui02`; the earlier three-section draft is superseded.

The presentation uses the documented writable rollout height, control visibility
and position properties, not dialog APIs. The rollout visibility flag itself is
documented for dialogs and is not used to hide Modify sections. Reference checked
18 October 2026: [Autodesk Max2027 rollout properties](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-DC435555-362D-4A03-BCF2-21179C5442F2.html).

## Ownership and capture

Document reference6 is the real path container; existing references0..5 retain
their meanings. Undo/reference staging, clone remapping, load admission, current
input observation and discovery now include that path. A present typed layout
requires exactly one path slot. Source deletion leaves a missing binding and a
failed Generate rather than silently reassigning a node.

Schema6 appends an optional bounded layout after schema5 quantity/scale fields.
Schemas3/4/5 retain exact prefix interpretation and receive no invented path.
Both lane IDs contribute to monotonic high-water recovery. Corrupt fields reject
before publishing decoded state/high-water. First quantity agrees with the main
quantity; combined active quantities respect output admission.

On Generate, host-thread capture copies the evaluated Bezier chain after WSM,
including absolute handles and the actual affine transform in millimetres.
Line-type segments retain linear geometry. Sampler, lane/query data and solve
use owned copied numbers. Actual path controls are recaptured and compared during
final guards before/after native publication, in addition to time/unit, owner,
state and dependency tickets. Receiver/obstacle keys are checked too.

Path calculations skip the surface sampling grid. Bound mesh receivers still
provide exact native contact/clearance/collision queries; independent obstacles
remain collision-only. Without receivers, authored path height defines the base,
with output and lane validation still mandatory. A new support flag is part of
the exact numeric geometry key; collision-only mode cannot become a fake support
surface for ordinary surface placement. No retained path cache is introduced.

Current frozen SDK/native build `build/native-032-path-host03` passed all fifteen
suites. Its owned Max API run `build/host-032-path02` passed 26 actual path checks;
the matching actual Modify run passed 78 checks, and the geometry regression run
`build/host-032-geometry05` passed 19. All hosts exited normally and passed all
five identity/profile guards. The source-map and receipt digests are recorded in
`build/path-host-032-progress01/progress.json`.

The earlier `path-host02` build and `host-032-path01` API receipts retain their own
frozen scope. The first mounted Modify extension run passed 55 checks before
failing path binding; that failure remains preserved in `build/host-032-path-ui01`.
The refresh helper's lexical ordering was fixed and the compact interface tested
on a fresh source pair. Actual UI handler checks do not qualify mouse picking,
visual quality, the full real-model/performance campaign or the final installer.
