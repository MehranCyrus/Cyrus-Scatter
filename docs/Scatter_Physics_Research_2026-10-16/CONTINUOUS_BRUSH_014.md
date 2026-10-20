# Physics Lab 0.1.4 continuous-brush implementation

Authorized 17 October 2026: implement and test CB1–CB6 from
[the continuous-brush research](CONTINUOUS_BRUSH_RESEARCH_20261017.md) in the
standalone Physics Lab. Keep crash diagnostics. Max 2027 only; no Computer Use,
main Scatter integration, preset work or artist installation.

## Version and ownership decision

0.1.3 → **0.1.4**, the next independent laboratory development delivery. This is
a substantial behavior change despite the small-step label: multiple gestures
share a live world, explicit Finish/Freeze publish, live Undo restores coupled
body state, and paused sessions can be recovered. Retain registration IDs.
Scene schema 2 adds pending-session recovery; schema-1 completed caches remain
readable without replay. Solver profile `cpl-continuous-1` identifies new solves.
Old receipts and the 0.1.3 installer remain frozen.

One native worker owns each live world's mutable physics state. Max captures
inputs and publishes on its host thread. Inputs are fixed for a session;
changed bindings invalidate Resume and preserve the last complete result.
Native immutable snapshots carry display data. Bounded native checkpoints and
ordered commands support history; persistent IDs never rewind on Undo.
Completed sessions remain fixed blockers. Finish/Freeze use short Max Undo
transactions, with previous complete output retained on failure.

Resource admission covers bodies, geometry, contacts, scratch, command queues,
preview buffers, history/checkpoints and recovery files. No unbounded catch-up
or silent history deletion. Capture/worker/Undo/render peak costs and source
identities must be recorded in final evidence.

## Delivery and gate status

**Implemented and qualified for standalone testing on 17 October 2026.**
The artist's physical interaction/viewport acceptance remains open. This is not
main Scatter integration or a production-reliability certification.

| Gate | Result and scope |
| --- | --- |
| CB1 | Passed: persistent world across gestures, batch admission, explicit Pause/Resume/Finish/Freeze/Cancel, stable IDs, harmless closed callbacks. |
| CB2 | Passed: native worker advances during a held gesture while the host makes no calls; bounded command queue/debt, pause/resume and retirement. Scripted 1,000-body interaction p95 **43 ms**; physical input/presented-frame latency unmeasured. |
| CB3 | Passed: outside misses, exit/re-entry without bridge births, partially outside footprints, holes, finite support, falling-body removal and lower support. |
| CB4 | Passed: coupled pre-stroke poses/velocities/sleep, live Undo/Redo, ordinary Max result Undo, atomic failed publication, paused save/reopen, clone/merge and crash recovery. |
| CB5 | Passed within the fixtures below: 1,000/5,000 distributed low-poly stress, queue and history admission, repeated lifecycle operations, both publication faults, native exception capture and abrupt-exit recovery. Dense piles and arbitrary allocation failures remain outside qualification. |
| CB6 delivery | Passed: exact ordinary native/script MZP, archive/hash/host guards, isolated installation and restart, automatic startup and **57 installed-pair Max checks**. |
| CB6 artist acceptance | Open: real mouse/tablet feel, the artist's screen/DPI, presented FPS and representative production scenes. |

Package:
[`CyrusPhysicsLab-0.1.4-Max2027.mzp`](../../dist/CyrusPhysicsLab-0.1.4-20261017-03/CyrusPhysicsLab-0.1.4-Max2027.mzp)
— **796,927 bytes**, SHA-256
`6f616ddb04605953a9ea5216d26d5ca518f71302666348ae6de33bd8b33fd2ec`.

Run it through **Scripting > Run Script**, save work and restart **Max 2027**.
Create **Geometry > Cyrus Labs > Cyrus Physics Lab**. The installer was exercised
only in an owned disposable profile. The artist's running Max session was not
installed into, restarted, or controlled. Earlier `-01` and `-02` packages are
internal superseded candidates; the link above is the delivery.

## Implemented behavior and ownership

- One `LiveSession` worker exclusively owns each mutable Jolt world. It receives
  copied geometry/settings and ordered numeric commands, never Max SDK objects.
  Max captures inputs, operates Painter, reads immutable snapshots and publishes
  the result on its host thread. Physics advances independently of the UI timer.
- Mouse-up closes a gesture while the world continues. Later gestures interact
  with earlier moving bodies. Completed sessions remain fixed blockers.
  Distance-based emission does not keep adding bodies while the cursor is still.
- Pause/right-click/panel close retain pending work. Finish settles the session;
  Freeze publishes the current preview with `settled=false`. Cancel discards only
  pending work. Input/owner changes prevent resumed authoring until reconciled;
  the copied preview can be frozen deliberately.
