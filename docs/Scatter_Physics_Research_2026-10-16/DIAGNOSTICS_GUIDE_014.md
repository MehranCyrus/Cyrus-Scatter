# Physics Lab diagnostics and recovery

**Support guide · 0.1.4 · Max 2027**  
[Documentation home](DOCUMENTATION.md) · [Artist guide](ARTIST_GUIDE_014.md)

## Start with the observed symptom

The status message, event order, loaded module identity and captured input are
more useful than a screenshot alone. A MAXScript runtime error is not sufficient
evidence of script-heap exhaustion. Distinguish a deliberate limit/state rejection,
a solver or publication failure, and a native exception.

| Symptom | Likely explanation or evidence to inspect | Next action |
| --- | --- | --- |
| Generation stops near 1,000 bodies | Default Body limit | Finish/Freeze pending work, raise Brush > Body limit up to 5,000, then start again; completed bodies still count |
| Limit reached below the visible count expected | Lost births, saved recipe, geometry or history admission | Preserve the exact status; consult the separate budgets in the technical guide |
| No births while holding the cursor still | Distance-based emission | Move the brush along the receiver |
| No births outside the receiver | Intended hit/footprint clipping | Re-enter the receiver; there should be no bridge across the gap |
| Settings remain disabled after Pause | Pending work retains its captured inputs | Finish/Freeze to keep it or Cancel to discard it before editing settings |
| Finish takes time or times out | Bodies remain active, or the bounded settle budget was reached | Inspect support/contact and counts; Resume, Undo, Freeze or Cancel as appropriate |
| Older objects do not move in a new session | Completed output is fixed collision geometry | Keep interacting strokes in one session, or deliberately Rebuild the result |
| Proxy limited to 128 vertices | Explicit custom proxy is too detailed, or an old build is loaded | Use auto for an ordinary render model, or simplify the custom proxy; verify loaded identity |
| Small collision gap or filled hole | Convex proxy envelope differs from the render mesh | Review the proxy shape, thickness and asset scale |
| Resume reports changed inputs | Binding, geometry, transform or units no longer match capture | Review and Freeze the cached preview, or Cancel and start from the intended setup |
| Resume requires the original solver | Recovery fingerprint differs | Use the matching delivered build, or Freeze the cached preview |
| Publication error repeats only on explicit retry | Previous result and pending preview were retained | Preserve logs and exact input; resolve the reported cause before retrying |
| “Wait for settling before another stroke” | Historical per-gesture workflow, not the intended 0.1.4 continuous behavior | Verify the exact script/native pair and restart after installation; report if reproduced with the verified 0.1.4 package |
| Max closes unexpectedly | Native exception, termination or another host/plugin failure remains possible | Preserve the whole recording and scene; do not infer a cause from one UI message |

## Recording location and contents

Recording starts automatically when **Start brush** is pressed. **Open logs**
opens the recording directory. After a crash, browse:

```text
%LOCALAPPDATA%\Cyrus\PhysicsLab\Diagnostics\<timestamp>-pid<process>
```

Keep the entire timestamp/PID folder. Do not retain only the last line, latest
status file or a screenshot of the error.

| Artifact | What it establishes |
| --- | --- |
| `events-*.jsonl` | Ordered UI/Painter/worker events, coordinates, hit/normal/pressure data, births, steps, errors and lifecycle |
| `context-*.json` | Captured source, receiver and collider geometry, settings, completed and pending data |
| `build-identity.json` | The recorded build/package identity |
| `modules.json` | Loaded native module paths and identity information |
| `exception.txt` | Fatal-code notifications received by the watcher |
| `exception-*.dmp` and `.dmp.json` | Dump plus its individual success/failure receipt |
| `dump-attempts.jsonl` / dump status | Outcomes of successive capture attempts |
| `process-exit.json` | Exit code and notification observations |
| `live-recovery-N.json` | Last complete durable pending session and its completed base |
| `live-recovery-N.json.status.json` | Slot state, such as active, committed or cancelled, with its epoch |

UI/timer heartbeat records include free MAXScript heap bytes and process
working-set/private/peak working-set bytes. These are different measurements.
Process private allocation is not total free physical RAM; free script heap is
not a complete measure of native allocation headroom.

The recorder captures callbacks delivered to this brush, not unrelated desktop
clicks. Contexts can contain scene geometry, and dumps can contain process
memory. Nothing is uploaded automatically; choose the intended recording when
sharing diagnostic data.

## Retention and durability

Events retain four 8 MiB segments. Contexts retain eight slots, each limited to
32 MiB. The watcher retains two dumps: the first fault and the newest later fault.
Old recording directories remain available. A later failed dump attempt must
not be interpreted as proof that an earlier successful dump is missing; inspect
the per-dump receipt and the attempt history.

