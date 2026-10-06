# Cyrus Scatter — Complete Codebase Documentation

<!-- CURRENT_SYSTEM_2026-10-05 -->

Historical source reference, dated 27 September. Use the [current system guide](../Current_System_2026-10-05/SYSTEM_GUIDE.md), [capability coverage](../Current_System_2026-10-05/CAPABILITY_MATRIX.md) and [document authority map](../Current_System_2026-10-05/DOCUMENT_AUDIT.md) for later procedural, UI, container and MCP changes.

**Snapshot:** 2026-09-27  
**Audited source:** `MehranCyrus/Cyrus-Scatter` → `main` → `b9a9e909b469456a6193337363b7c50b2397e549`

This is the codebase-first documentation pass requested before licensing implementation. It reconstructs the earlier research package, then goes substantially deeper through the actual repository: all 97 tracked files were inventoried, every native source family was inspected, every UI generator stage/template was inspected, the generated production MAXScript was structurally analyzed, the installer/startup path was traced, native tests were read, and the existing release/feature guides were reconciled into a development history.

## What this package is

It is the technical source of truth for understanding how Cyrus Scatter is currently built. It separates:

- **CURRENT / VERIFIED** — supported by the audited source.
- **HISTORICAL / VERIFIED** — supported by repository guides/release notes.
- **RECOMMENDED** — future licensing, packaging, security or release engineering.
- **NOT RUNTIME-VERIFIED** — source was inspected, but Max/CTest/render farm was not executed in this documentation pass.

## Reading order

Start with `00_Documentation_Coverage_and_Status.md`, then `01_System_Overview.md`. The codebase reference is documents 02–18. Commercialization/licensing is documents 19–24. Sources are in 25.

## Most important architectural conclusion

Cyrus Scatter is not a MAXScript-only scatter tool. The valuable placement engine is a host-independent C++17 library. 3ds Max scene conversion and callable operations are native. Preview caching is native. CS Edit is a native modifier with persistent identities. Surface Analyzer has a separate native engine. MAXScript is the scene-state/UI/orchestration layer and generates PFlow structures for final rendering.

That means commercialization should add licensing around native host-facing boundaries rather than rewrite the product.

## Important operational note

GitHub reported the repository as **public** during this audit. If the source is intended to be proprietary, repository visibility and any prior exposure should be reviewed before commercial release.

## Verification boundary

This pass did **not** compile the code, execute CTest, launch 3ds Max, open saved MAX scenes, run Corona/Arnold/Deadline, or penetration-test binaries. Those actions are explicitly tracked in the test/risk documents rather than assumed.