- Live Undo restores the coupled world, including earlier bodies moved by the
  removed stroke. Redo restores the captured later world. Empty outside gestures
  add no history and do not discard Redo. A cancelled gesture keeps prior strokes.
  Artist IDs and gesture IDs are never rewound by live Undo.
- Each footprint candidate is projected to the receiver. Unsupported candidates
  are skipped, and cursor misses break path interpolation. A pending body is
  removed only when its full collision bounds fall below a conservative plane
  beneath all scene colliders. Lower support is therefore retained.
- Finish/Freeze publish through a short Max Undo transaction. Injected failures
  before publication and after assignment retain both the previous result and
  the pending preview. There is no automatic retry; explicit retry succeeds.
  Global Undo pauses live work; undoing its completed base discards dependent
  pending work rather than mixing incompatible states.
- Saved pending scenes display cached geometry without automatically simulating.
  Matching solver fingerprints allow native replay on Resume; another solver can
  still Freeze the cached preview. The recovery core uses schema 2: full births
  are stored once, historical checkpoints reference birth IDs, and a small
  catalog holds births needed only by Redo. No raw engine checkpoint bytes are
  accepted from disk. In-memory Undo uses native checkpoints.
- Source, receiver and collider recapture validates topology and physical data.
  Numeric recapture tolerates `1e-8 + 1e-6 * magnitude` for float fields; integer
  identities/topology remain exact. Max open/merge can convert metres to current
  scene units. The host frame is adopted only after all copied inputs still
  match in metres; the stored solver inputs stay unchanged.

The core and resource lifetimes are C++. MAXScript remains the compact native
rollout/control layer. The new header has Start/Resume, Pause, Finish, Freeze,
Undo stroke, Redo stroke and Cancel session. Status/error text wraps and grows the
rollout. Native control rectangles, font fit and non-overlap passed at **150%**
scale, including a long error. These were programmatic measurements, without
screenshots or Computer Use.

Key source:
[`live_session.h`](../../CyrusPhysicsLab/include/live_session.h),
[`live_session.cpp`](../../CyrusPhysicsLab/src/live_session.cpp),
[`jolt_world.cpp`](../../CyrusPhysicsLab/src/jolt_world.cpp),
[`max_live.inc`](../../CyrusPhysicsLab/src/max_live.inc),
[`max_host.cpp`](../../CyrusPhysicsLab/src/max_host.cpp),
[`CyrusPhysicsLab.ms`](../../CyrusPhysicsLab/scripts/CyrusPhysicsLab.ms).
The [artist guide](../../CyrusPhysicsLab/README.md) describes usage and recovery.

## Verification and measured costs

The retained [evidence JSON](CONTINUOUS_BRUSH_014_EVIDENCE.json) includes full
build/source hashes, launch identities, assertions, layout measurements, timing
samples, crash receipts and the installed-pair receipt. Its
[collector](continuous-brush-fixtures/collect_014.py) verifies those identities.

- **3,174 existing native checks + 413 continuous-brush checks** pass. They include
  a witness where stroke B moves A, exact full-state Undo, branch/recovery parity,
  Redo-only birth catalogs, holes/lower support, body/history/queue admission,
  timeout retention and repeated worker retirement.
- `build/physics-lab-014-installer-01/`: isolated MZP install and restart; startup
  loads the packaged hashes; all **57 actual-button/Painter SDK checks** pass.
  Held-stroke stepping, another stroke while bodies move, ten pause/resume
  cycles, outside re-entry, live history, paused save/reopen, Finish, Freeze,
  Max Undo/Redo and schema-1 cached input are covered.
- `build/physics-lab-014-secondary-host-03/`: long-status layout, twelve lifecycle
  loops, global Undo, clone/merge, source/frame/unit changes, owner deletion,
  reset, transformed Area regression, two-session Rebuild, and preserved 0.1.0 /
  0.1.1 MAX scenes. Each old scene retains its **60 cached bodies and original
  solver profile**, without replay or resaving the historical file.
- `build/physics-lab-014-fault-host-04/`: exact current source compiled with private
  fault probes. Both publication faults, no automatic retry, explicit retry/Undo,
  Finish timeout and Freeze pass. These modules are never packaged.

The first 1,000-body timing run exposed redundant recovery serialization. The
recording grew to **4,827,824 bytes**, and successive strokes became slower.
After birth-catalog deduplication the same workload recorded **513,117 bytes**:

| Scripted 1,000-body baseline + 20 SDK strokes | Before | After |
| --- | ---: | ---: |
| Median command-to-snapshot plus redraw call | 112.5 ms | 38.5 ms |
| p95, nearest rank | 185 ms | **43 ms** |
| Worst sample | 187 ms | 43 ms |
| Cancel session | 198 ms | **19 ms** |

