# Physics Lab crash diagnostics 0.1.3

17 October 2026. The user reported a native Max crash after Start → brush → Stop
→ Start, with the status “Wait for settling before another stroke.” Scope is the
standalone Physics Lab only, with no Computer Use or artist-profile installation.

Version decision: **0.1.2 → 0.1.3**, a patch delivery for durable diagnostics and
the Painter callback lifecycle. Scene schema 1, solver profile `cpl-leaf-3`, class
IDs and Scatter/preset versions remain unchanged. The 0.1.2 package and historical
receipts are preserved. This is an experimental diagnostic delivery, not general
crash-free certification.

**Delivered result:** the 0.1.2 native null-read path was reproduced and guarded.
0.1.3 records brush input/lifecycle/solver events, MAXScript free heap and process
memory, saves geometry/settings/state, and starts a separate crash-dump watcher.
Final native/script regressions, forced access violation, abrupt termination and
an isolated installation/restart passed. Artist input remains a separate check.

Source hypothesis before changes: after rejecting a stroke while an earlier
stroke is settling, `PaintStroke` calls `cancel()`, clearing `staged`. A following
hit callback dereferences `staged->origin` before `sample()` can recreate it.
Previous private tests stop immediately on a FALSE PaintStroke result and did
not exercise that following callback. Host reproduction and final results will
be recorded below.

