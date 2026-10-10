# Research ledger and planning rationale

Reviewed 10 October 2026. **Documentation, selected binary observations, local source findings and proposed designs are different evidence classes.** None proves a prototype's runtime quality. This pass inspected existing analysis exports; it did not launch a new Ghidra investigation or a Max test.

## Current Cyrus evidence

Baseline: commit `880ea89b654a389191c02e7a373807044ec713f1`, 0.77. Read the root [README](../../../README.md), [agent workflow](../../../docs/AGENT_WORKFLOW.md), [architecture](../../../docs/ARCHITECTURE.md), [backlog](../../../docs/BACKLOG.md) and [0.77 evidence](../../../docs/Paint_Feedback_0.77_2026-10-10/README.md).

In [brush.cpp](../../../AminScatter/src/brush.cpp), `CoverageCache::build` clamps output to 32,768 triangles, limits visited work to budget times twelve and can return an incomplete result. In [brush_host.cpp](../../../AminScatter/src/brush_host.cpp), `evaluate` uses the returned triangles for the next tint. This can replace a complete earlier preview with incomplete coverage. The screenshot's exact runtime cause remains unconfirmed without its scene and loaded identities; display loss is not proof of saved paint deletion.

Earlier same-area long-history qualification is useful but too narrow to establish expanding-area brush quality. Its 1,000-stroke fixture produced only 832 tint triangles. The [older cost probe](../../../docs/ForestPack_Research_2026-10-08/brush/REGION_COST_EVIDENCE.json) explicitly measures a frozen Cyrus core only; it does not benchmark Forest, a polygon implementation, display or FPS. Do not repurpose it as a vector victory.

## Evidence table

| Source | What it supports | What it does not establish |
| --- | --- | --- |
| [Forest Areas documentation](https://docs.itoosoft.com/forestpack/forest-plugin/areas) | Painted areas, add/subtract workflow and spline interchange | All internal structures or unlimited curved-surface painting |
| [Forest native brush findings](../../../docs/ForestPack_Research_2026-10-08/brush/NATIVE_FINDINGS.md) | Inspected path uses Max Painter, projected integer circle footprints, Boolean contour edits and closed LinearShape publication | Complete product architecture, all versions, tested cache hit rates or performance |
| [Deeper vendor code map](../../../docs/Vendor_Native_Deep_Research_2026-10-09/CODE_MAP.md) | Selected Chaos path uses face/barycentric anchors, segment bounds hierarchy and Euclidean tubular containment | Geodesic distance, complete layer precedence or a general grayscale mask implementation |
| [Prior vendor host tests](../../../docs/Vendor_Surface_Paint_Research_2026-10-09/README.md) | Specific Forest flat coverage and Chaos curved paint observations on recorded fixtures | Universal speed/stability or unchanged-data cache reuse |
| [Houdini Attribute Paint](https://www.sidefx.com/docs/houdini/nodes/sop/attribpaint.html) | Attribute painting and caching/baking of results; stroke, surface and visibility options | That Houdini uses our proposed face tiles, or that its renderer/brush can be transplanted |
| [Autodesk Painter V7](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_painter_interface___v7.html) | Host Painter can initialize/update from evaluated object states | A ready-made mask storage or fast display implementation |
| [Autodesk scripted paint tools](https://help.autodesk.com/cloudhelp/2022/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Paint-Tools/GUID-69632609-C1FC-43F3-BA75-17033A41DA9C.html) | Scripted input scaffold is possible | That script-only kernels offer a fair native algorithm comparison |
| [Clipper2 overview](https://angusj.com/clipper2/Docs/Overview.htm), [robustness](https://angusj.com/clipper2/Docs/Robustness.htm) | Public polygon Boolean candidate, integer precision/range tradeoffs | Exact Forest library version or guaranteed preservation of sub-resolution geometry |
| [Clipper2 repository](https://github.com/AngusJohnson/Clipper2), [license](https://github.com/AngusJohnson/Clipper2/blob/main/LICENSE) | Public implementation with Boost license; current README warns about triangulation bugs | Permission to assume its triangulation is ready for our fill path |
| [Disney Ptex repository](https://github.com/wdas/ptex) | Per-face texture mapping as a reference without artist UV layout | A brush engine, our exact triangular schema, or a necessary dependency |

The current [Chaos Max documentation page](https://documentation.chaos.com/space/CRMAX/124525180/Chaos+Scatter) yielded no extractable page text through the web reader in this pass. Use the qualified local reports for the listed Chaos claims; do not substitute C4D documentation for unverified Max behavior.

## Corrections that matter to the decision

**Forest really does resolve the inspected paint workflow into borders.** The observed footprint is a 24-vertex circle, with union/subtraction and simplification before closed shape publication. The exact tolerances and complete surface eligibility are not qualified. A uses this architectural idea, not copied private code or a compulsory 24-vertex rule. Its initial domain is projected terrain.

**The later Chaos research is more specific than the early report.** Its [code map](../../../docs/Vendor_Native_Deep_Research_2026-10-09/CODE_MAP.md) identifies face plus two barycentric coordinates and a segment hierarchy. The exported tubular containment routine uses ordinary 3D distances. Re-reading the local reconstructed routine confirms that this is not evidence of geodesic painting. Model replacement observed in a fixture is also not identical to grayscale density accumulation. C adopts neither assumption silently.

**Baking current values is a distinct candidate.** Houdini documents cached paint values on geometry; Ptex illustrates face-based addressing. D combines those principles in a new proposed design. B is the simpler projected raster alternative. Both must prove that resolution, seams and memory are acceptable. These are engineering hypotheses, not recovered vendor implementations.

## Tooling checked locally

See the machine-readable [inventory](../evidence/planning-inventory.json). It records checks for Ghidra 12.1.4 files, Java 21 tool files, ghidra-mcp 6.0.0 JAR, the Max 2027 Painter SDK header and MSVC 14.38 compiler. File availability does not certify a live server or successful new build.

All seven installed inputs listed by the earlier deep investigation were hashed again: Forest package metadata/plugin/startup script and Chaos package metadata/loader/adapter/core. Their comparison with previous hashes is recorded individually. Selected raw Chaos exports (`stroke_tube_contains.c`, `stroke_bounds_prepare.c`) remain in the existing ignored `build/vendor-native-deep-20261009-01/` run; their hashes are recorded without copying reconstructed vendor code into the lab.

The existing launcher/client under `C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/` can support a later narrow investigation if a prototype exposes an unanswered question. Do not restart broad disassembly merely to accumulate more research. The useful next evidence is a working small comparison.

## Remaining research questions tied to tests

- If C leaks through a folded surface, compare an explicit surface-distance restriction against D; do not assume Chaos solves it elsewhere.
- Qualify a contour fill triangulator on holes, touching boundaries and degeneracy before adopting it for A. Pin dependency revision/license in its build manifest.
- Confirm reliable Max presentation timing and retained line/fill upload accounting in the host spike. CPU callbacks cannot certify FPS.
- For D, settle seam reconstruction and variable face resolution with small oracle fixtures before a high-density scene.
- If all kernels are fast but drawing is slow, isolate display transport before changing canonical storage again.

No vendor implementation or benchmark is treated as a requirement to copy. The user's workflow, measured correctness and measured interaction determine what proceeds.
