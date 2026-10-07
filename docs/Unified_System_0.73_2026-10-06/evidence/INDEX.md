# Evidence index

All final campaigns below use the [recorded final script/native pair](../RESULTS.md). Curated receipts are copied here; full logs, disposable scenes, SDKs/binaries and failed-run details remain in ignored local folders. [index.json](index.json) records each copied file's source path, bytes and SHA-256. No connection descriptor, authentication secret, operation journal or vendor pseudocode is copied.

| Evidence | Entry | Meaning |
| --- | --- | --- |
| Scatter SDK 2027 | [receipt](native-max2027/receipt.json), [tests](native-max2027/tests.log) | Build input/output identities and 14 passing suites. |
| Scatter SDK 2026 | [receipt](native-max2026/receipt.json), [tests](native-max2026/tests.log) | 14 passing suites; no runtime claim. |
| Analyzer SDK | [2027](analyzer-max2027/receipt.json), [2026](analyzer-max2026/receipt.json) | Matching dependency, one passing native suite each. |
| Offline/generated | [Python JUnit](python-tests.xml), [generated check](generated-check.json) | 141 passes; reproducibility, 240 controls, 245 port dispositions and fourteen fixtures. |
| Final core | [qualification](core/qualification.json), [pipeline](core/core073.json), [containers](core/containers073.json), [ports](core/ports073.json), [groups](core/groups073.json), [persistence](core/persistence073.json) | Five passing probes, same final guarded pair. |
| Current UI/idle | [qualification](ui/qualification.json), [UI](ui/ui073-acceptance.json), [idle](ui/idle-qualification.json), [mock Corona](ui/corona-stop-073.json) | Native bindings, eight settled cases and eight mocked IR lifecycle cases. |
| Natural selection | [qualification](selection/qualification.json), [acceptance](selection/container-selection073.json), [cold warmup](selection/selection-reopen-warmup.json), [settled counters](selection/selection-counter-comparison.json) | Twelve checks, zero router errors, natural positive mounting, shared/global/unlinked/closed/expansion and reopen. Cold preview creation is separate from passive UI reuse. |
| Playback | [qualification](playback/qualification.json), [result](playback/result.txt) | 942 assertions across actual dependencies/lifecycle. |
| Analyzer/parity | [qualification](analyzer-assignment/qualification.json), [assignment](analyzer-assignment/analyzer-assignment073.json), [baseline](baseline-comparison.json) | Positive inside/edge choices, missing child choice, growth/reopen and preserved 0.72 position/source-index fingerprints. |
| Navigation | [qualification](navigation/qualification.json), [raw data](navigation/unified073-final-100k-navigation.json) | 100k cache/upload invariants; synchronous timing, not presented FPS. |
| MCP direct | [qualification](mcp-direct/qualification.json), [result](mcp-direct/mcp073.json) | Four-mode approved authoring, passive publication and rollback. |
| MCP stdio | [qualification](mcp-panel/qualification.json), [result](mcp-panel/panel-runtime-result.json), [reopen](mcp-panel/panel-save-reopen.json) | Actual stdio/IPC/host-thread dispatch, consent/approval, exact cold-root output and lifecycle reset. |
| Source/retirement | [current inventory](current-snapshot.json), [generator retirement](retired-generator-inputs.json), [old builder](retired-document-builder.json) | Current tracked/untracked scope and historical dispositions; hashes are inventories, not behavioral tests. |
| Retired scene denial | [qualification](retirement/qualification.json), [result](retirement/retirement073.json) | Persisted old-schema rejection, including copy and re-save/reopen; ordinary geometry may load and original bytes stay unchanged. |
| Delivery | [packages](packages.json) | Native MZP entry hashes, MCP host/wheel identities and source equality; no artist installation. |
| Offline MCP installation | [bundle smoke](mcp-bundle-smoke.json) | Actual hashed wheel install/stdio advertisement and unpaired-host rejection in a disposable venv. |
| Diagnostic corrections | [attempt audit](attempt-audit.json) | Failed intermediate fixtures remain classified and are not promoted to passes. |
| Final document audit | [validation](validation.json) | Current-link/source/package/protected-scope checks; not UI/renderer evidence. |

## Reproduce without computer-use

Use a fresh ignored output directory for each host run. [unified_073_qualification.py](../../../tools/procedural_lab/unified_073_qualification.py) creates its own hidden private profile, verifies build receipts and stops only its launched PID. It never attaches to the artist process. Dependent definition files load before separate probe blocks compile. `qualification.json` records fixture/code hashes and results; `index.json` maps campaign names to private directories.

```powershell
python tools/procedural_lab/offline_build.py --year 2027 --project scatter --output build/REPRO-073/native-max2027
python tools/procedural_lab/offline_build.py --year 2027 --project analyzer --output build/REPRO-073/analyzer-max2027
# Repeat for --year 2026 for its separate SDK-only artifacts.
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q
python tools/procedural_lab/check_generated.py

python tools/procedural_lab/unified_073_qualification.py --name REPRO-073-core `
  --native build/REPRO-073/native-max2027 `
  --fixture tools/procedural_lab/Max_Procedural_07_Fixture.ms `
  --definitions tools/procedural_lab/Max_Procedural_07_Acceptance.ms `
  --probe 'P07Acceptance()'

python tools/procedural_lab/unified_073_qualification.py --name REPRO-073-nav `
  --native build/REPRO-073/native-max2027 `
  --definitions tools/procedural_lab/Max_Unified_073_Navigation.ms `
  --code 'P07Navigation "REPRO-073" 100000 frames:30 containers:true'
```

Other probe bodies are identified in their receipts and fixtures. UI/idle uses `Max_UI_073_Acceptance.ms`, `Max_Corona_Stop_073.ms` and `--idle`; playback uses the matching Analyzer dependency and current two playback fixtures. MCP launches `unified_073_mcp_host.py`, or the panel host plus external `runtime_panel_073_qualification.py`, after Max releases busy script evaluation. Local fixture authority is not a remotely exposed approval API.

The [package validator](../../../tools/procedural_lab/package_unified_073.py) requires explicit natural-selection/core/UI/playback/navigation/MCP/Analyzer/retirement campaign paths. [Collector](../../../tools/procedural_lab/collect_unified_073_evidence.py) copies only its allowlisted reports and independently verifies package/source equality. Run from the repository root with the pinned tooling; fresh paths avoid mixing generations. Neither tool installs, commits or pushes. The [original error reproduction and previous UI receipts](../../Container_Selection_Fix_0.73_2026-10-06/README.md) explain why passing forced-mount assertions were insufficient.
