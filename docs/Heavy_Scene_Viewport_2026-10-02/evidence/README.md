# Evidence inventory

Read [RESULTS.md](../RESULTS.md) for interpretation. This archive preserves the accepted experiment and the failed attempts needed to understand its limits. It contains no executable binaries or artist scenes.

| Files | Meaning |
| --- | --- |
| `points*-fixture.json` | Exact point/row/source counts and preparation timings for each case |
| `points*-frames.csv` | Raw synchronous camera-step and callback timings |
| `points*-cases.json` | Repeat/arm boundaries, QPC timestamps, before/after native counters |
| `points*.png`, `pilot-*.png` | Viewport appearance captures; PNGs named pilot remain useful visual checks, not acceptance of the rejected pilot timings |
| `summary.json` | Per-arm and per-repeat median/p95/p99, validation counters; derived by `analyze.py` |
| `presentmon-official.csv`, `presentmon-summary.json` | Independent presentation trace and QPC-aligned analysis |
| `presentmon-tool.json` | Official tool origin, digest and valid Intel signature |
| `lifecycle*.json`, `gesture.json`, `cleanup.json` | Ownership, multiple views, real mouse pan and scene-reset checks |
| `cleanup-raw-maxscript.txt`, `normalization.json` | Original successful reset record and explicit numeric-suffix normalization |
| `shutdown-*.json` | Timer disposal request plus independent observation of private-process exit |
| `ready.json`, `launch.json`, `machine.json` | Loaded modules, private invocation, host/viewport and hardware identities |
| `input-identity.json`, `preservation.json` | Pre-launch identities and matching final hashes |
| `binary-identities.json`, `build-2026/`, `build-2027/` | SDK build evidence and both probe module hashes; binaries stay in the private build directory |
| `recipes/` | Exact submitted scripts, including rejected/debugging requests; filenames are not pass indicators |
| `probe-source/`, `probe-source-identities.json` | Source snapshot at archiving; serializer-only cleanup/shutdown edits after execution are documented in the results |
| `research-input-identities.json` | Fingerprints and original paths for all supplied reports and ledgers |
| `manifest.json` | SHA-256 and byte counts for archive files except the manifest itself |

## Rejected data

`rejected/pilot25k-*` uses ordinary `redrawViews`; the retained draw counter did not advance for every requested step. Do not include these timings in speed claims. `redraw-check.json` and accepted trial counters establish why the protocol changed to `completeRedraw`.

Early launch, registration and MAXScript export failures are preserved under `rejected/`. The first lifecycle record has non-JSON Integer64 suffixes; its twelve cycles were subsequently rerun with a corrected serializer. The successful reset was not rerun: its raw numeric tokens were explicitly normalized for JSON, with the unmodified original preserved.

The final `ready.json`, accepted case files and process-specific loaded module identities govern the run. A stale startup-error file from a repaired attempt does not override those later observations. The results document describes the two older PresentMon attempts that produced no capture; no data from them is accepted.

## Recompute and verify

Run from the repository root:

```powershell
python tools/performance/native_point_probe/analyze.py docs/Heavy_Scene_Viewport_2026-10-02/evidence
python tools/performance/native_point_probe/analyze_presentmon.py docs/Heavy_Scene_Viewport_2026-10-02/evidence
python tools/performance/native_point_probe/verify_evidence.py
```

The analyzers deterministically regenerate their two summaries from raw records. On the archived data they retain the same bytes and hashes. A changed analyzer that changes output must produce a separately identified result rather than silently replace this evidence.

Probe counter indices are described in the [runbook](../../../tools/performance/native_point_probe/README.md). Explicit realization calls are not driver upload traffic; draw calls are not completed screen frames. The private helper has no production picking, persistence or fallback implementation.
