# Reproduce the deeper native research

Run from `F:\Cursor\_Cyrus_Apps\CyrusScatter`. Use a **new** ignored `build/` run. Keep vendor binaries unchanged and analyze copies. Raw disassembly/decompiler listings remain local; only neutral scripts, addresses, paraphrased findings and receipts are documented.

## Prerequisites and capture

This workflow reuses the verified tools in `C:\Users\Mehran\Documents\ChatGPT\Play\tyflow-analysis\tools.json`: portable Ghidra 12.1.4, Ghidra MCP 6.0.0, Java 21. The Max probe requires installed Max 2027, the pinned prior owned scene, the prior 0.74 package/private-profile template, and the exact installed modules in [the receipt](../EVIDENCE.json). The vendor transport does not load Cyrus orchestration. No plugin installer is run.

```powershell
python docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/lab.py capture --run build/vendor-native-deep-NEW
python docs/ForestPack_Research_2026-10-08/reproduce/backend.py start --run build/vendor-native-deep-NEW
python docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/prepare_projects.py --run build/vendor-native-deep-NEW
```

The backend creates a fresh `userhome` and empty `projects` directory, binds localhost port 18091, and allows scripts only for this owned run. Ensure the port is free first; do not stop an unrelated listener. `prepare_projects.py` copies the closed prior analysis projects and refuses mismatched installed binary hashes. It does not overwrite the prior projects. If an old project is missing or a plugin version changed, import the captured binary in a new project and analyze it; do not reuse recorded RVAs blindly.

## Targeted native exports

Open one project/program at a time:

```powershell
python docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/probe.py --run build/vendor-native-deep-NEW --project ChaosOwnership
```

Other project choices are `ReceivingSurfaceCore` and `ForestPack943`. Before switching, save the current program and close the project:

```powershell
python docs/ForestPack_Research_2026-10-08/reproduce/backend.py request --run build/vendor-native-deep-NEW --endpoint /save_program --output build/vendor-native-deep-NEW/save-program.json
python docs/ForestPack_Research_2026-10-08/reproduce/backend.py request --run build/vendor-native-deep-NEW --method POST --endpoint /close_project --output build/vendor-native-deep-NEW/close-project.json
```

Select questions from [CODE_MAP.md](../CODE_MAP.md). Add `0x180000000` to an RVA to make its analysis VA. A selection JSON is an array of objects, for example:

```json
[
  {"label":"stroke_spatial_query","address":"180014a20"},
  {"label":"stroke_tube_contains","address":"180033130"}
]
```

For that selection load `ReceivingSurfaceCore`, then run:

```powershell
python docs/ForestPack_Research_2026-10-08/reproduce/export_selected.py --run build/vendor-native-deep-NEW --selection build/vendor-native-deep-NEW/selection.json --output build/vendor-native-deep-NEW/core-selected
```

This helper limits batches to 30 selected functions, body size to 64 KiB and decompile time to 30 seconds each. It records requested/actual entry, body bytes, instruction count, decoded byte total and completion. Require decoded bytes to match the selected analysis-defined body; this is not proof of original function boundaries or correct inferred types.

`probe.py --anchors ... --output ... --depth 0` finds references to selected addresses. Depth 1–4 follows data references where no containing function exists, capped at 512 emitted references per anchor and 40 anchors. It is not an unbounded call-graph scraper. `vtables.py` only samples candidate pointers; executable targets and independently validated RTTI layout are required before calling an address a vtable. The initial hierarchy-descriptor guesses in the recorded run failed that requirement and are excluded.

The Forest comparator is initially decoded as a label without a function. With `ForestPack943` loaded, define only this bounded straight-line leaf and trace its timestamp writes:

```powershell
python docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/leaf.py --run build/vendor-native-deep-NEW --address 18007a650
python docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/field_refs.py --run build/vendor-native-deep-NEW --offset f48f0
```

The leaf helper refuses calls/jumps, more than 16 instructions, or a return beyond 32 bytes. The recovered leaf is 28 bytes. `field_refs.py` searches decoded instruction operands for one selected displacement, caps results at 128, and does not imply complete references through pointer arithmetic. Export the comparator and its discovered writers (`0x79520`, `0x79b80`), plus eviction (`0x7a670`). Check `_time64` writes and ordering before interpreting this as source-sample recency.

## Independent Max SDK witness

```powershell
python docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/sdk_witness.py --output build/vendor-native-deep-NEW/sdk-qualified
```

This compiles our own short source with MSVC 14.38.33130 and the installed Max 2027 SDK. Nothing is linked, installed or executed. Static assertions verify the four table-type values. Separate compiler invocations report `Mesh`, `TriObject` and `BlockWrite_Value` layouts. Confirm `0xf8 + 0x168 + 8 = 0x268` for the TriObject face count. Looking only at `Mesh.numFaces` would misidentify the adapter's offset.

## Read-only saved-paint probe

```powershell
python docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/lab.py launch --run build/vendor-native-deep-NEW
```

Wait for `host/ready.txt`; check the owned PID/profile in `launch.json`, host version, loaded module paths and captured hashes. The script intentionally loads only `build/vendor-surface-paint-20261009-01/host/vendor-fixture.max`, the prior owned scene. It never saves that scene. Do not change it to an artist path.

```powershell
python docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/lab.py request --run build/vendor-native-deep-NEW --script docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/read_saved_paint.ms
python docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/analyze_saved_paint.py --run build/vendor-native-deep-NEW
```

Require SUCCESS for the exact request, then verify **5 points / 3 records**, point counts **1+2+2**, valid receiver/face references and two unique barycentric anchors. The script's line saying `layers 3` records `layerList.count`; do not treat that label as proof of a complete layer schema. The Python analysis uses the sampled flat triangles and generic barycentric arithmetic. It does not emulate the vendor scatter engine.

`PENDING` after 50 seconds is not cancellation. Inspect the exact `response.txt` and `stage.txt` before issuing another request. On a stall, retain diagnostics and report it; never queue dependent mutations behind an unresolved request.

## Close, preserve, publish receipts

Save/close every copied analysis project. Stop only PIDs whose current executable and full owned-run command arguments match `server-start.json` or `host/launch.json`; for Java also verify the listener's owner. Never kill by application name. Record `host/cleanup.json` and `analysis-cleanup.json` with `stopped: true`, the matched PID and command. The captured original scene must still match its earlier hash.

The report finalizer verifies installed hashes, exported body ledgers, SDK receipts, old scene preservation, report links and Python parsing. It records concurrent product source changes rather than overwriting them:

```powershell
python docs/Vendor_Native_Deep_Research_2026-10-09/reproduce/finalize.py --run build/vendor-native-deep-20261009-01
```

That last command regenerates this report's evidence for the recorded run. For an independent future run, publish its receipts in a separate dated research folder; do not replace this historical result. No product build/tests are warranted by documentation-only research. Viewport FPS, buffer uploads and placement-cache reuse require separate instrumented qualification.
