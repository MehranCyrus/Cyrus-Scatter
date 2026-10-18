# Native foundation execution — 0.86.0 target

## Final scoped delivery — 18 October 2026

The current [delivery report](DELIVERY_0860.md) supersedes prototype status below.
Candidate 11 is frozen in `build/native-fields-0860-20261018-01/{native-11,fault-11}`.
Both 44-suite native builds, 168 Python checks and generated checks pass. The
final Max matrix and one-hour soak (3602.9 seconds / 60 complete cycles) passed. Verified MZP/EXE
installers are in `dist/CyrusScatter-0.86.0-20261018/`; no artist installation occurred.

The native-only controller covers generation, mesh/UV masks, Paint, boundary and
Analyzer fields, transforms, Relax, Edit, radius/acceptance/cleanup, preview,
PFlow groups and 500-row Bake. Changed-block authored Edit history preserves
Undo. Native admission replaces Count-scaled MAXScript workspace reservation.

Mixed cycles exposed structural Edit-key reuse (candidate 08), preset epoch/frame
restoration (09), and abandoned-created-owner cache retention (10). Candidate 11
adds layer/area copies and all imports to the existing discarded-creation cleanup.
A four-cycle script-only private iteration kept the same retained bytes at equal
history states. The exact final pair subsequently passed the full sustained regression.
Failed runs remain frozen; no prior receipt is relabeled as final acceptance.

## Historical implementation checkpoints

Everything below describes its own earlier pair and date. Statements such as
“default-off”, “not a delivery” or “pending” are historical checkpoint status.

17 October 2026. Internal implementation progress under the [active goal](../improvement-program/OBJECTIVE.md).

**Not a 0.86.0 delivery or complete N01–N09 acceptance.** Existing pipeline and

product metadata remain 0.85.4/schema 58 while storage is qualified separately.

### Edit ownership implementation in progress — 18 October 2026

N07 now separates authored row blocks (128 rows), compact selection bit blocks,

immutable input bindings and published visibility IDs. Generated candidate keys

are numeric; only authored copies retain allocated text. Rows preserve the old

append order and dormant identities, so an identity row is intentionally retained

for each encountered original. Removing that order table is not assumed safe.

Native input pins an immutable placement View instead of duplicating matrices.

Calculation rollback and history copy small layer maps plus shared references;

mutations detach only the table and changed blocks. Save/Load keeps chunk 0x7301

and the same field order; generated keys are expanded only at persistence and

explicit readback boundaries.

The Edit allocator ledger counts unique requested blocks, tables, map nodes,

buckets and authored string buffers. Native placement storage remains in its

separate ledger. The first Restore Size attribution counted all reachable shared data and was

rejected by Max at 200k: every created restore was destroyed at Accept, so Undo

did not change output. That failed receipt is preserved. The successor separates

authored history from derived input/publication and attributes changed blocks

relative to the paired state, with checked INT_MAX saturation. One host hold

retains one authored snapshot until EndHold. This policy is under qualification;

its attributed history bytes must not be added to the unique allocator ledger. The first native-04 compile found C++20's removed shared_ptr::unique;

the host-thread-only detach check now uses use_count()!=1. No successful receipt

was overwritten. Old Edit plane/mountain scenes and exact ordered fingerprints

were frozen in native-03 host ...controller-20261018-07 for cross-build tests.

All N07 history, allocation and host tests remain pending until recorded below.

Native-02 optional controller parity passed plane and mountain for grids,

Clusters, Bands, Paint/fades/holes, radius rings/overlays and initial/final Relax.

Paint Live Undo/Redo and 65-second passive-idle witnesses passed on both. Actual

Analyzer 0.14 was used for Areas, falloff, assignment/facing and fixed anchors,

pending/current rejection and save/reopen. Analyzer requires a planar analysis

input: mountain tests use a separate planar guide, not unsupported curvature

analysis of the mountain. Native-03 actual PFlow matched every particle matrix

and scale against the comparison route, and 1001-node paged Bake matched source,

material and matrix with Undo/Redo and empty Bake on both terrains. Render/preview

flags are controller-owned and rebound to leaves after history; the test checks

that ownership. Production renders, IR/cancel and failure injection remain open.

## Preserved baseline

### Resumed completion work — 18 October 2026

The user requests completion and Max 2027 qualification of 0.86.0, with installers

but no artist installation. The next preparation changes share the existing

boundary evaluator between the comparison and native adapters, avoiding full

