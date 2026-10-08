# Tools, reproduction and continuation

## Which shared GitHub tools help

| Tool | Suitability for this installed Forest module |
|---|---|
| [Ghidra MCP](https://github.com/bethington/ghidra-mcp) | Used successfully with the existing portable Ghidra 12.1.4, Java 21 and GhidraMCP 6.0.0. Import, analysis, scripts, references, disassembly and decompilation work. No new installation needed. The live schema advertises 215 endpoints; that is a tool catalog, not analysis coverage. |
| [IDA MCP](https://github.com/HexRaysSA/ida-mcp) | Alternative native analysis integration. It is not required to continue this working Ghidra investigation; IDA/decompiler availability was not verified or installed. |
| [ILSpy](https://github.com/icsharpcode/ILSpy) | A .NET decompiler. The core Forest module has no CLR directory, so this is not the tool for its native engine. |
| [Cpp2IL](https://github.com/SamboyCoding/Cpp2IL) | Targets Unity IL2CPP. This Max native plugin is not a Unity IL2CPP target. |
| Universal Modder, REA and AI game-modding guides | Previously recovered links are research aids, not prerequisites. They were not installed or used for this pass. Two original shortened-link matches remain inferred. |
| AnyPS5 / PortPS5 | Previously supplied console-oriented tools were not used; no demonstrated need in this Windows Max plugin investigation. |

Original recovered-link receipt: `C:\Users\Mehran\Documents\ChatGPT\Play\tyflow-analysis\FULL-HANDOFF-REPORT.txt`, section 2. Existing `tools.json` there supplies runtime paths only. Its launch scripts/projects were preserved; this run used a fresh project, fresh user home and localhost port 18091 inside this repository.

## Reproduce the bounded workflow

The neutral helpers under [reproduce](reproduce/) contain no vendor pseudocode or assembly. They require the existing local Python/requests, tool paths, MSVC and Max SDK. Run from the repository root with a **fresh** build directory. Do not run the finalize helper against an existing receipt; it deliberately refuses replacement.

1. `capture.py --run build/<fresh-run>` captures installed identities/copies and inventories PE metadata.
2. `collect_docs.py --run build/<fresh-run>` retrieves public primary documentation. Failed URLs and HTTP status are retained. The actual run kept an initial wrong `items-editor` URL and its successful `item-editor` correction. Full pages stay private.
3. `backend.py start --run build/<fresh-run>` starts an owned, hidden, loopback backend. Use its live schema before issuing project/import/analysis requests. Import only copied files; do not execute the target binary.
4. `find_anchors.py` and `export_selected.py` trace selected strings, RTTI/vtables and bounded functions. Inspect each helper's CLI arguments. Selection addresses apply only to the pinned image; labels must be reviewed after inspection.
5. `sdk_witness.py` independently compiles SDK class layouts without linking/executing. Preserve failed receipts as well as corrected passes.
6. Save all programs, close the project, verify backend executable/argument-file/listener ownership and stop only its owned PID. Preserve the Ghidra database.
7. `finalize.py --run build/<fresh-run>` checks original/copy/source hashes and exports metadata to this report's receipt. For a new dated investigation, copy the neutral helpers into its own report directory first.

Actual private run: `build/forestpack-research-20261008-01`. It contains 19 successful official-page retrievals plus one failed URL attempt, four native inventories, a saved Ghidra project and four selected-analysis batches. Thirty-two records decompiled with complete decoded coverage of their analysis-defined bodies; one selected cache comparator was not discovered. Four corrected SDK probes passed. Eight installed input originals/copies and eight inspected repository source hashes remained unchanged. Backend PID 26972 was saved/closed/stopped with ownership checks. See [EVIDENCE.json](EVIDENCE.json).

## Remaining questions and next acceptance criteria

- Reconstruct collision sort priority and test the grid's assumptions for extreme mixed radii. Do not assume placement ordering is random or grid behavior universal.
- Locate/analyze cache comparator `0x7a650`, establishing true function bounds before decompilation; then trace priority fields and refcounts. Do not label eviction LRU yet.
- Trace callers that clear the marker ready flag and the revision-comparison fields. Static retained drawing does not prove zero re-upload for every UI or animation event.
- Identify receiver-preparation structures beyond R-tree names. Profile Cyrus before proposing shared acceleration.
- Use a disposable Max profile/scene for behavioral experiments: deterministic seeds, masks, jitter/boundary order, collision rejection, custom edits, source animation, mode transitions and selection. Record actual loaded identities before comparing results.
- Renderer integration, Pro-exclusive paths, effects compiler/evaluation details and Chaos Scatter native analysis remain separate investigations. This pass supplies no comparative FPS or renderer-memory conclusion.

No commit, push, installation, packaging, scene mutation or deployment was performed.
