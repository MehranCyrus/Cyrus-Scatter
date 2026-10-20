# Physics Lab validation and delivery report

**Standalone 0.1.4 · Max 2027 · 17 October 2026**  
[Documentation home](DOCUMENTATION.md) · [Detailed implementation ledger](CONTINUOUS_BRUSH_014.md)

## Delivery assessment

The continuous-brush implementation is delivered for standalone artist testing.
Recorded checks cover native state contracts, Max interaction through the actual
rollout/Painter SDK path, result Undo, pending-session persistence, boundary
behavior, private publication faults, diagnostics, recovery and isolated package
installation. The user subsequently reported that brushing felt very fast and
optimized.

That feedback adds a positive artist observation to the automated evidence. It
does not establish an instrumented viewport rate, full UI/DPI acceptance, a
particular production-scene capacity or an audit of the artist's loaded module
hashes. Broader production qualification and CyrusScatter integration remain open.

This report consolidates existing evidence. The documentation pass did not
modify feature code, launch Max, repeat the benchmark, install into the artist's
profile or use Computer Use.

## Exact delivery

| Item | Recorded identity |
| --- | --- |
| Package | [CyrusPhysicsLab-0.1.4-Max2027.mzp](../../dist/CyrusPhysicsLab-0.1.4-20261017-03/CyrusPhysicsLab-0.1.4-Max2027.mzp) |
| Package bytes | 796,927 |
| SHA-256 | `6f616ddb04605953a9ea5216d26d5ca518f71302666348ae6de33bd8b33fd2ec` |
| Host qualification | Max 2027 only |
| Solver profile | `cpl-continuous-1` |
| Core solver fingerprint | `5db7dc8f07cdea4960ae3b5c583dcb07955e5191a36be20b15fece6a949d0b8c` |
| Scene/result schema | 2; historical schema-1 completed caches retained |
| Qualified ordinary modules and PDBs | [Frozen qualified directory](../../build/physics-continuous-014-20261017-01/qualified/) |
| Complete evidence | [CONTINUOUS_BRUSH_014_EVIDENCE.json](CONTINUOUS_BRUSH_014_EVIDENCE.json) |

Install using **Scripting > Run Script**, save work and restart Max 2027. Create
**Geometry > Cyrus Labs > Cyrus Physics Lab**. Package integrity, payload hashes,
host guard and private-fault exclusion were checked; the MZP was installed and
restarted in an owned disposable profile, followed by the installed-pair workflow.

The reusable `build/physics-continuous-014-20261017-01/native-01/` directory now
contains a **private fault build**. It is not the shipping pair. Use the frozen
qualified directory or the exact MZP above. Internal `-01`/`-02` MZPs are superseded
candidates. Version captions alone cannot distinguish these artifacts.

## Implemented scope

| Phase | Delivered behavior | Evidence boundary |
| --- | --- | --- |
| CB1 — lifecycle | Persistent world, multiple gestures, Pause/Resume/Finish/Freeze/Cancel, stable identities | Native and Max SDK workflow; physical input not instrumented |
| CB2 — scheduling | Dedicated worker, fixed steps, bounded debt/queue, immutable preview | Worker progress during held gesture without host calls; scripted latency below |
| CB3 — outside support | Miss breaks path, partial footprint clipping, lost-body removal, lower support | Numeric and Max boundary fixtures |
| CB4 — history and persistence | Coupled live Undo/Redo, result Undo, save/reopen, clone/merge, recovery | Matching solver/input fixtures and deliberate mismatch |
| CB5 — robustness | Admission, retirement, publication failure retention, stress, diagnostics | Bounded cases; arbitrary allocation/OS/disk failure remains unqualified |
| CB6 — delivery | Exact ordinary pair, MZP, isolated installation/restart | 57 installed-pair workflow checks; broader artist acceptance remains separate |

These CB identifiers belong to the continuous-brush follow-up. They do not
complete the entire original Scatter physics roadmap or the main plugin's
P/I/PG/N programs.

