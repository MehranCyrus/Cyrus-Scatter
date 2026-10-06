# Method, identities and evidence limits

6 October 2026.

## Evidence vocabulary

**Source fact** means a current Cyrus file was inspected. **Static reproduction** means bytes, disassembly, RTTI or compiler diagnostics were independently checked during this investigation. **Documented contract** means an official source states the behavior. **Inference** means those facts suggest an explanation but do not prove the implementation or runtime outcome. **Unverified** means the required observation was not made.

Ghidra pseudocode is an aid to understanding machine code. Analyst labels are not recovered original C++ names. A method with a decompiled listing is not automatically fully understood, and a passing export request is not a passing plugin test.

## Exact target and Cyrus snapshot

| Item | Verified identity |
| --- | --- |
| Installed target, read only | `C:\Program Files\Autodesk\3ds Max 2027\Plugins\tyFlow_2027.dlo` |
| Private working copy | `C:\Users\Mehran\Documents\ChatGPT\Play\tyflow-analysis\inputs\tyFlow_2027.dlo` |
| Target SHA-256, both files | `5b1068b5b3627f64f78cd2b51ca0c23d616be09943077d5ffcf1c6fecc713fd9` |
| Size / file version | 650,320,384 bytes / `2.1000.0.0` |
| Binary technology | Native PE32+ x64; no CLR header; image base `0x180000000` |
| Cyrus branch / HEAD | `codex/floating-layer-editor-0.7.1` / `147e3f524aa3f4cd9db9bb2bffb7350f9f78de31` |
| Current generated Scatter SHA-256 | `d1f264b7702d4ccc75eb782d60134b46ddcf04bf7f550f8a702c8a34fe65c772` |
| Script payload SHA-256, preserved qualification receipt | `605f6b743df1f048ae4b7b0be67a496779956c26b68462ffd822c850ec8f7263` |
| Product / serialization | 0.7.1 / 53 |