`Instance` input/output scratch for native falloff. Paint uses a narrow POD

filtered-successor builder owned by AminScatter: Brush may append an ordered

subset and transformed matrices, while identities, anchors and source/receiver

correspondence come from the retained immutable input. No STL ownership crosses

DLLs. A failed builder is discarded; authored Paint and published output remain

unchanged. Builders and leases release on all failure paths. Density randomness,

union tie-breaking, precision boundaries and filter order remain unchanged.

Acceptance requires complete ordered parity for boundary/Area falloff and Paint,

including overlapping Areas, holes, scales, multiple receivers, invalid inputs,

same-frame edits, actual controller history and lifecycle release. Native output

must have zero population-sized script materializations. These are planned

checks, not yet passing evidence; remaining N06–N09 gates are unchanged.

The first `native-fields-0860-20261018-01/native-01` pair passed all 43 native

suites and `run_fields.py` in owned Max 2027 host `...controller-20261018-05`.

Plane/mountain raw parity passed at 5k/50k/200k, including multiple receivers,

Paint holes/union/curves, UTF-16 seed identity, boundary/Area fading and rejection.

Covered native adapters created no script populations; their last views released

all tracked placement storage. That host was guarded-closed. These are direct

adapter witnesses, not controller/Undo/render acceptance of later edits.

N06 implementation choice: source groups pin immutable selected native views.

PFlow's Script Operator reads one detached Matrix3 per particle and keeps no

population-sized script matrix array. The small renderer owner list pins the

corresponding root publications until the existing bridge clear/rebuild lifecycle.

Bake reads detached pages of at most 500 rows in its existing authored operation;

its real scene nodes and their host Undo are unavoidable, separate costs. Verify

actual PFlow evaluation, source frames, failure/clear/reopen, page detachment,

Bake Undo and partial-creation cleanup before removing the internal output guard.

The [reviewed 0.85.4 implementation](BASELINE_0854_20261017.md) is committed and

pushed as `7379ea3`, with the remote ref verified. Original source/package

receipts and installer bytes remain unchanged. Unrelated Physics Lab, artist

scenes, presentation/landscape, website and licensing work are excluded.

## N01 measurements

[Machine-readable baseline and raw-receipt hashes](N01_BASELINE.json) record ten

warm repetitions per Count/terrain, a separate warm-up, outside-window complete

ordered eight-field SHA-256 fingerprints, history depth, script heap and sampled

process private commit. Both fixtures are reproducible owned `.max` scenes: a

triangulated 100 m plane and analytic mountain, each with a pyramid source and

Point Cloud preview using one source point per plant and the existing 20k cap.

| Count | Plane median Update | Mountain median Update |

| --- | ---: | ---: |

| 5k | 120.07 ms | 119.77 ms |

| 50k | 346.25 ms | 344.46 ms |

| 90k | 536.74 ms | 537.67 ms |

| 200k | 1,462.51 ms | 1,486.30 ms |

All ten repetitions retained the same complete ordered fingerprint at each

Count within each fixture. 120 seconds idle had no solve, receiver, preparation

or upload increments. Existing unrelated Undo remained available during Count

changes. These are scripted Manual Update timings, not physical input latency,

full Mesh drawing or production renderer qualification.

The explicit observer deduplicates actual `Value*` identities across supplied

root/receiver/Paint/prepared arrays. At 200k it observed 400,000 distinct row

arrays, matrices and anchor values, 200,001 strings, 124,981,496 bytes of known

SDK object payload and 44,800,168 bytes of array pointer capacity. This is

**reachable payload**, including interned values potentially shared outside the

supplied roots. It is not exclusive plugin ownership, allocator/GC overhead,

string capacity, process private commit or VRAM. Schedule/radius capacities

were separately 1.6 MB each. Observer traversal took about 686 ms in that

snapshot and stays outside timing windows; no hot callback invokes it.

Remaining N01 work: per-stage/materialization/scratch counts, complete old/new

peak coexistence, history pin attribution, ordinary versus Edit/preset history

cost, and actual hold/Size probes before N07. The current consumer inventory is

in [SOURCE_MAP.md](SOURCE_MAP.md). This initial baseline supports the isolated

N02 storage prototype; it does not close N01 or authorize skipping its remaining

measurements before integrated acceptance.

## N02 storage decisions and current implementation

