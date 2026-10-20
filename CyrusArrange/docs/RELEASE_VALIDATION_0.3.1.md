# Cyrus Arrange 0.3.1 validation

Status: **qualified for the documented Max 2027 workflow**. All twenty functional suites, the
actual real-model producer and native viewport tests have passed on the final
pair. Saved-scene UI readback, relocated rendering and the actual immutable
installer/startup gates passed. Historical failed attempts are
retained; a fixture's successful report with a failed host exit is excluded.

## Behavior and ownership

The public native **Cyrus Arrange** modifier appears in the Modifier List.
New arrangements use a selectable, nonrenderable cyan icon with that modifier
already attached. Modify provides the furniture type, furniture binding, Props,
Amount, Spacing, Generate, Repeat seed and Advanced controls over the existing
native Document. Selecting an icon or opening its parameters performs no
geometry capture or placement solve. The native engine remains the authority
for geometry, placements, transactions, dependencies and saved state.

The modifier passes input geometry through unchanged. A temporary off-scene
scripted custom attribute hosts the MAXScript controls through the SDK's edit
methods. Each edit session binds the intended owner, context and Document GUID;
stale callbacks are rejected. See [native presentation](NATIVE_PRESENTATION.md)
for lifetime, reentrancy and the development hosting defect that was corrected.
Document/library/registry formats remain **4/2/1**. Existing native identities
are preserved; the presentation adds native modifier and icon classes.

## Frozen final build

Build: [native-arrange-031-06 receipt](../build/native-arrange-031-06/receipt.json).
All **12 native test executables** passed. The exact-input Python campaign
passed **36 tests**. Actual host: **Max 2027.1 / 29.1.0.11426**. Runtime,
fixtures, installer and tooling comprise **138 frozen inputs**.

| Module | SHA-256 |
| --- | --- |
| CyrusArrange.dlx | `62565dbbd68d0e80977206fe369b7354dc6c82ddf8503b3f95dfd57d279c97cb` |
| CyrusArrangeStorage.dlh | `a8740d003042f9f4f2ef1f5809ab704b917b37b102c441be99e2f7df84201e4c` |

The [collected functional campaign](../build/final-031-complete/receipt.json)
passed **20 suites / 3,809 assertions** against this exact full source map and
pair. Each accepted host exited normally and passed actual loaded-module,
unchanged-binary, private-INI and artist-profile gates. The Modify suite used
a normal owned GUI process with a real command panel. Development-only runs
and failed host exits are excluded. Installer/startup executed the unchanged
MZP in two private processes, including a real installed Modify page;
both gates passed as recorded below.

| Max suite | Passed |
| --- | ---: |
| Inspector | 69 |
| Native arrangement | 21 |
| Library validation | 6 |
| Cache | 685 |
| Atomic cache callbacks | 233 |
| Cache boundaries | 1,182 |
| Visual geometry and materials | 156 |
| Furniture gallery | 49 |
| Workflow | 162 |
| Lifecycle | 89 |
| Preview | 38 |
| Surface regions | 83 |
| Obstacles | 78 |
| Simple workflow | 85 |
| Composition | 52 |
| Composition lifecycle | 71 |
| Migration | 60 |
| Bulk props and reusable groups | 119 |
| Actual native Modify workflow | 139 |
| Prepared real models | 432 |

## Real prepared models

[The final physical producer](../build/host-final-031-realworld07/receipt.json)
passed **432 checks**, with normal Max and runner exits. Its saved scene contains
the prepared coffee table and side table, two book sources, the complete
three-part potted plant and the original vase set. The saved coffee arrangement
has three books, one complete plant and one vase set; the side has one vase set.
Both requested counts are fully filled. Source scale is **1**; output poses
come directly from generation, with no manual placement correction.

Scene SHA-256:
`d40af1ca5a6d682b7675f0c412092b76e0c4cf72f364dd759af892aa9c06df32`.
Physical report:
`88a4f25e345a70cba7fa7c8c77277efafd5970fe0d5e7d22ae9a6cf546250f2d`.
Full actual WORLD geometry CSV:
`937b90b69d78040c1cdc115f0e2441e84fd14d44f3a5490cce974f48fc383d96`.

The [independent double-precision verification](../build/host-final-031-realworld07/independent-real-world-30961b45d2b7.json)
uses the exported actual geometry and immutable preparation metadata without
importing the native solver or physical fixture. It checked **13 meshes,
94,207 vertices and 167,614 triangles**, complete original plant membership,
rigid source/output correspondence, full footprint support, true union-boundary
clearance, conservative furniture/prop intersections and all 131 copied maps.

| Saved scene measurement | Result |
| --- | ---: |
| Minimum support-edge distance | 14.722694 mm |
| Minimum same-table prop gap | 50.769440 mm |
| Minimum gap across the arrangements | 534.204498 mm |
| Maximum rigid source/output vertex error | 0.000194 mm (rounded up) |
| Required edge margin / prop spacing | 10 / 15 mm |
| World measurement allowance | 0.03 mm |