The watcher uses a copied exception record/context and `ClientPointers=FALSE`.
Microsoft recommends a separate process for
[MiniDumpWriteDump](https://learn.microsoft.com/en-us/windows/win32/api/minidumpapiset/nf-minidumpapiset-minidumpwritedump)
and documents [exception pointer ownership](https://learn.microsoft.com/en-us/windows/win32/api/minidumpapiset/ns-minidumpapiset-minidump_exception_information).
The exception notification path avoids explicit heap allocation and locks, consistent with
[vectored handler guidance](https://learn.microsoft.com/en-us/windows/win32/api/winnt/nc-winnt-pvectored_exception_handler).

## Reproduced cause and memory question

`build/physics-lab-013-old-crash-01` loaded the exact ordinary 0.1.2 pair/script.
Its fixture used a Plane and Sphere32, invoked Start/Stop/Start, emitted/released
a stroke, then delivered successive actual SDK Painter hit callbacks. The first
late callback reported **“Wait for settling before another stroke”**, cancelled
the pending session and returned FALSE. The second hit callback caused native
**`0xC0000005`, read of address `0x100`**. MaxScript caught that SDK-injected system
exception; the controlled witness is a native access violation, not a claim that
we obtained the original artist application's crash stack.

The source dereferenced `staged->origin` before checking/recreating a session.
`cancel()` had already reset `staged`. The tiny invalid read address and this
observed lifecycle match an intentional null reset, rather than MAXScript heap
exhaustion. The earlier runtime error was a state guard, not an out-of-memory
message. Raising the MAXScript heap is not a fix for this reproduced path.
Other artist failures require their own recording; the original screenshot alone
does not rule out separate memory pressure.

The successor records `maxscript_heap_free_bytes` and process working-set/private/
peak working-set bytes in UI/timer records. In the final owned test there were
**517 memory samples**, with **63,875,520–81,025,460 bytes** of free MAXScript heap
and **2,746,793,984–2,940,710,912 private process bytes**. These are observations
from the owned successor test, not measurements of the artist session or the old
crash baseline. Private process allocation and MAXScript free heap are separate
measurements; neither should be described as total free physical RAM.

## Implementation and recording

- `StartStroke` rejects a new gesture while an earlier one is settling, retaining
  that session. `PaintStroke` checks authoring/session/staged/emitter/picking state
  before accessing pending geometry. Late callbacks after cancellation are ignored.
  End/Cancel callbacks for the rejected gesture retain the earlier settling stroke.
- The recorder flushes each JSONL event through `WriteFile` + `FlushFileBuffers`.
  Entry events precede native calls. Records include button/gesture lifecycle,
  pixel coordinates, world hit/normal/ray, face, source/receiver bindings and node
  handles/names, modifiers/pressure, emitted birth identities/transforms, solver
  steps, errors, commit state, and redraw/timer boundaries.
- Rolling context snapshots contain prepared settings, full source render/collision
  data, receiver/collider geometry, saved rows, pending births/rows and motion.
  Module paths/base addresses and package/build hashes are recorded separately.
  The exact native PDB and source are retained with the frozen build.
- An external `CyrusPhysicsCrashWatch.exe` opens only its launch-recorded parent
  PID and verifies the process creation identity. A fixed shared exception packet
  wakes it. It does not attach as a debugger, replace Max's crash handler, swallow
  an exception, or call host APIs from its process. First-chance fatal-code notices
  can be handled/rethrown by Max; they are labelled as notifications.
- Dumps publish through a temporary file and atomic rename after successful
  completion. A failed later attempt preserves complete earlier dumps. The first
  fault dump is retained and the second slot holds the newest later fault.
  Per-dump receipts and `dump-attempts.jsonl` distinguish success from failure.
- Recording starts with Start brush. **Open logs** occupies the existing reserved
  header space, sharing its position with Keep preview when a timeout offers that
  action. It does not change the main Scatter UI. Native `cplDiagnosticInfo()`
  reports recorder/watcher readiness and file errors; dump attempts have their own
  outcome receipts.

Default folder: `%LOCALAPPDATA%/Cyrus/PhysicsLab/Diagnostics/<UTC-stamp>-pid...`.
Owned tests override the root through `CYRUS_PHYSICS_LOG_DIR`. Events retain four
8 MiB segments; full contexts retain eight slots, at most 32 MiB each; two dumps
are retained per recording. Earlier recording folders are preserved. There is
no automatic upload. Context/dump files can contain scene geometry and process
memory; the user chooses which recording to share.

## Final evidence

Exact hashes, fixtures, loaded paths, memory samples, dump inspection and failed
iterations are in [CRASH_DIAGNOSTICS_013_EVIDENCE.json](CRASH_DIAGNOSTICS_013_EVIDENCE.json).
Executed private fixtures are preserved in
[crash-diagnostics-fixtures](crash-diagnostics-fixtures/physics-lab-013-lifecycle.ms).

| Witness | Result and scope |
| --- | --- |
| `build/physics-lab-013-delivery-20261017-02` | Frozen ordinary native pair, watcher, exact full source, build receipt, native PDB and passing CTest. No private fault build. |
| `build/physics-lab-013-final-03` | All ten existing host fixtures plus **361 lifecycle assertions** passed. Includes UI bounds/captions, Sphere32/Plane, custom/auto proxy, real buttons/timers/Painter hit callbacks, timeout controls, extended authoring, transforms, old cached profiles, 60-leaf demo and the new repeated lifecycle cases. |
| Lifecycle coverage | **50 Start/Stop/restart cycles**, late hits before StartStroke and after cancellation, repeated hits while settling, rejected Cancel preserving the previous session, recovery, exact saved result retention, Undo and save/reopen. |
| `build/physics-lab-013-fatal-03` | Final native/script/helper hashes; forced private-probe null write captured as `0xC0000005`. A **10,578,067-byte** complete dump identifies the private probe as the original fault module. Exception stream, **215 thread contexts** and **33,196 memory descriptors** were checked against file bounds. |
| Follow-on dump failure | After capturing the original fault, the harness terminated lingering owned Max with exit 78. A later rethrow dump attempt reported partial-copy. Its temporary file was not published; the original complete dump and success receipt remained. This failure is retained, not called a second successful capture. |
| `build/physics-lab-013-hardkill-02` | Final exact triplet; `TerminateProcess(...,77)` bypassed clean shutdown. Every retained JSONL line parsed and the last event was the flushed `qa.before_terminate_process` marker after a genuine brush hit. The independent watcher recorded exit 77. A final dump is not expected from this hard-kill path. |
| `build/physics-lab-013-installed-02` | Final MZP hashes, isolated installation, automatic startup after an owned restart, installed exact pair/helper and Sphere32/button/Painter/proxy/roundtrip workflow passed. |

The final full host run matches the delivered native/script hashes. Its helper
was subsequently changed only for first/latest atomic dump retention; the exact
final helper was separately qualified by the forced-fault, abrupt-exit and final
installed-package tests. This distinction is preserved in the evidence.

The initial combined regression loaded two generations of the private Painter
probe and stalled on duplicate primitive registration after the ten existing
fixtures had passed. Only the verified owned PID was stopped. The test fixtures
now use one private probe consistently. Earlier diagnostic candidates, partial
dumps and superseded packages remain as historical receipts. The private probe
and its forced-crash functions are absent from the user package.

The normal Max INI, plug-in registration and lab startup hashes match before/after
the installer campaign. No artist installation/restart was performed. Unrelated
Scatter/preset working-tree changes were preserved. The knowledge index remained
stale (38 checked, 15 verified; Physics Lab unenrolled), so current/frozen source
inspection was used. No commit or push was made.

## User test package

[CyrusPhysicsLab-0.1.3-Max2027.mzp](../../dist/CyrusPhysicsLab-0.1.3-20261017-02/CyrusPhysicsLab-0.1.3-Max2027.mzp),
**718,695 bytes**, SHA-256
`10756869ba3542fcfc4a7d994bba6b03d11d3de4ba0539a338383bc666006720`.
Archive integrity, every payload hash, version/Max guard, script/native/helper
identities and exclusion of private commands were verified. The previously
delivered 0.1.2 package remains byte-identical.

Run the MZP through **Scripting > Run Script**, save work, and restart **Max 2027**.
Confirm the lab caption is 0.1.3, then reproduce Start → brush → Stop → Start.
Recording starts automatically. Use **Open logs** while Max is running. If Max
crashes, keep the newest timestamp/PID folder under the default Diagnostics path;
zip the entire folder, including events, contexts, module/build identities and any
dump/status files. No need to depend on the Listener surviving the crash.

Acceptance limits: no physical mouse/tablet or artist-session validation; the
exact original artist crash is not yet recorded. Abrupt termination/fail-fast,
stack exhaustion, missing access, storage/system failure or power loss may
prevent a final dump. The tested hard-kill path proves survival of already-flushed
events and the independent exit record. The known edge-footprint whole-stroke
abort and zero-birth Undo step are not redesigned in this patch.
