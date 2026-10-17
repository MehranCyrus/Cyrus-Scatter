# Native foundation execution — 0.86.0 target

17 October 2026. Internal implementation progress under the [active goal](../improvement-program/OBJECTIVE.md).
**Not a 0.86.0 delivery or complete N01–N09 acceptance.** Existing pipeline and
product metadata remain 0.85.4/schema 58 while storage is qualified separately.

## Preserved baseline

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

## Next dependency-ready work

Adapt retained Point/Mesh preview consumers and coherent native publication,
then connect Surface random through native acceptance, preview and ordinary
Count Undo/Redo. Ordinary scalar history keeps its existing refresh semantics;
do not introduce full placement snapshots for every Count change merely because
the standalone hold probe can retain them. Complete optional Paint/mask/Band/
Analyzer/Relax adapters, active Edit, inspection/render/PFlow/Bake and the full
N01–N09 acceptance before declaring the foundation finished. Preserve Float32
boundaries and slope/altitude formulas and controls.

The first coherent qualified user delivery remains 0.86.0 with matching MZP/EXE.
These adapters are internal prototypes; there is no new user installer yet.