Timing records live in `build/physics-lab-014-performance-host-01/` and `-02/`.
The latter uses the final native pair and unchanged normal brush/timer path;
only the subsequent long-error-label layout fix differs in that script receipt.
This is SDK-command-to-host-snapshot/redraw-call timing, **not physical click to
presented frame**. These are local shared-workstation observations, not an
exclusive benchmark or universal latency claim. The final installed script was
separately exercised by the installed-pair workflow.

Native stress: separated **8-vertex / 12-face boxes**, one support slab,
`dt=1/120`, four collision substeps, **360 steps**. Both populations finish with
zero moving/lost bodies and pass full-population Undo/Redo:

| Bodies | Step median / p95 / worst | Archive | Undo / Redo | Sampled private memory |
| --- | --- | --- | --- | --- |
| 1,000 | 4.55 / 6.01 / 9.75 ms | 6.49 ms | 1.10 / 1.27 ms | 31.60 MiB |
| 5,000 | 24.47 / 35.60 / 47.89 ms | 37.03 ms | 4.06 / 5.10 ms | 47.83 MiB |

`build/physics-continuous-014-20261017-01/stress-qualified.json` retains the raw
values. Memory is sampled native-process private memory, not Max's full working
set or a guaranteed peak. The Max timing run separately recorded approximately
2.03 GiB peak working set and 2.90 GiB private bytes for the whole application.
The 5,000-body case exceeds an 8.33 ms step budget and is a capacity stress, **not
an interactive or dense-pile promise**.

## Crash diagnostics and recovery receipts

Existing flushed ring logs, build/module identity, geometry contexts and the
external dump watcher remain. Worker records add command sequence, session epoch,
applied birth steps, clock clamps, removals, history and retirement. The UI records
heap/process-memory heartbeats at most once per second during live work.
Recovery writes use a temporary file, flush and atomic replace. A bounded status
file distinguishes active, committed and cancelled slots.

- `build/physics-lab-014-fatal-02/`: injected native access violation
  `0xC0000005`, which Max translated to a script exception before the owned host
  exited. The first dump is **10,916,644 bytes**, has an MDMP header and a successful
  dump receipt. A later dump attempt failed; the first dump remained intact.
- `build/physics-lab-014-hardkill-02/`: immediate process termination, exit **77**,
  with no exception notification. The flushed log and complete recovery JSON
  survived without an orderly plugin shutdown.
- `build/physics-lab-014-recovery-host-03/`: both recordings restore their three
  bodies and three-stroke history, replay with the matching solver, support
  Undo/Redo and Freeze. Deliberate solver mismatch rejects replay while retaining
  the cached preview and allowing Freeze.

These tests verify the recorded boundaries. They do not guarantee a final dump
under every OS, disk, stack or allocation failure, or recovery of the last
unflushed input/step. The supplied artist recording remains untouched.

## Budgets, provenance and remaining acceptance

Budgets include 384 queued samples / 512 total commands, 128 gestures, 64 MiB
native history, 16 MiB per engine checkpoint, 32 MiB recovery file, eight live
recovery slots and 120,000 live steps. Finish has its own step budget and 30-second
wall limit. Numeric work slices check elapsed time after each step, target six
milliseconds and cap at eight steps; an individual step cannot be preempted.
Recovery-history pressure cannot prevent publication: Finish/Freeze request only
the bounded current birth recipe, not the whole recovery history. Preview/source,
body, contact and scratch bounds remain separate. A language change alone is not
proof against arbitrary OOM.

Initial branch/HEAD: `codex/workflow-0.75`,
`8645c6cc4878a05e8fa6f835610872b2da1359ea`. The owned baseline in
`build/physics-continuous-014-20261017-01/` preserves the original lab and dirty
workspace inventory. Other work continued in the shared repository; this task
edited only the lab, its research/navigation documents and owned build outputs.
It did not edit presets, integrate Scatter, commit or push. Knowledge retrieval
was stale; original source and new receipts supplied the engineering evidence.

The ordinary delivery pair and matching PDBs are frozen under
`build/physics-continuous-014-20261017-01/qualified/`. The reusable `native-01/`
directory now contains the **private fault build**, deliberately rejected by the
packager. Use the qualified snapshot or the linked MZP, not that development DLL.

Next acceptance belongs to the artist: install the supplied MZP, repeatedly draw
while earlier objects collide, leave/re-enter the receiver, pause/resume, try
stroke Undo/Redo, then Finish or Freeze. Judge physical input and panel sizing on
the real setup. Keep representative dense/complex scenes as a separate next
performance/quality gate. No main-plugin merge is implied by this delivery.
