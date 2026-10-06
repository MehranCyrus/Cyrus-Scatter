# Continuation guide

6 October 2026. The owned analysis server was saved, closed and stopped at the end of this task; see [verification](evidence/verification.json).

## Saved locations

| Purpose | Path |
| --- | --- |
| Prior full handoff | `C:\Users\Mehran\Documents\ChatGPT\Play\tyflow-analysis\FULL-HANDOFF-REPORT.txt` |
| Working binary | `...\tyflow-analysis\inputs\tyFlow_2027.dlo` |
| Ghidra project | `...\tyflow-analysis\projects\tyFlowArchitecture.gpr` and `.rep` |
| Backup before this investigation's database annotations | `...\tyflow-analysis\research-20261006\project-before\` |
| New private selections, listings and receipts | `...\tyflow-analysis\research-20261006\` |
| Existing headless launcher / REST client | `...\tyflow-analysis\start_headless.py` / `mcp_request.py` |

All ellipses in this table expand to `C:\Users\Mehran\Documents\ChatGPT\Play`. Vendor pseudocode/assembly and original binary should remain in this private workspace; repository documents store factual conclusions and evidence fingerprints.

## Reproduce safely and accurately

1. Read [Method](METHOD_AND_EVIDENCE.md) and the machine-readable [research receipt](evidence/research-receipt.json). Verify the binary SHA-256 before using any RVA. A different release invalidates the address/ABI mapping.
2. Inspect the existing launcher/configuration, start the headless server hidden, record the new PID, and verify its local listener. The old `server-start.json` records an initial unrelated MCP connection check; it is not a launch-success receipt. Reuse the current project, or copy the preserved project if a clean before-analysis database is required. The old headless log was reused by the server; older log content is not guaranteed preserved.
3. Open/load the project through its existing REST client. Use the schema actually served by installed ghidra-mcp 6.0.0 rather than assuming current GitHub main's endpoint names. Do not expose the server externally.
4. Recreate the PE scan with `reproduce/static_pe.py <working-binary> <new-private-output> --expected-sha256 <pinned-hash>`. It validates the hash and performs a read-only scan. Its raw pattern hits require disassembly confirmation.
5. For SDK ambiguity, run `reproduce/sdk_layout.py <repo> <new-private-output>`. It needs the recorded existing MSVC/SDK paths, creates only compile fixtures and does not link/execute. Final results here are `sdk-layout-v4`, not the intermediate incomplete witnesses.
6. For a selected function family, inspect the private selection JSON and use `reproduce/ghidra_batch.py <selection-json> <new-private-output>`. The server/client port is 18089. Include chained unwind fragments and verify leaf thunks separately; exported spans must be at most 64 KiB. The script annotates the analysis database only. Review assembly, reference targets, completion/errors and manifest, not just HTTP status.
7. Treat `batch03-v2`, `batch05-v2` and `batch06-v2` as corrections to their earlier partial outputs. Do not infer cache clearing from the misnamed `Global_Mesh_Cache_Clear` helper, IsRendering from Interface slot 463, or a fully understood scheduler from the timed-out dispatch.
8. Save the program, close the project, then stop only the owned verified process. Record identities and rehash targets/source. Avoid closing another engineer's analysis session or Max instance.

## Copyable next investigation prompt

> Read `docs/TyFlow_Architecture_Research_2026-10-06/README.md` and its linked evidence, especially the method corrections. Continue only the unresolved custom render-item lifetime/upload question from submit RVA 0x01ddf130 in the pinned tyFlow 2027 binary. Map the assigned implementation through validated RTTI/vtables and official Max 2027 SDK methods. Separate verified disassembly, inferred field meanings and runtime questions. Compare with Cyrus `point_display.cpp` and `mesh_display.inc` without changing production code. Preserve private artifacts and record hashes/ranges/errors. Do not repeat broad scans, claim complete source recovery, run artist scenes/profiles, or infer presented FPS from redraw timing. Save/close the owned analysis session when done.

For the next implementation task, use [Roadmap](ROADMAP_AND_EXPERIMENTS.md) instead. Its first action is the concrete P1 context-binding correction; a new whole-engine rewrite is not supported by this evidence.