- `placement_store.h/.cpp` defines a measured **96-byte** Float32 record with

  source, face, explicit receiver slot, numeric identity, Band owner, barycentric

  anchor and flags. It preserves full nonnegative signed-64-bit IDs; generated

  candidates allocate no identity strings. Authored ASCII keys preserve the

  existing 256-byte procedural boundary and exact text, including noncanonical

  candidate-like strings. Raw/edited stage identity representations remain distinct.

  Lossless storage does not establish acceptance validity: N04 must still apply

  the existing candidate-schedule checks, including rejection of malformed or

  missing `c:` identities even when the row is protected.

- A consumed builder exposes no mutable alias into its frozen storage. Shared

  views pin one immutable base. Selection order is explicit and flattened;

  compaction remaps only internal authored-key slots. Empty selection drops the

  rejected base. Native source-use summaries avoid script population scans.

- Owner/generation/view tokens reject mismatched readback; pages cap at 500 and

  return detached records. This session data is never serialized. Real controller

  owner retirement and public publication-token routing remain integration work.

- Narrow hooks on placement-owned standard-vector allocations count actual

  requested capacity, allocation/reallocation overlap and last-owner release.

  They do not replace the heap. Counters exclude shared-pointer control blocks,

  allocator headers and the construction-only interning map/string scratch;

  these exclusions must be reconciled in N01/N08 peak accounting.

- `placement_value.cpp` supplies the GC-traced immutable value. Explicit script

  capture/selection is capped at 500; it is a small authored/inspection boundary,

  **not** a full-population compatibility fallback. No production generator is

  switched by these primitives yet.

- `placement_api.h/.cpp` establishes versioned POD read leases owned/freed by

  AminScatter.dlx. Brush checks API size/version/record stride before acquisition.

  Acquisition requires the actual Max main thread. Retained numeric reads and

  release do not call Max. Consumers cannot exchange STL/shared-pointer ownership

  or link another store. Writable Paint-stage adaptation remains N03 work.

Two focused native suites pass: layout/rounding, identity, views, overflow and

malformed fields, source summaries, bounded pages and release; and allocation

failure at 8/4/11 construction/selection/successor boundaries with retry and no

predecessor mutation or tracked leak. A 200k record vector occupies exactly

19,200,000 requested bytes **for one vector**, not the complete pipeline.

The Max 2027 SDK build and all 42 native suites pass. Real Max tests verify

complete raw/edited row round trips, 64-bit keys, stale/wrong-kind rejection,

detached pages, immutable copy/GC retention, same-module Brush lease reads and

last-owner release. After unrelated wrappers collected, only the compact two-row

192-byte generation remained; releasing its last wrapper returned tracked live

bytes, allocations, stores and selections to baseline.

The focused core-only build initially exposed an existing declared-language

mismatch: recipe long-path code needs C++20 while the library advertised C++17.

The library now declares C++20, matching the existing Max 2027 SDK builds. Both

focused store suites pass without a command-line language override; their first

failed configuration and successful successor logs are preserved.

Current frozen build: `build/native-foundation-0860-20261017-01/store-native-03/`.

Current successful owned host: `build/mcp-qualification/foundation-memory0854-nativestore-20261017-04/`.

All 168 recorded source inputs match; [component qualification](N02_QUALIFICATION.json)

records native/module hashes and exact test receipts. The final two safety

changes translate observer allocation exceptions to Max errors and explicitly

check Brush's ABI version. Four concurrent numeric readers also retain one

generation after producer release and free it at last-reader release in CTest.

The earlier prototypes `store-native-01/02` and successful hosts `...20261017-02/03`

remain preserved with their own source/native identities. The last build also

declares the already-required C++20 library minimum correctly.

The first startup attempt exited before the test script; its dump and parser

summary are preserved. A null-IP background-thread dump has stack pointers in

Chrome/Corona components, not a proven causal unwind. The same frozen pair

subsequently started and passed the tests. Preserve this failed attempt; broader

startup/third-party compatibility remains an N09 qualification concern.

No performance improvement is claimed for the active pipeline yet. N02 still

needs integrated owner retirement, full native semantic fingerprinting,

multithreaded lease/lifetime qualification and complete byte attribution.

The prototype pair also passed the existing private Max core sequence and all

eight ready preset Load/Undo/Redo/save/reopen regressions. See the exact build

and host receipts rather than inferring acceptance from the source version label.

Those broad regressions ran against `store-native-01`; the final pair repeats

