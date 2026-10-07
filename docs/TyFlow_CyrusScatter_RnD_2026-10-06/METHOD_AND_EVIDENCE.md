# Method, identities and evidence limits

6 October 2026. Review/R&D only, without computer-use. The starting worktree was clean before this folder was created. Reviewed branch: `codex/integrated-ui-0.72`; HEAD: `01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2`. The focused implementation diff is `75564c4..01a04b2`. Broader findings concern the existing system, not necessarily that diff.

## Inputs and provenance

| Input | Identity / independent check |
| --- | --- |
| Scatter | Development 0.72, package/native 0.72.0, serialization 53. Generated script SHA-256 `77dadf0df9faabbba224de5c0602745c98302b1401e7a21368d5af0ba77f855b`. Canonical generator/templates and generated output were compared. |
| Existing 0.72 source inventory | All 560 entries independently matched at review start. A separate inventory covers 585 tracked files outside `docs/` and the root README. These inventories include some documentation, not just executable source. [Start snapshot](evidence/start-snapshot.json). |
| Earlier qualification | All 52 indexed 0.72 receipts matched their recorded bytes/hashes. Source and binary hashes in four SDK receipts independently matched. [Audit](evidence/prior-receipt-audit.json). This is an integrity audit, not a rerun of Max tests. |
| tyFlow | Installed `C:\Program Files\Autodesk\3ds Max 2027\Plugins\tyFlow_2027.dlo` and private input copy independently matched SHA-256 `5b1068b5b3627f64f78cd2b51ca0c23d616be09943077d5ffcf1c6fecc713fd9`, 650,320,384 bytes, version 2.1000.0.0. Native PE32+ x64, preferred base `0x180000000`, no CLR header. |
| Analysis tooling | Existing Ghidra 12.1.4, Java 21.0.12.1+1 and ghidra-mcp 6.0.0 were reused. Installed REST schema lists 245 tools; the live GitHub README describes a different current surface. Installed identity governs this run. No extra tools were installed. |
| Autodesk ABI | Compile-only MSVC 14.38.33130 / Windows SDK 10.0.19041.0 / local Max 2027 SDK witnesses for `ICustomRenderItem` and `IVirtualDevice`. Both compilations passed; no linking or execution. [Receipt](evidence/display-abi.json). |
| Fresh CPU tests | Exact current pure core rebuilt with `AMIN_BUILD_MAX=OFF`; 14/14 suites pass. New all-pairs and scaling fixtures plus 140 Python tests pass. [Experiments](EXPERIMENTS.md). No Max module was built or loaded in this review. |

The old reports remain useful evidence for their own versions. Their source facts were checked against 0.72 before being carried forward. The earlier popup-owner P1 is fixed and qualified within the subsequent 0.72 API-driven host campaign. It is not a new open defect in this review.

## Evidence vocabulary

| Label | Meaning |
| --- | --- |
| Source fact | Traceable current Cyrus source, with a file and line. It establishes implementation, not every runtime result. |
| Reproduced offline | This review executed a numeric fixture against current source. CPU timing is local evidence; it is not viewport FPS. |
| Audited historical runtime | A preserved matching Max receipt was independently checked. The test was not rerun here. |
| Verified selected binary path | PE/RTTI/unwind/instruction evidence and, where applicable, compiled SDK virtual-slot mapping corroborate a bounded claim. It does not recover original C++. |
| Vendor contract | Official documentation, checked this review. Live documentation is not automatically pinned to the installed binary's precise feature behavior. |
| Hypothesis / proposal | A plausible explanation or candidate improvement requiring its stated experiment. It is not implemented or qualified. |

## Bounded binary work

The existing saved Ghidra project was copied into a new private directory before annotations. A headless backend ran only on `127.0.0.1:18089`. Only the copy was opened, disassembled, annotated and saved. The plugin was never executed by this analysis. The original installed binary and original project were not patched. The saved copy, raw vendor listings and full logs stay outside Git at:

`C:\Users\Mehran\Documents\ChatGPT\Play\tyflow-analysis\research-072-rnd-20261006`

Three batches inspected **26 selected regions**, each at most 64 KiB, using PE unwind bounds or explicit verified leaf bounds. Chained unwind fragments were included where applicable. Their addresses, decoded byte counts, decompiler completion flags, warnings and private artifact hashes are in the [static region ledger](evidence/static-region-ledger.json). RTTI inheritance and render-item vtables are in [selected RTTI](evidence/selected-rtti.json).

**A successful decompiler return is insufficient.** Parallel helpers A/B decode only 2,160/3,559 and 2,699/4,094 selected bytes; their pseudocode contains invalid-flow warnings. Pool slot 2 decodes its selected bytes but follows problematic external control flow. These paths do not establish a complete scheduler or barrier. Settings has an eight-byte decoded gap. Known SDK destructor/material tail jumps also produce jumptable warnings; conclusions use checked instructions/imports rather than assuming reconstructed C is clean.

