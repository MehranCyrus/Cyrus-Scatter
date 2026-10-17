# Native placement qualification tools

Private Max 2027 drivers and read-only evidence summarizers. These files are
outside the installer payload. Read the [active implementation ledger](../../docs/plans/native-placement/IMPLEMENTATION.md)
and [current scope/evidence](../../docs/plans/native-placement/EXECUTION_0860.md).
The product pipeline has not been switched by this internal N02 checkpoint.

Use fresh owned host/output names. The existing `tools/memory_0854/host.py`
isolator requires a matching Max 2027 SDK receipt and verifies source hashes
before launch; copied module paths are checked inside Max. Never attach these
reset/GC fixtures to the artist session or install into their profile.

```powershell
py -3.11 -B tools/memory_0854/host.py launch foundation-memory0854-nativeobserve-UNIQUE --native build/QUALIFIED-SDK-BUILD
py -3.11 -B tools/native_placement/run_baseline.py foundation-memory0854-nativeobserve-UNIQUE --repetitions 10 --idle
py -3.11 -B tools/memory_0854/host.py send foundation-memory0854-nativeobserve-UNIQUE --script tools/native_placement/observe_counts.ms
py -3.11 -B tools/native_placement/summarize_baseline.py foundation-memory0854-nativeobserve-UNIQUE --output build/UNIQUE/baseline.json
py -3.11 -B tools/memory_0854/close_owned.py foundation-memory0854-nativeobserve-UNIQUE
```

`baseline.ms` creates owned plane/mountain fixtures and authored Count holds,
records complete ordered row hashes and preserves unrelated Undo. Hashing and
reachability traversal stay outside timed Update windows. Windows process memory
is sampled at a nominal 20 ms interval; sampled private commit is not exact
plugin allocation or GPU memory. Timing summaries exclude warm-up iteration zero
and additional observation iteration eleven. Retain individual samples/outliers.

For N02, use `foundation-memory0854-nativestore-UNIQUE` with `run_store_host.py`.
It checks explicit bounded row capture/page round trips, wrong/stale tokens,
detached values, selection/compaction, GC retention/release and Brush's owning-DLL
POD read lease. `record_store_qualification.py` freezes this dated checkpoint's
explicit receipt paths only; it is not a generic release-certification command.

Observe the current request before sending another. A wait deadline is an
observation timeout, not proof of failure or permission to duplicate a mutation.
Close only after the driver finishes and its final request is terminal. Preserve
failed startup/dump evidence; do not restart or reconfigure the artist host.

`run_binding.py` exercises source correspondence, evaluated receiver revisions,
preparation sealing, native data publication and shared radii in a guarded binding
or controller host. It compares complete legacy/native fields and tests stale
source/terrain/preparation rejection, offset/join/empty provenance and last-pin GC.
`run_controller.py` tests the default-off internal migration route in a controller
host, including the real Count handlers and ordinary Undo/Redo. These drivers
are prototypes, not release certification or an installer. Reuse native modules
with `launch_observed.py --script-only` only when the existing host guard proves
that **only the generated script** differs; record the iteration and freeze a
fresh exact pair before delivery. Never mix changed native inputs with an older
module. Startup exits and live timeouts are separate recorded outcomes.