the N02 host boundary/GC tests and all 42 native suites. All owned successful

hosts were closed through their guarded command; the artist host was preserved.

At the earlier N02 checkpoint, knowledge status after activating this goal was:

the selected 36-parent generation

is compatible, with 34 current parents; the reviewed edits to `AGENTS.md` and

root `README.md` make those two enrolled parents stale. Native execution plans

and new sources are read directly. Do not present the old index as fully fresh;

publish a reviewed successor at the delivery knowledge checkpoint.

## Native producer and ownership qualification

Producer/ownership work is now implemented in an internal pair. The native

canonical producer and orientation preserve the existing Float32 boundaries;

no-modifier Edit normalization shares the same immutable base with a distinct

view token. Twenty-six plane/mountain cases compare full ordered fields and

the v2 rows/radii/binding/statistics fingerprint. Producer-only warm timing is

recorded in [N03_PRODUCER_BENCHMARK.json](N03_PRODUCER_BENCHMARK.json); this is

not full Update, preview, input latency or FPS acceptance.

An explicitly nonshipping SDK probe tests ordinary, repeated Restore(false),

cancel, super holds and abandoned Redo in Max 2027. The 5k/50k/90k native

vectors total 13,920,000 unique requested bytes. Conservative per-record pin

attribution reaches 19,680,000 bytes because multiple records share storage;

it must not be reported as unique physical memory. Abandoning Redo destroys all

five restore records. Removing the remaining script/current pins releases all

tracked vectors. Ordinary production Count history is still the existing

parameter refresh path; this standalone probe does not replace or qualify it.

Implementation decision (F02/F03/F05/F07): extend the existing radius

and acceptance bridges to immutable native input/output, preserving the same

pure solver and Float32 radius boundary. Generated schedules and sample

identities use numeric keys; authored keys remain exact text. Receiver/owner,

edited stage, root work bounds, radius lengths and candidate membership are

validated before publication. Accepted selections preserve order and immutable

predecessors; an empty selection releases its base. Measure selection retention

before choosing a compaction policy. No main controller route is switched until

native preview and ordinary Undo are integrated; optional features and all

downstream consumers must follow. Slope/altitude formulas and controls stay fixed.

Test acceptance: full ordered rows, frozen radii and all statistics/rounds equal

the legacy bridge on plane/mountain, multiple receivers, grids, three collision

scopes, protected zero-quota edits, radius overrides, cleanup/refill and failure

retention. Instrument script materializations and native lifetime separately.

This is implementation progress under the full active goal, not a reduced

delivery scope or authorization to omit later native/roadmap requirements.

## Native acceptance adapter qualification

Implementation checkpoint **`9945c82`** is pushed to `codex/workflow-0.75`,

with the remote ref verified. It includes the internal adapters, private probe,

tests and stage evidence. The companion evidence update records the final Python

rerun; native/script bytes remain unchanged. Unrelated work remains excluded.

The current internal `acceptance-native-01` pair implements native receiver

offset/join, source scale/offset/filtering, the existing post-Edit surface

eligibility filter, effective radii/overrides and procedural acceptance. The

same numerical solver still determines order, collision scopes, refill, cleanup

and statistics. Generated schedules and sample identities use numeric keys;

generated samples allocate no decimal identity strings. Native results retain

ordered immutable selections and native radii. All-kept results reuse the input;

empty selections drop their rejected base.

Plane and mountain comparisons include 5k/50k/200k candidates, two receiver

slots (including 128), projected grids, source filtering, enabled surface

filters, radius overrides, target/refill, cleanup, three collision scopes and

protected zero-quota copies. Full ordered row/radius/statistics fingerprints

match the old bridge. Rejections preserve the earlier complete value. The

retained controller route also passes actual Count/Manual/Live, failure recovery,

65-second idle, 60k/90k copy history, active Edit/radius save/reopen and all eight

ready presets' Load/Undo/Redo/save/reopen regressions. See the exact source,

binary, fixture and log witnesses in [the stage receipt](N03_N04_QUALIFICATION.json).

Materialization observation now distinguishes population arrays from individual

rows, matrices and strings. It is opt-in and batches atomic updates at function

exit. Only listed adapters are covered; Paint is explicitly uninstrumented.

Native storage counters cover requested placement-vector capacity, not all

solver/source/geometry/allocator memory. Sample scratch still contains copied

positions/radii and an empty string object for numeric candidates. Reducing that

