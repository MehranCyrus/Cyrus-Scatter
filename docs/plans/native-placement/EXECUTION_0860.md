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

Knowledge status after activating this goal: the selected 36-parent generation
is compatible, with 34 current parents; the reviewed edits to `AGENTS.md` and
root `README.md` make those two enrolled parents stale. Native execution plans
and new sources are read directly. Do not present the old index as fully fresh;
publish a reviewed successor at the delivery knowledge checkpoint.

## Next dependency-ready work

Finish remaining N01 ownership/history probes and N02 boundaries, then connect
one Surface-random native path through acceptance, retained preview and ordinary
Count Undo/Redo. Preserve Float32 stage boundaries and slope/altitude formulas
and controls. Expand to optional features and consumers only with parity evidence.
The first coherent qualified user delivery remains 0.86.0, with matching MZP/EXE;
there is no new installer from this internal storage checkpoint.
