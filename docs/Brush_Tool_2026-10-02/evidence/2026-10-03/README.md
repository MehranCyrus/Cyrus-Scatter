# Brush prototype evidence — 3 October 2026

Read [the implementation report](../../IMPLEMENTATION_2026-10-03.md) for limits and interpretation.

- `acceptance-g-*`: real plane/sphere gestures, picking grid, behavior/Manual-mode checks, clone and target lifecycle. This binary predates the final right-click callback.
- `acceptance-i-*`: final binary identity, actual loaded modules, fresh-process load of g's saved document, real right-click cancellation of programmatically prepared pending input, repeated lifecycle checks and final saved demonstration signatures.
- `max2026-native-tests.txt`, `max2027-native-tests.txt`: all 11 native suites passed. Later host-only right-click edits were compiled for both SDKs; no core code changed afterward. No Max 2026 application session was available.
- `history.csv`: CPU Release single-run cost probe, four-vertex plane, 10,000 queries and single-dab histories. Field values matched 65 exhaustive-replay query checks per case. This measures neither input-to-visible latency nor peak memory/Undo costs.
- `manifest.json`: base commit, source hashes at collection and explicit distinction between the two host candidates.

Development machine: AMD Ryzen 5 5600X (6 cores / 12 logical processors), NVIDIA RTX 3090, display driver `32.0.16.1047`; Max 2027.1 (`maxVersion` is recorded in each ready file). The history probe is synchronous CPU code with no GPU work. Max sessions were open during it, so times are a smoke baseline rather than a controlled comparison.

The full scenes, copied DLLs, screenshots and transport traces remain in ignored `build/brush-lab-2026-10-03/`. Earlier exploratory runs include deliberately failing fixtures; they are not release artifacts. Reproduce using [the lab instructions](../../../../tools/brush_lab/README.md).
