# Validation, performance and phase completion

Current execution status is in the [phase table](../improvement-program/PROGRESS.md#original-phase-status):
P01–P07 implemented, P08/P09 pending, P10 delivered for supported recipe/library
scope and P11 partial. Further implementation is paused. Version assignments and
enrollment instructions in this original specification are historical; use the
current version policy and user instruction for any new delivery.

This matrix supplies the common acceptance process for all eleven phases. It
does not assert universal correctness or turn old passing receipts into new ones.
Read [implementation scope](IMPLEMENTATION.md) before selecting the tests.
The separate [0.82.4 mesh mask campaign](MESH_MASK_0824.md) records current
Max 2027 channels, Curvature, Paint composition, lifecycle and idle witnesses;
P06 remains paused.

## Evidence levels

| Level | What it establishes | What it does not establish |
| --- | --- | --- |
| Source inspection | Chosen contract and implementation/dependency path | Executed correctness |
| Native/offline | Numeric behavior, bounded algorithms, pure-state tests | Max UI, actual SDK callbacks or rendering |
| Matched private host | Actual script/native behavior for pinned fixtures/host | Every physical gesture, asset, renderer or machine |
| Physical/visual workflow | Observed interaction, visible layout/result | Unmeasured performance or exhaustive reliability |
| Renderer witness | Tested renderer/source/material/output combination | All renderers, proxies or animation families |

Use **planned**, **implementing**, **verification**, **blocked**, and **complete**
statuses in TODO. Complete requires the phase's required acceptance, recorded
source identities, coherent commit and verified push. Broader release boundaries
can remain explicitly open only when they are outside the phase's promised scope.
Do not downgrade a product failure to an optional gate after the fact. The user
explicitly clarified on 14 October that their own artist acceptance is at the end
of all eleven phases. Agent-run Max and automated checks remain required per
phase. Unavailable Computer Use is recorded as a physical/visual evidence limit
and carried to final acceptance; it does not block implementation or Git delivery.

## Common invariants

| ID | Check | Required comparison |
| --- | --- | --- |
| V01 | Owner correctness | Edit A; verify saved settings, identities and result belong to A; switch/copy/remove/Undo owners |
| V02 | Determinism | Same relevant inputs produce same ordered IDs, models and full transforms in the qualified environment |
| V03 | Independent randomness | Change size/orientation/display without consuming unrelated position/source random channels |
| V04 | Scoped dependency reuse | Edit independent B; compare A's full result and preparation/upload counters, accounting for shared admission |
| V05 | Manual/Live | Pending Manual settings stay unpublished through browsing/display/help; relevant Live inputs update; unrelated time changes do not |
| V06 | Complete publication | Failure before and during install retains matching rows/sources/radii/statistics/display/output from the previous complete result |
| V07 | Resource bounds | Invalid/excessive inputs fail within work/memory budgets; retries report underfill; no hidden unbounded loop |
| V08 | Persistence | Current-schema save/reopen, copy, merge and Undo/Redo retain intended authored values/identities |
| V09 | Units/transforms | World distances, density and receiver/source transforms retain physical meaning within supported conversion scope |
| V10 | Output parity | Final render/exact output consumes the intended accepted publication and final source basis |
| V11 | Real UI route | Invoke generated controls and subsequent callbacks; test owner lifetime and displayed state, not only internal helpers |
| V12 | Documentation | Guide/tooltips/catalog match proven behavior; internal IDs remain stable; website sources clearly distinguish source from deployment |

Select applicable V checks per phase; shared acceptance/cache/publication changes
require the affected earlier-phase regressions. Pure wording changes do not need
new tests that merely compare implementation strings; use existing generation
checks and an actual workflow witness where status behavior changes.

## Fixture set

- **F-Small:** two independent layers, two receivers, Model/Point/Empty rows,
  disabled/hidden owners and one linked spacing pair. Fast host lifecycle checks.
- **F-Terrain:** plane, tilted terrain, vertical/underside faces and transformed
  receivers with known elevations, two distinct UV channels and explicit holes.
- **F-Patterns:** analytic lattice/path/reference cases with independent expected
  coordinates, sequences and interval boundaries.
- **F-Maps:** constant, ramp, checker and color regions; missing/invalid channels;
  animated map and unrelated animated scene object.
- **F-Assets:** simple, dense, mirrored/nonuniform and supported proxy sources;
  missing-class cases retained as failures, not disguised substitutions.
- **F-Production:** owned copies of the terrace plus purpose-built orchard/path
  and mixed-recipe scenes. Hash originals; record source/texture dependencies.
- **F-Failure:** finite-work exhaustion, invalid settings, missing dependencies,
  storage failure where applicable and supported publication fault injection in
  private builds only. Never ship diagnostic authorities in product packages.

| Phase | Focused fixture requirements |
| --- | --- |
| P01 | F-Small state/owner matrix; empty/failed/limited preview; passive-read counters; actual generated panel |
| P02 | Preset/curve round trip and malformed/unwritable files; F-Small Undo/Manual/units |
| P03 | F-Terrain analytic filters plus Paint/Bands/refill/protected edits |
| P04 | F-Maps UV channels/resolutions; F-Terrain transforms; relevant animation |
| P05 | Vector/spline loops, holes, tolerance, transforms and malformed imports |
| P06 | F-Patterns lattice oracle and boundary-change identities; F-Terrain projection |
| P07 | F-Assets final basis/radii; coincident/animated/deleted targets |
| P08 | F-Patterns arc-length oracle, seam/sequence rules, reference lifecycle |
| P09 | F-Maps × supported layouts; source roles/weights; final-bound collisions |
| P10 | Multi-layer F-Production recipe/binding round trips; data/storage failures |
| P11 | Complete prior matrix plus F-Assets/F-Production navigation, modes and sustained resource cycles |

## Performance protocol

Record the machine/Max year, viewport size/mode, source geometry, shown population,
camera, renderer, settings and background workload. Pin the source and loaded
binary/script hashes before collecting candidate evidence.

Measure separately:

1. Cold editor construction and first source/receiver preparation.
2. Candidate generation, filtering, transform/radius work and spacing/cleanup.
3. Publication staging and retained CPU/GPU preparation/upload.
4. Warm unchanged reads, independent-layer edits and repeated mode changes.
5. Scripted redraw duration; actual presented frame times only when a suitable
   measurement exists. Neither one is automatically the other.
6. Current retained resources, peak working set and measured GPU memory where
   available. Conservative reservations are not detected available VRAM.
7. Render preparation/output time independently of viewport presentation.

For timings, include repetitions and median/p95 when the sample size supports it;
use paired baseline/candidate runs and reverse order where useful. Set a relevant
regression threshold after observing baseline variability. Do not invent a global
FPS/latency target before measuring the fixture. A consistent regression outside
noise requires explanation and resolution or an explicit product tradeoff.

Hard invariants have no timing tolerance: unchanged warm browsing/navigation must
not solve or re-upload unchanged data. Resource cycles must stabilize within the
documented cache policy; monotonic growth requires investigation. A faster result
with different planting is not an equivalent performance improvement.

## Commands and host isolation

Follow [the agent workflow](../../AGENT_WORKFLOW.md) for current commands and fresh
run directories. Typical checks include generator reproducibility, approved UI
layout, generated integration, native CTest and MCP/tools pytest. Under the user's
14 October 2026 rule, compile with the **Max 2027 SDK only** and validate real
generated MAXScript, physical interactions and performance in **Max 2027 only**.
Max 2026 testing requires a new explicit user request. Preserve the completed
P01–P05 dual-version receipts as historical evidence.

Inspect each launcher before using it. Test in owned redirected profiles under
ignored `build/`; hash/copy artist scenes; serialize mutations per host. After a
timeout, inspect completion before retrying. Stop only recorded owned processes.
Keep original profile hashes and scene hashes in preservation receipts.

An existing receipt's script hash cannot be relabeled after edits. For script-only
changes, either build a fresh matching candidate or explicitly verify every native
source input is unchanged, record the new script identity and document the reused
native ABI before launch. Never bypass a mismatch assertion to make a test run.

## Completion receipt

Each phase records in TODO/progress and its local detailed receipt:

- Behavior delivered, chosen version and impacted schema/native/API domains.
- Starting commit and pre-existing changes; final commit and remote branch/hash.
- Frozen source/build/script/native hashes and host/fixture identities.
- Exact commands, check outcomes and diagnostic files for failures as well as passes.
- Before/after performance with conditions and applicability limits.
- Actual visual/physical/render checks, and clearly named unperformed scenarios.
- Updated guide/catalog/website-source status and next phase's entry conditions.

Git does not preserve ignored scenes, SDKs, binaries and installers. Record their
local paths/hashes; do not imply the source commit contains those artifacts.