The working tree has 15 modified tracked files and additional untracked playback source, tests and reports. HEAD alone cannot identify this candidate. The [other assessment's initial inventory](../TyFlow_CyrusScatter_Assessment_2026-10-06/evidence/source-state-before.json) predates our changes and fingerprints 532 source/configuration files, including licensing source. Our final comparison against that inventory is explicitly attributed to that earlier capture; it is not falsely presented as our own initial snapshot. Our changes are this research folder and one additive documentation-index paragraph.

Artist `.max` files and Max profiles were not opened or edited. We did not install anything into Max, run the target plugin, or change its binary. Matching installed/current Scatter versions remain a delivery concern, separate from research.

## Which GitHub tools helped

| Tool | Decision for this target | Primary source |
| --- | --- | --- |
| Ghidra + ghidra-mcp | Used the existing Ghidra 12.1.4, JDK 21.0.12.1 and ghidra-mcp 6.0.0 installation. The saved database, bounded scripts and REST exports gave useful native disassembly/decompilation. | [Repository](https://github.com/bethington/ghidra-mcp), [6.0.0 release](https://github.com/bethington/ghidra-mcp/releases/tag/v6.0.0) |
| ILSpy | No benefit for the primary `.dlo`: its inspected format is native, without a CLR header. Useful if a separate managed assembly is later identified. | [ILSpy](https://github.com/icsharpcode/ILSpy) |
| IDA MCP | Alternative native analysis environment; no installation was needed for the questions answered here. Its backend requires a suitable IDA/idalib setup. | [IDA MCP](https://github.com/HexRaysSA/ida-mcp) |
| REA | Investigation workflow rather than a superior native decompiler. Its documented Windows Ghidra limitation makes it unnecessary for this existing Windows project. | [REA](https://github.com/morluto/rea) |
| Cpp2IL | Not applicable to the inspected native Max plugin; intended for Unity IL2CPP reconstruction. | [Cpp2IL](https://github.com/SamboyCoding/Cpp2IL) |

The previous nine-project handoff remains at `C:\Users\Mehran\Documents\ChatGPT\Play\tyflow-analysis\FULL-HANDOFF-REPORT.txt`. Its other workflow/console-port projects were not used as evidence of tyFlow internals. No new tool installation was necessary.

## How the investigation worked

1. Rechecked the installed binary and working-copy hash, inspected the prior handoff and raw evidence, and copied the existing `.gpr`/`.rep` project to private `project-before/` before new analysis annotations.
2. Started an owned hidden Java analysis process, PID 27608, with an 8 GiB heap. Verified its listener was `127.0.0.1:18089`. Loaded the existing project/program; no vendor code executed.
3. Used [static_pe.py](reproduce/static_pe.py) to inspect PE imports, exception/unwind regions, selected MSVC RTTI and candidate vtables. The final scan is private `anchors-v3/static-anchors.json`: 4,620 imports, 1,789 selected raw instruction-pattern candidates, two selected constructor-reference candidates and 15 selected RTTI names.
4. Confirmed selected candidates in disassembly. Used RTTI inheritance and an SDK-only MSVC layout witness to identify actual host virtual methods, rather than assigning meaning to a guessed offset.
5. Exported bounded regions with [ghidra_batch.py](reproduce/ghidra_batch.py). Each selection, instruction listing, cross-reference list, pseudocode result and file hash is preserved privately. Limit: 64 KiB selected span and 30-second decompilation timeout per function.
6. Followed specific UI, parameter, validity and display paths into their helpers, then compared them with the current Cyrus source and preserved receipts.
7. Saved/closed the project, stopped only the verified owned process, rehashed the target and checked repository/evidence integrity. The [final receipt](evidence/verification.json) records the result.

The program-info endpoint reports 222,704 functions. This includes loader/analysis placeholders and is not 222,704 analyzed or understood functions. CUDA/NVIDIA sections occupy much of the file, but section size does not show which algorithm is active in a given scene.

## SDK ABI witness and important corrections

`sdk-layout-v4/` contains six separate successful `/c` compilations with MSVC 14.38.33130 and local Max 2027 headers. They only report class layout/vtables: no linking and no plugin execution. PBAccessor, IParamBlock2, GeomObject, Interface, Interface15 and IObjectDisplay2 were covered. [sdk_layout.py](reproduce/sdk_layout.py) recreates this witness.

| Confirmed local slot | Meaning used in the analysis |
| --- | --- |
| PBAccessor 3 / 8 | `Set` / `TabChanged` |
| GeomObject 161 / 172 / 180 / 236 / 272 / 308 | `NotifyRefChanged` / `PrepareDisplay` / `Display` / `Eval` / `ObjectValidity` / `GetRenderMesh` |
| Interface 29 / 32 / 181 / 463 | `RedrawViews` / `ForceCompleteRedraw` / `GetTime` / `IsNetworkRenderServer` |
| Interface15 860 | `GetMainThreadID` |
| IObjectDisplay2 10 / 11 / 12 / 13 | `GetObjectDisplayRequirement` / `PrepareDisplay` / `UpdatePerNodeItems` / `UpdatePerViewItems` |

These are version-specific ABI observations, not portable slot-number APIs. Crucially, Interface slot 463 is **IsNetworkRenderServer**, not IsRendering. A main-thread-ID comparison is present in GetRenderMesh but does not establish that every later operation is protected against cross-thread entry. These distinctions affect the evaluation/thread-safety conclusions.

RTTI identifies TFlow's SimpleObject2/GeomObject ancestry and an IObjectDisplay2 subobject at offset `0x3f0`. Its selected thunks subtract that offset and jump to the methods discussed below. Qt wrapper ancestry includes `MaxSDK::QMaxParamBlockWidget`. [Autodesk's plugin entry-point contract](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/group___required_plugin_dll_function.html) describes registration; a registration branch's class count is not an operator count.

## Authoritative export batches

Paths below are relative to private `research-20261006/`. [research-receipt.json](evidence/research-receipt.json) records counts, ranges and file-hash verification.

| Use this batch | What it establishes | Limit / superseded output |
| --- | --- | --- |
| `batch01/` | Selected Qt signal handlers, combo overrides, rollout creation/order/transfer and PBAccessor/UI wrappers | Some entry fragments are superseded by complete chained exports below. |
| `batch02/` | TFlow host methods, cache-reset gate, popup initialization/filtering, widget helpers | Initial Display/PB handler prologues alone were incomplete. |
| `batch03-v2/` | Chained Display/PB/signal functions; evaluation gate, invalidate/notify and time conversion | Repairs the incomplete `batch03/` exports. |
| `batch04/` | PB/widget metadata synchronization, time-dependence helper and large simulation dispatch assembly | Dispatch at RVA `0x03f80b70` covers 26,281 bytes / 5,030 instructions; decompilation timed out. No complete C-level scheduler claim follows. |
| `batch05-v2/` | Four IObjectDisplay2 thunks/bodies and the complete 17-byte interval-contains helper | Initial `batch05/` selected no regions because the leaf thunks have no ordinary unwind record. |
| `batch06/` | Display context preparation and submission, including custom render items and instancing | Invalidation's initial 30-byte root omitted chained fragments. |
| `batch06-v2/` | Full selected invalidation family: 152 bytes / 38 instructions | Replaces the incomplete invalidation root. |

Some listings include decompiler warnings, inferred types and tail-call expansion. The filtering function has one uncovered padding byte in its selected range. An export can therefore succeed without all selected bytes belonging to instructions. We retained failed/intermediate artifacts instead of discarding this evidence.

The seven authoritative batch folders contain 66 selected-region receipts, with 65 completed decompilations and the one explicitly recorded dispatch timeout. Counts include repeated/corrected fragments and leaf thunks; they are not 66 unique original source functions. All listed batch artifact hashes matched. Six SDK-only compilations passed, four research Python scripts passed syntax checks, and 75 local document links/line targets were checked. All 532 source/configuration fingerprints matched the attributed earlier inventory; HEAD, branch and staged state also matched. These are research-integrity checks, not runtime/performance tests.

An early analyst label `Global_Mesh_Cache_Clear` at RVA `0x03fa4fa0` is misleading: the examined helper collects entries. Its body alone does not prove a cache-clear operation. Wrapper slot 52 populates/setup controls; we do not identify it as UpdateParameterUI merely from that slot. No timer-start/import count is evidence of permanent idle polling.

## What remains unknown

The complete simulation scheduler, worker-pool implementation, spatial collision structures, operator-specific algorithms, GPU kernels, all render-item realization/upload policies, renderer/export ownership and global lock discipline were not recovered. Original source, exact typedefs, inlined abstractions and complete call graphs are unavailable. One large dispatch listing timed out; finding the right smaller helpers is preferable to claiming full recovery.

No matched tyFlow/Scatter scene was benchmarked. This investigation cannot establish which product is faster, explain a percentage FPS difference, prove no host CPU activity, or qualify Corona. Public documentation is current at access time but is not necessarily an exact specification of the installed file version. Older performance FAQ GPU descriptions must not override newer solver documentation or binary evidence.