The verifier's **26 analytic checks** passed. An initial metadata comparison
used an inappropriate 1e-6 mm comparison between Float64 converted preparation
bounds and MAXScript Point3 readback. All eight literal bounds were proved to
equal the correctly rounded Float32 preparation components exactly. The gate
now requires that exact representation equality; geometric tolerances were
not widened. Original verifier and diagnostic evidence are preserved under
`build/real-world-031-01/`.

Actual Max checks also cover original topology, smoothing, authored mapping
arrays/faces, material roots and material IDs, seed repetition, fresh seeds,
icon movement, save/reopen and source preservation. The [physical test design](REAL_MODEL_TESTING.md)
explains unmapped plant parts, empty material slots and the Euclidean-edge
regression. Artist seeds **412031/412032** were selected through a bounded,
logged explicit search; these saved states repeat exactly. A new random seed
can produce underfill, which is reported rather than hidden by resizing props.

## Actual viewport evidence

[Final icon host](../build/icon-qa-031/host-06/receipt.json): **66 checks**, normal
GUI exit, exact final pair and all twelve host guards. The QA module invokes
the actual native Display and HitTest methods, checks positive/negative picks,
millimetre/centimetre bounds, transformed state and graphics-state restoration.
Six original viewport captures were visually inspected: selected, unselected
and transformed icons in both unit systems. The cyan diamond and C are clear
and complete. These are Top views; they do not visually prove the vertical
marker. The diagnostic module is excluded from the product installer.

## Saved real-scene Modify controls

[The additional real-scene GUI readback](../build/real-scene-modify-031-draft/host-native06-physical07-02/receipt.json)
passed **51 checks**, normal Max and runner exits, with every identity and
preservation flag true. It opens the exact final physical scene and switches
Coffee → Side → Coffee using the actual native modifiers. It verifies the
native context, saved Document GUID, actual presentation attribute, live page
HWND, enabled controls, Amount/Spacing/type and all saved settings/ordered
placement fields. Full native state, references, transforms and cache/dependency
counters remain exact throughout passive browsing and closing.

The first additional readback was rejected by its independent unit gate:
the harness omitted `useFileUnits:true` and adopted the private centimetre
context. Poses and settings were already exact. The corrected build-only
successor adopts the saved millimetre scale and retains the strict unit and
pose gates. Both attempts remain preserved; no runtime change was needed.

The root inspected both new original whole-owned-Max captures. The Coffee
image clearly shows the real scene, Cyrus Arrange stack and parameters, and
is copied byte-identically to [the Modify guide](MODIFY_PANEL.md). The Side
image shows its correct stack but blank lower parameter pixels in the
immediate window capture, so it is excluded as an illustration. Its actual
live numeric readback passed. A nonuniform scene image alone is insufficient
to establish parameter-page appearance. No pixels were edited or synthesized.

Native Manual mode marks transient dependencies pending after loading; it
retains the saved output and performs no automatic solve. The guide explains
Repeat seed + Generate for refreshing the saved composition. Both actual
root/page windows and the applicable controls were enabled in the readback.

An additional paint-probe prerequisite registered `postSystemStartup` from
the command-line script. No notification arrived within its 60-second guard;
it cleaned up and exited normally without loading the scene or touching a
Modify page. That attempt is excluded and proves no product UI defect or
startup-event ordering. A separate deferred-UI-turn probe has its own scope;
it cannot retroactively satisfy the missing startup event.

That separate finite deferred-UI-turn supplement exercised all three mounts
and recorded 14 controls, 21 declared HWNDs and 25 recursive child windows per
mount, with actual captions, ancestry and bounds. Its script passed 387 checks
and the Side page painted. **The overall run is excluded from qualification**:
the protected artist `Plugin.UserSettings.ini` hash changed during its interval.
The writer is unknown. A bounded read-only audit found no owned deferred-run
path or private Arrange path in the resulting keys; it found no exact original
copy for a value diff. No artist file was restored or overwritten. The extra
captures also contain occlusion/region limitations and are excluded from
product illustrations. These diagnostics add zero accepted functional checks.
The clean 51-check readback and Coffee illustration remain the accepted
additional scene evidence. See the [supplement review](../build/real-scene-deferred-ui-031/deferred-ui01/REVIEW.md).

## Relocation, rendering and accepted example

[The final relocated readback/render host](../build/host-final-031-readback-render08/receipt.json)
passed **23 checks**, normal Max and runner exits and all twenty identity,
preservation, geometry, material, map-resolution and image guards. It loads a
byte-identical copy of the physical producer's saved file and renders its
three saved cameras. It performs no Generate, stage reconstruction, scene
save, manual placement or map-path repair.

Both independent WORLD comparisons contain 94,207 vertices and 167,614
triangles with **maximum delta zero**. Before/after CSVs and material/map
exports are byte-identical. Twelve assigned bitmap instances, covering eleven
distinct filenames, resolve through both actual Max resolution APIs to the
relocated maps directory before and after rendering. All 131 supplied map
files remain byte-identical; extra collection maps need not be assigned to the
selected pieces. The 134 copied inputs (scene, report, CSV and maps) retain
their exact admitted SHA values and byte counts.