Recovery records are replaced atomically through a temporary file, flush and
replace operation at gesture/control boundaries and approximately once per
second while the world changes. Up to eight sessions own recovery slots, each
limited to 32 MiB. Slot status matters: the newest file by time is not
automatically the session the user intends to recover.

The watcher runs separately and does not replace Max's crash handler. Existing
flushed records can survive a host crash, but immediate termination, power loss,
disk failure or certain fatal conditions can prevent a final dump or final
write. Recovery may omit the last unflushed input or simulation steps.

Native `cplDiagnosticInfo()` exposes `recording`, `watcher_ready` and `error` for
engineering inspection. Those fields should confirm a functioning recorder;
the mere existence of a directory does not prove successful capture.

## Recover a session

1. Preserve a copy of the complete diagnostic folder and the relevant MAX scene.
2. Open the saved MAX scene using its original source/receiver/collider bindings.
   Use the matching 0.1.4 package when intending to Resume.
3. Select the lab object. If it already has pending work, deliberately Finish,
   Freeze or Cancel that work before loading another recovery. Loading recovery
   is not a merge of two live sessions.
4. Under **Result and files > Recover session...**, select the appropriate
   `live-recovery-N.json`. Use its context, owner/epoch and companion status to
   identify the correct session.
5. Review the cached preview. **Resume** reconstructs the recorded world only
   when the solver fingerprint and recaptured inputs match. **Freeze** accepts
   the cached poses without requiring simulation replay.
6. Check the result and save a new MAX scene. Keep the original recovery intact
   until the restored work has been reviewed.

The loaded recovery includes a completed base, and importing that base is a Max
Undo operation. Original materials and scene bindings still come from the MAX
scene. A solver mismatch preserves the cached preview but prevents Resume;
editing the fingerprint to bypass this check is not a supported recovery path.

Result **Load...** is for completed-result JSON. Use **Recover session...** for
live-recovery JSON. Their contents and validation contracts differ.

## What was established about the earlier crashes

The controlled 0.1.2 reproduction delivered successive Painter callbacks after
a settling rejection had cancelled state. Source then dereferenced the cleared
`staged` pointer before checking it. The observed failure was a native
`0xC0000005` read at address `0x100`. The runtime message was a lifecycle guard;
raising the MAXScript heap would not repair that demonstrated path.

That reproduction is not the original artist application's crash stack. It
supports a specific corrected defect, not a claim that all crashes had one
cause. [0.1.3 diagnostics report](CRASH_DIAGNOSTICS_013.md).

The subsequently supplied `20261017-133334-933-pid26456` recording contained
three accepted strokes, 18 settling rejections and one commit in its primary
snapshot. No fatal exception or out-of-memory error was recorded there. Some
bodies were outside the finite receiver and still falling, which could prevent
the old whole-batch settle check from finishing. The snapshots did not prove
the exact edge/contact trajectory of each body.
[Artist recording analysis](ARTIST_LOG_013_20261017.md).

0.1.4 addresses the waiting policy through one world across gestures, separate
Finish/Freeze commands and bounded lost-body removal. It retains diagnostics and
closed-callback protection. This is a causal explanation supported by inspected
code and tests, not a crash-free certification.

## Current crash-test evidence

The final ordinary pair was tested with an injected native access violation and
with abrupt process termination in owned Max 2027 profiles. Max translated the
injected exception to a script exception before the owned host exited. The
first dump was valid and had a successful receipt; a later dump attempt failed
without deleting that first dump. The abrupt termination produced exit code 77
without an exception notification, while its complete flushed recovery survived.

Both recordings restored their three-body, three-stroke sessions, supported
same-solver replay and live Undo/Redo, and could Freeze. A deliberate solver
mismatch retained the preview and refused replay. See the
[validation report](VALIDATION_REPORT_014.md#diagnostics-and-recovery-tests) for
artifact paths and the exact limits of these tests.

## A useful failure report

Copy this template and attach only the scene/recording you intend to share:

```text
Physics Lab version and installer filename:
3ds Max version/build:
Diagnostic timestamp/PID folder:
Approximate event time within the recording:

Receiver, source and collider description:
Scene system units and approximate source dimensions:
Body limit; completed / pending / moving / fallen counts:
Brush radius, spacing, height, scale and proxy mode:

Exact sequence (Start, drag, release, Pause, Resume, Undo, etc.):
Expected result:
Observed result and exact status/error text:
Did Max remain responsive, raise an error or exit?
Did this reproduce in a copy of the scene?
Relevant MAX scene and external assets available:
```

For engineering analysis, correlate owner, session epoch, command sequence and
simulation step before comparing events. Check the last complete recovery and
its status, distinguish birth intent from applied births, and inspect the first
fault receipt rather than assuming the last status is the original failure.