scratch and choosing view/compaction retention remain measured N04/N08 work.

Bare native joins validate session owner, stage and source **count**; they do

not contain an actual frozen asset correspondence table. N05 must bind and

validate source identities and input/publication epochs before the controller

uses this route. The v2 diagnostic hashes the metadata supplied by its caller;

it does not itself establish that the metadata belongs to the published epoch.

The current knowledge generation verifies 33/36 enrolled parents; AGENTS,

README and the modified Edit bridge are stale. New sources/plans are inspected

directly. Publish a reviewed successor at the delivery knowledge checkpoint.

## Native preview input adapters

The internal `preview-native-01` pair now feeds native placements directly into

the existing Point/Mesh/proxy snapshots. `PreviewRows` reads immutable records

on the host thread and creates only stack SDK matrices for displayed data.

All inputs, including unshown source indices and Band ownership, are validated.

The existing retained draw publisher and snapshot ownership stay in place.

`cyrusPreviewContentEqual` compares complete native draw content and bounds

without exporting population arrays; allocation/GPU identity and field diagnostic

metadata are deliberately separate from that semantic comparison.

[Exact N05 preview evidence](N05_PREVIEW_QUALIFICATION.json) records 18 point

cases and 78 geometry cases across plane/mountain and 5k/50k/200k placements,

full/one/limited subsets, all proxy modes, Mesh and placeholders. Band/color

and source validation, rejected-successor retention, changed equal-count data,

source edits and copied-geometry lifetimes pass. Actual Nitrous publication

reuses unchanged uploads. After input placement release, drawing remains valid;

last-cache/scene departure releases tracked Point/Mesh reservations. The matching

pair passes 42 native suites, 168 Python tests, generated checks, the existing

controller/65-second idle/copy/Edit/radius tests and all eight preset round trips.

The successful owned host is guarded-closed; artist and unrelated hosts remain

preserved.

`cyrusPlacementSourceUsage` returns at most 1,024 counts but scans native input.

Compute/cache this summary during preparation/publication; do not introduce a

population scan on passive panel refresh. The main controller still uses its

existing production route. Bound native root publication, ordinary Count on the

native route, radius-ring preparation, active Edit and downstream consumers

remain open. These tests do not establish full Update speedup, presented FPS,

physical input latency or production-renderer acceptance.

## N05 source/receiver correspondence and first controller route (internal)

The current unshipped implementation adds immutable source cohorts (ordered role

IDs, actual scene handles and output flags), evaluated receiver provenance,

preparation receipts and native publication ownership. It shares placement/radius

buffers and derives source-use counts at freeze. Detached manifest/statistics

readback is bounded; a publication page remains limited to 500 rows. These are

numeric/metadata owners, not standalone Max reference targets or renderer pins.

Receiver provenance is stamped from the **same copied mesh actually consumed by

generation**, using the existing surface-key hash implementation. It distinguishes

persistent receiver IDs from random variation domains. Offset/join operations

preserve face ranges and reject conflicting revisions. Selection, compaction and

empty views retain provenance. Publication rejects a changed geometry signature,

scene binding, source order or preparation receipt instead of relabeling old data.

Protected authored copies retain the previously declared detached-provenance

exception; active Edit migration is still pending.

Local frozen builds and raw evidence are under

`build/native-binding-0860-20261017-04/`. The source/data-container tests have passed

on actual Max 2027 plane/mountain scenes through 200k candidates, including

same-frame equal-topology terrain edits, receiver joins, failed successors and

last-pin release. Shared radius ownership also passed the existing controller,

Count history, 65-second idle, copy, Edit, save/reopen and eight ready-preset

regressions on the recorded earlier pair. These scopes are separate: those

legacy-controller regressions do **not** qualify the new controller route.

An internal, default-off controller migration switch now connects Surface random

to native buffers, acceptance, retained preview, data publication and bounded

inspection. Its explicit validation rejects not-yet-integrated optional/render

routes; it does not silently drop them. The unchanged default route preserves

their existing behavior while migration continues. The internal switch is not a

new artist feature or a second long-term shipping engine.

The frozen `binding-native-07` pair passes actual Max 2027 controller checks on

both terrains: 5k/50k/200k and zero Count, ordinary Count Undo/Redo, Manual/Live,

post-preparation failure retention/recovery, retained Point/proxy/Mesh switching,

same-cardinality source replacement, passive panels, independent copied owners,

deletion Undo/Redo, save/reopen, 65 seconds idle and final store/radius release.