Names assigned by the analyst are provisional. In particular, `Pool_Dispatch_Parameters` actually guards a main-thread progress/UI path; `Pool_Job_Bank_Access` clamps a worker count. Those corrections are explicit in the ledger and [internals report](TYFLOW_INTERNALS.md). Presence of a type/import/string is only a lead until its active call path is verified.

The copied program/project were saved and closed. Owned backend PID 45836 was stopped only after its command line matched this run's argument file. [Closure receipt](evidence/process-closed.json). It was closed before CPU measurements.

## Tool choice and reproduction

[Ghidra + ghidra-mcp](https://github.com/bethington/ghidra-mcp) fits this native target and was already available. [ILSpy](https://github.com/icsharpcode/ILSpy) targets managed .NET; [Cpp2IL](https://github.com/SamboyCoding/Cpp2IL) targets Unity IL2CPP. Neither matches this binary. [IDA MCP](https://github.com/HexRaysSA/ida-mcp) is an alternative analysis backend, not an additional source of engine truth. Installing more wrappers would not fix uncertain bounds or missing runtime evidence. The previous tool survey remains linked from the [earlier method report](../TyFlow_Architecture_Research_2026-10-06/METHOD_AND_EVIDENCE.md).

Neutral helpers are under `reproduce/`: snapshot comparison, private project-copy launch, SDK ABI witness, selected RTTI, fresh core tests and receipt curation. The prior [bounded Ghidra exporter](../TyFlow_Architecture_Research_2026-10-06/reproduce/ghidra_batch.py) was reused with the private batch selections. Do not load a script against mismatching binaries or launch an artist scene to reproduce a numeric fixture.

The source review is organized by the complete 34-family capability map and targeted paths; it does not claim exhaustive recovery of tyFlow's hundreds of operators or inspection of every line in every historical document. No matched tyFlow/Cyrus runtime benchmark, pointer/DPI test, GPU trace, renderer test or Max 2026 runtime test was run in this review.

## Primary-source reading register

Live sources were checked on 6 October 2026; the installed binary/SDK ABI governs version-specific static conclusions.

| Question | Primary sources / use |
| --- | --- |
| Placement/paint semantics, cache and time | tyFlow [Main Settings](https://docs.tyflow.com/tyflow_objects/tyFlow/mainSettings/), [Cache](https://docs.tyflow.com/tyflow_objects/tyFlow/cache/), [Position Object](https://docs.tyflow.com/tyflow_particles/operators/position_object/), [Birth Paint](https://docs.tyflow.com/tyflow_operators/particles/birth_paint/). Contracts/analogies, not recovered private algorithms. |
| CPU/GPU and measured reset causes | tyFlow [CPU](https://docs.tyflow.com/tyflow_objects/tyFlow/cpu/), [GPU](https://docs.tyflow.com/tyflow_objects/tyFlow/gpu/), [performance FAQ](https://docs.tyflow.com/faq/performance/), [debugging](https://docs.tyflow.com/tyflow_objects/tyFlow/debugging/). Useful controlled experiments; feature-generation differences remain explicit. |
| Plugin extension ownership | [tyParticleObjectExt](https://docs.tyflow.com/tyflow_SDK/tyParticleObjectExt/). Public query/update/release contract, not private engine source. |
| Display and UI ABI/contract | Autodesk [ICustomRenderItem](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_custom_render_item.html), [QMaxParamBlockWidget](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_q_max_param_block_widget.html), Qt [QSignalBlocker](https://doc.qt.io/qt-6/qsignalblocker.html), installed SDK compile witnesses. |
| Host access versus numeric workers | Autodesk [2017 thread-safety guidance](https://help.autodesk.com/cloudhelp/2017/ENU/Max-SDK/files/GUID-610CE507-CD6B-4D82-A248-50BCB7F9CD40.htm). Explicitly older guidance; current Cyrus source/SDK boundaries inspected separately. |
| Dependency caching and profiling | SideFX [Cache If](https://www.sidefx.com/docs/houdini/nodes/sop/cacheif.html), [performance command](https://www.sidefx.com/docs/houdini/commands/performance.html). Transferable measurement/dependency ideas, no Houdini runtime qualification or integration. |
| Export failure contract | Microsoft [StreamWriter.Close](https://learn.microsoft.com/en-us/dotnet/api/system.io.streamwriter.close?view=netframework-4.8.1). Corroborates CR1's failure path. |

The earlier Houdini/Autodesk [vendor recheck](../Current_System_2026-10-05/VENDOR_RECHECK.md) remains its own dated source register. No forum or inferred private source was used as an API contract.