## Verification inventory

| Evidence | Recorded result | What was exercised |
| --- | --- | --- |
| Native core tests | **3,174 checks passed** | Existing input, geometry, solver and result contracts |
| Native continuous tests | **413 checks passed** | Coupled Undo, identity, branch recovery, Redo-only catalogs, empty/outside gestures, support/removal, admission and retirement |
| [Installed package](../../build/physics-lab-014-installer-01/) | **57 Max checks passed** | Actual rollout handlers/Painter SDK, held-gesture stepping, another stroke while moving, pause/resume, outside re-entry, save/reopen, Finish/Freeze and Max Undo/Redo |
| [Secondary host checks](../../build/physics-lab-014-secondary-host-03/) | Passed | Twelve lifecycle loops, unrelated global Undo, clone/merge isolation, invalidation, deletion/reset, transformed Area, two-session Rebuild and old cached scenes |
| Secondary native-control measurements | Passed at **150% scale** | Rectangles inside bounds, font fit and no overlap, including long error text |
| [Private fault host](../../build/physics-lab-014-fault-host-04/) | Passed | Before-publication and after-assignment faults, previous/pending retention, no automatic retry, explicit retry/Undo, Finish timeout and Freeze |
| [Recovery host](../../build/physics-lab-014-recovery-host-03/) | Passed | Both final crash recordings, same-build Resume, Undo/Redo, Freeze and mismatch rejection |

The old 0.1.0 and 0.1.1 scene checks each retained 60 cached bodies with their
original solver profile, without replaying or resaving the historical file.
The layout checks used native metrics; no screenshots or Computer Use were used.
Check counts identify the retained runs and are not substitutes for their scope.

## Performance measurements

### Scripted interaction with 1,000 pending bodies

Twenty actual SDK sample gestures were measured after preparing 1,000 low-poly
bodies. The measured path ends at the host snapshot plus redraw **call**. It is
not a physical mouse-to-displayed-frame measurement.

| Metric | Before recovery deduplication | After |
| --- | ---: | ---: |
| Median | 112.5 ms | **38.5 ms** |
| p95, nearest rank | 185 ms | **43 ms** |
| Worst sample | 187 ms | 43 ms |
| Cancel session | 198 ms | **19 ms** |
| Durable recovery size | 4,827,824 bytes | **513,117 bytes** |

Before: [performance-host-01](../../build/physics-lab-014-performance-host-01/).
After: [performance-host-02](../../build/physics-lab-014-performance-host-02/).
The latter uses the final native pair. Its script receipt precedes only the
subsequent long-error-label layout fix; the normal brush/timer path is unchanged.
The final script was independently exercised by installed-package tests.

Recovery formerly repeated full birth lists for historical points. The new
representation stores full current births once, references IDs in history and
retains only Redo-specific extra births in a catalog. The smaller record and
lower measured cost support this targeted optimization. The broader advantage
of continuous worker ownership is architectural; this comparison does not
isolate a C++-versus-MAXScript language speedup.

These runs shared the workstation with other work. They are local observations,
not an exclusive benchmark or a guarantee for another scene. The Max timing run
recorded approximately **2.03 GiB peak working set** and **2.90 GiB private bytes**
for the whole application, not just the lab.

### Native capacity stress

The fixture used separated 8-vertex/12-face boxes, one support slab, fixed
`dt=1/120`, four collision substeps and 360 steps. Both populations finished with
zero moving/lost bodies and passed full-population Undo/Redo.

| Metric | 1,000 bodies | 5,000 bodies |
| --- | ---: | ---: |
| Step median | 4.55 ms | 24.47 ms |
| Step p95 | 6.01 ms | 35.60 ms |
| Worst step | 9.75 ms | 47.89 ms |
| Archive | 6.49 ms | 37.03 ms |
| Undo / Redo | 1.10 / 1.27 ms | 4.06 / 5.10 ms |
| Sampled native-process private memory | 31.60 MiB | 47.83 MiB |