The three actual PNGs are **1280 × 900**, rendered with **Corona / 32 passes**.
The root inspected all three original images for complete plant parts,
original materials, apparent scale, contacts, separation and framing. All are
accepted as test-scene illustrations. Overview shows both complete tables;
detail cameras intentionally crop background furniture and the side-table
foot. Numeric geometry/collision proof remains separate from appearance.

The first render-readback harness stopped before rendering because it tried
to read the nonexistent TargetCamera `.lens` property. Its five completed
geometry/map checks and failed result remain preserved. A build-only successor
uses the documented `.fov` getter in the same before/after camera snapshot;
no native, production script, scene, material or placement was changed.

[The delivered example](../examples/real-world-0.3.1/README.md) contains
**144 files / 121,978,879 bytes**: the exact scene, 131 maps, three PNGs, artist
guide, raw geometry, physical report, independent proof and provenance. Its
manifest SHA is
`e413a7ca458632d9f63f874962eee7a489d4ad32151443e5dffb2f3505ef9414`.
Fresh staging and promotion were independently checked against every admitted
file/hash/byte count; [the audit](../build/example-031-independent-audit-01/audit.json)
passed **468 provenance/member checks**.

[Fresh original-library preservation](../build/real-world-031-01/preservation-full-20261018T113038Z.json)
passed for **742 original files**, 70 organized asset families, 127 prepared
Max variants and 489 catalog maps. The audit also rehashes the five explicit
prior-delivery/library baseline records; it does not claim every historical
archive was checked. A [separate root check](../build/final-031-complete/prior-030-archives-preserved.json)
confirms the exact previous 0.3.0 MZP and source/examples ZIP retain their
original hashes.

## Failed attempts and limits

Earlier normal-Max panel development exposed an incorrect standalone rollout
host; it was replaced by the genuine scripted-attribute edit route and the
final panel suite must verify that route. Other development-only runs are not
release evidence. An earlier scene candidate used a lamp mistaken for a plant;
it is excluded from the delivered example and image evidence.

`host-final-031-realworld06` completed 432 checks but Max returned -1 during
shutdown. The runner correctly rejected it. The unchanged, controlled
successor `realworld07` completed with exit 0. No shutdown cause is established.
The first-cohort composition/bulk processes and the first final Modify process crashed before test entry with
zero assertions. Owned dumps were preserved only after their PID/time identity
was verified. Both captured execute AV at address zero; the bulk dump's first
raw return falls in `chrome_elf`. The deeper unwind is unreliable and no cause
or component attribution has been established. These failed runs remain
excluded. Their controlled, unchanged-source successors passed normally and
are the accepted functional receipts; this does not establish a startup fix.

Qualification is limited to the tested Max 2027 workflow and prepared Corona
models. It does not promise arbitrary third-party modifier, displacement or
renderer compatibility, rigid-body stability or perfect packing. Conservative
envelopes can reject valid tight fits. These correctness runs are not controlled
performance comparisons or measurements of viewport FPS. No artist session
was commanded, installed into or restarted; owned processes independently
check preservation of the artist INI files during their own run.

## Installer and delivery

The qualified [Max 2027 installer](../dist/CyrusArrange-0.3.1/CyrusArrange-0.3.1-Max2027.mzp)
has SHA-256
`0fce2ca16fc47d026337039ee72115de9cca5943e3561e02e45226e4397077d8`.
The actual immutable archive passed **43 installer checks** and **17 automatic
installed-startup checks**, each with normal exit 0. The second process loaded
the installed native pair and six matching UI scripts through its private
startup configuration and mounted the actual native Modify presentation with
a live page HWND. These phases passed their profile, installed-payload,
loaded-path, private-INI and unchanged-archive guards. They performed no artist
installation. See the [installer receipt](../build/installer-final-031-06/receipt.json),
[qualification receipt](../dist/CyrusArrange-0.3.1/qualification-receipt.json)
and [independent archive/installed-file audit](../build/installer-independent-audit-031/REVIEW.md).
This preservation claim covers those two phases, not every auxiliary process
in the task interval; the excluded profile-failed diagnostic is described above.

The [source and examples archive](../dist/CyrusArrange-0.3.1/CyrusArrange-0.3.1-Source-and-Examples.zip)
includes the exact qualified inputs, current documentation, accepted real-model
example and selected verification evidence. Its
[source receipt](../dist/CyrusArrange-0.3.1/source-receipt.json) records every
member's hash and byte count. The MZP remains unchanged after testing: its
documentation is the pre-installer snapshot and can still describe the then
pending installer gate. The source manifest records those documentation
differences explicitly. The separate
[delivery receipt](../dist/CyrusArrange-0.3.1/delivery-receipt.json) binds the final
archives and acceptance evidence without a circular self-hash.