This is scoped acceptance of the internal first route, not full N05/N09 product

acceptance. The existing default engine/core regression and all eight ready

preset Load/Undo/Redo/save/reopen cases pass on the same pair. The

[machine-readable receipt](N05_PUBLICATION_QUALIFICATION.json) records all 180

frozen input hashes, actual loaded native-module paths/hashes, 43 native suites,

168 Python tests, generated checks, raw evidence hashes, individual benchmark

samples, corrected iterations and remaining acceptance. The owned host is

guarded-closed; no artist installation occurred.

Initial actual-host attempts caught an unqualified forward `layerID` reference,

Max's `IntegerPtr` node-handle type and retained buffers in a deleted copied

controller after scene reset. The helper now uses `this.layerID`; the manifest

reader accepts the SDK's integer-number types while rejecting fractional values.

Numeric `(AnimHandle, native owner)` retirement tickets resolve surviving old

scripted owners before full scene transitions, including deleted copies. Tickets

do not pin those owners or buffers, and deletion Undo keeps its complete Manual

result. Mismatched/reused owner tickets are ignored.

The new controller performs light collection only before a relevant native

calculation so unreachable opaque wrappers can release external allocations;

it does not collect from passive UI or clear Undo. A premature Count-handler

assertion also exposed legitimate deferred release-timer work: the driver now

observes completion within a bounded interval instead of forcing Update.

Five matched warm CPU Update samples per route/count/terrain (warm-up excluded)

show a useful large-count improvement and a small-count regression:

| Terrain / Count | Existing route median | Native route median |

| --- | ---: | ---: |

| Plane / 5k | 152.19 ms | 207.08 ms |

| Plane / 50k | 407.82 ms | 272.89 ms |

| Plane / 200k | 2,542.78 ms | 554.53 ms |

| Mountain / 5k | 139.13 ms | 205.68 ms |

| Mountain / 50k | 387.86 ms | 281.80 ms |

| Mountain / 200k | 2,458.45 ms | 547.33 ms |

Complete ordered field/radius/statistic fingerprints match between routes for

every sample. Timing excludes hashing/file I/O and does not measure presented

FPS, physical input latency, cold native-only script heap or all peak ownership.

Source review removed unnecessary integer counting from the existing route;

the final comparison preserves its original BitArray source-presence loops.

**N08 must profile and reduce the observed 5k overhead** before delivery;

unconditional light collection is a candidate to measure, not a proven cause.

No normal-profile installation, version bump or 0.86.0 package has occurred.

## Optional preparation checkpoint — 18 October 2026

Whole Scale, mesh-channel density and Analyzer Area now accept immutable native

candidate buffers. Whole Scale builds a private successor with the existing SDK

Float32 multiplication. Removal-only mask/Area operations retain ordered native

selections. Source correspondence and evaluated-receiver provenance survive all

three stages; their input generations remain immutable. The legacy adapters

retain their numerical expressions, with opt-in materialization counters added.

Whole Scale and mesh density are enabled in the internal, default-off controller

route. Native raw/prepared keys now include a bounded `ReceiverFields` signature

from the numeric channel snapshot already captured during receiver planning.

Passive key reads do not evaluate a mesh. Relevant mapping notifications and

explicit Update still control when planning occurs; a geometry-only signature

does not establish channel freshness.

The [optional-preparation receipt](N03_OPTIONAL_PREPARATION_QUALIFICATION.json)

records the frozen `native-02` pair under

`build/native-preparation-0860-20261018-01/` and the owned final host

`foundation-memory0854-nativeaccept-controller-20261018-04`. Scope:

- Plane/mountain complete ordered field parity at 5k/50k/200k for all three

  adapters, including multiple scale ranges, two mesh channels, all components,

  inversion/remapping/curves, Area caps/widths and combined stages.

- Zero/full/out-of-range and missing/disabled fields, same-frame numeric changes

  with unchanged geometry, failure preservation and final storage release.

- Controller rows/radii/statistics parity through 200k and zero Count; scaled

  collision radii retain the existing spacing result and winner order.

- Actual mesh mapping and Data Channel Curvature/Vertex Output Live callbacks;

  Manual pending edits, ordinary Count Undo/Redo, missing-input retention and

  recovery, authored scene save/reopen and 65 seconds idle on both terrains.

- No placement-sized MAXScript values in covered native calls, and no extra

  channel reads, preparation, solve, preview builds or retained uploads during

  the qualified idle/panel windows.