[Raw stress receipt](../../build/physics-continuous-014-20261017-01/stress-qualified.json).
Sampled private memory is not a guaranteed peak, a measurement of Max memory or
VRAM. The 5,000-body step cost exceeds an 8.33 ms interval and therefore
establishes a **capacity stress result**, not interactive or dense-pile capacity.
Friction, contact density, source complexity and scene support materially change
the workload.

## Diagnostics and recovery tests

| Test | Recorded observation | Limit |
| --- | --- | --- |
| [Injected native fault](../../build/physics-lab-014-fatal-02/) | `0xC0000005`; first valid MDMP file **10,916,644 bytes**, successful individual receipt | Max translated the injection into a script exception before host exit; not an original uncaught artist crash |
| Later dump attempt in that run | Failed while the first dump remained intact | Last status alone does not describe all attempts |
| [Abrupt termination](../../build/physics-lab-014-hardkill-02/) | Exit **77**, zero exception notifications; flushed events and complete recovery survived | No final exception dump expected from this termination route |
| Restoring both recordings | Three bodies/three-stroke history, same-solver replay, Undo to two, Redo to three, Freeze | Matching controlled input; last unflushed work may be absent |
| Deliberate solver mismatch | Replay rejected; cached preview retained and Freeze allowed | Cached appearance is not proof of resumable state |

The recorder and recovery are designed around retained durable boundaries.
These tests do not establish guaranteed final capture under all disk, OS, stack,
allocator or fail-fast conditions. Original artist recordings remain untouched.

## Artist observation after delivery

On 17 October 2026, after receiving the 0.1.4 package, the user described the
performance as very optimized and fast, then asked whether the body count was
limited to 1,000. The source-confirmed explanation is that 1,000 is the UI default
and 5,000 the current maximum setting, with additional independent resource caps.

Record this as **positive subjective interaction feedback**. The conversation
does not specify the scene geometry, population, hardware, measured frame times,
loaded hashes, a sustained test duration or acceptance of every control. The
historical implementation ledger's open artist gate is preserved; this report
adds the later observation without retroactively rewriting the test receipts.

## Reproduction and artifact preservation

The [project guide](../../CyrusPhysicsLab/README.md#reproduce-the-experiments)
contains build and host commands. Use fresh owned directories and the documented
local toolchain. The build script records pinned dependencies and source hashes;
never mix a new script with old native modules. Max tests must use the verified
ordinary pair in disposable profiles, never the artist's session.

The retained [evidence collector](continuous-brush-fixtures/collect_014.py)
checks source/binary identities, package payloads, installed restart, geometry,
fault separation, recovery and diagnostics. Running it regenerates the release
evidence JSON from existing receipts; it does not rerun Max or native tests.
Preserve original receipts before producing a new delivery's evidence.

`build/`, `dist/`, scenes, native modules and installers are ignored local
artifacts. Preserve the exact MZP, ordinary modules/PDBs, source receipt, relevant
scenes and diagnostics separately. A Git commit alone does not back them up.

## Remaining acceptance and next decisions

| Open gate | Evidence needed before closing it |
| --- | --- |
| Artist interaction | Repeated continuous strokes, outside/re-entry, pause/resume, both Undo scopes and correct control sizing on the actual setup |
| Representative contact quality | Curved/thin leaf proxies, arbitrary supports, dense piles and relevant material/scale settings |
| Sustained performance | Defined scene/input, repeated frame-time and interaction measurements, memory retention and growth |
| Broader host/render coverage | Explicit Max/renderer/display scenarios beyond the retained fixtures |
| Increased limits | Measured queue/history/geometry/solver and failure behavior at proposed populations |
| Engine decision | Matched quality as well as cost in representative Jolt/PhysX cases |
| CyrusScatter integration | Separate authorization, ownership/persistence/display design and new acceptance under the main plugin contracts |

The present delivery is useful for testing and has a positive initial artist
response. Its documented limits remain part of that assessment.