Analyzer Area remains guarded at controller level pending an actual, separately

qualified Analyzer owner, including stale-guide rejection and history. Direct

numeric paths/points do not prove that workflow. Physical VertexPaint strokes,

UI drag/scroll/DPI and renderer behavior were not newly qualified here. Single

optional-route Update timings are observations, not controlled performance

distributions. The prior small-count overhead remains an N08 requirement.

Corrected iterations are retained: the test initially supplied an invalid empty

density curve, a helper conflicted with MAXScript's `log`, and Data Channel's

operator ID required its full-width Integer64 representation. The controller key

writer now explicitly writes its prefix into an empty StringStream. Final

qualification must use the receipt's exact source/test hashes; earlier script-only

host iterations are not the final pair. No product version bump or installer is

created for this internal checkpoint.

Final exact-pair validation also passed all 43 native suites, 168 Python tests,

the generated-source check, the earlier native controller/history/lifecycle

matrix, the existing default-engine core tests and all eight ready-preset

Load/Undo/Redo/save/reopen cases. The receipt verifies 180 frozen source inputs,

actual loaded native paths/hashes, final driver/log hashes and guarded host exit.

The owned final session is closed; artist sessions and installed packages were

preserved. New implementation evidence is still read from these originals until

a reviewed knowledge-index successor enrolls it.

## Next dependency-ready work

N05 implementation decision, now implemented for the preview input adapters:

retain the existing Point/Mesh snapshots and

atomic draw publication. Add a host-thread reader for either the native view

or the temporary legacy comparison input; reconstruct only stack SDK Matrix3

values for the shown subset. Validate all source indices and Band ownership,

including unshown inputs, before producing a cache. A native full-cache equality

query will compare points, triangles, instance matrices, bounds and palettes

without diagnostic population expansion. Test all display modes, budgets,

colors, placeholders, failure retention and resource release before routing the

controller. Source-count equality is insufficient to establish publication asset

correspondence: capture stable source IDs/handles and input/publication epochs

at the root transaction, preserving Manual pending settings and existing Undo.

The connected Surface random route now has scoped source/receiver binding,

preparation, acceptance, retained preview and ordinary Count Undo/Redo evidence.

Ordinary scalar history keeps its existing refresh semantics;

do not introduce full placement snapshots for every Count change merely because

the standalone hold probe can retain them. Complete optional Paint/mask/Band/

Analyzer/Relax adapters, active Edit, inspection/render/PFlow/Bake and the full

N01–N09 acceptance before declaring the foundation finished. Preserve Float32

boundaries and slope/altitude formulas and controls.

The first coherent qualified user delivery remains 0.86.0 with matching MZP/EXE.

These adapters are internal prototypes; there is no new user installer yet.

Next qualify the actual Analyzer Area controller workflow and adapt boundary

falloff, then Brush's cross-module output, special Analyzer orientation/final Relax

and the remaining optional consumers.

Reuse the existing numerical expressions and Float32 boundaries. Every changed

record builder preserves source and evaluated-receiver provenance; removal-only

stages can return native selections. Seal preparation only after these stages.

For mesh masks, preserve the newly qualified numeric signature and same-frame

mapping/Data Channel behavior. Actual physical VertexPaint stroke notifications

remain a separate qualification; do not infer them from the numeric fixture,

Forest's static research or unchanged topology.

Follow-on source inspection, 18 October: `boundary_falloff_bridge.inc` converts

rows to the existing numeric `amin::boundaryFalloff` kernel and reconstructs them.

Preserve its three-dimensional Analyzer distance versus world-XY Area distance,

strict deletion edge, curve sampling, candidate stream 7 and final Float32

conversion. Its input/output `Instance` vectors are separate scratch costs;

removing MAXScript transport does not by itself remove those copies.

`cyrusBrushRegionFilter` is owned by the separate Brush module. Its current

placement API only leases read-only records. A successor output API must keep

allocation, builders and final script-value ownership in AminScatter, preserve

source/receiver provenance and use a bounded POD boundary. Preserve the existing

UTF-16 population hash, full candidate threshold, strongest-density union with

saved-order ties, and Float32 scale multiplication. Do not pass STL ownership

between modules or materialize a full script population to work around the

missing output operation. Qualify exact-pair rejection, partial failure and last

lease release along with Paint/Undo/receiver and final-output parity.
