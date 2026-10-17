# tyFlow: documented workflow and native evidence

16 October 2026. Public documentation and the installed binary are separate sources. Current online documentation is not guaranteed to describe the exact installed build. No tyFlow flow was executed in this task.

## What tyFlow documents

**VENDOR DOC.** [Birth Paint](https://docs.tyflow.com/tyflow_operators/particles/birth_paint/) paints particles on scene objects. It exposes brush radius, stroke spacing, density/scale controls, surface offset, world/object-space birth coordinates and temporary preview particles. Updating can be continuous or deferred until mouse release. Birth time can follow the paint frame, a specified frame or all frames. This provides a close interaction reference; the page does not promise a continually advancing, isolated physics sandbox during a held mouse gesture.

**VENDOR DOC.** [PhysX Shape](https://docs.tyflow.com/tyflow_operators/particles/physx_shape/) converts particles to rigid bodies with selectable collision representations and physical properties. Its ordinary Mesh hull mode is kinematic; compound convex shapes are the documented route for dynamic concave assets. Treat this operator's documented restrictions separately from the wider capabilities of a newer standalone PhysX SDK.

**VENDOR DOC.** [PhysX Collision](https://docs.tyflow.com/tyflow_operators/particles/physx_collision/) adds mesh scene colliders and collision tests, with hull representation, friction/restitution and simulation-group filtering. [PhysX Switch](https://docs.tyflow.com/tyflow_operators/particles/physx_switch/) distinguishes dynamic, kinematic, trigger and deactivated treatment. Kinematic obstacles can affect dynamic particles without being pushed themselves.

**VENDOR DOC.** The [simulation-loop guide](https://docs.tyflow.com/tyflow_particles/simulation/) places particle operator processing and velocity/spin integration before PhysX synchronization/evaluation. Moving simulations depend on earlier time steps. Static operator combinations can be recognized and reused. The [PhysX settings](https://docs.tyflow.com/tyflow_particles/object/physx/) document velocity and duration sleep thresholds, with a limitation for PhysX-bound particles.

**PROPOSED REFERENCE FLOW, not a tested scene:** Birth Paint (asset shapes and offset) -> PhysX Shape (convex/compound proxy) -> PhysX Collision (street/curb/bench) -> Display. Inspect birth-time and update settings deliberately. For static composition, capture the chosen settled state; do not assume every timeline frame is equivalent. Optional forces/initial speed can add directional drift. Exact operator interactions and paint responsiveness require an owned Max 2027 witness.

## Fresh native investigation

Tools: Ghidra 12.1.4, Ghidra MCP 6.0.0, Java 21. The existing GitHub tool inventory identified this functioning stack; alternatives were not installed. The [GitHub release README](https://github.com/bethington/ghidra-mcp/blob/v6.0.0/README.md) was fetched through the GitHub connector. Actual endpoint discovery used the running backend's `/mcp/schema`, whose catalog reports 215 tools; the startup log reports 245 registered routes. Neither count measures recovered behavior.

Input: installed `C:/Program Files/Autodesk/3ds Max 2027/Plugins/tyFlow_2027.dlo` and private lab input both hash to `5b1068b5b3627f64f78cd2b51ca0c23d616be09943077d5ffcf1c6fecc713fd9`, 650,320,384 bytes. The loaded analysis program reports the same SHA-256 and image base `0x180000000`. No vendor module was executed or modified.

The original `tyFlowArchitecture.gpr` plus `.rep` were copied into the fresh ignored run. RTTI was decoded from the input bytes, then selected callbacks were disassembled/decompiled in that copy. [Max 2027's Painter interface documentation](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_painter_canvas_interface___v5.html) and the local 2027 SDK header establish the seven virtual callback positions. No SDK compilation was needed.

| NATIVE finding | Exact anchor in this binary | Meaning and limit |
| --- | --- | --- |
| Birth Paint class has a Painter canvas base | `TFlow_OP_birthPaint`, canvas subobject offset `0x590`, vtable RVA `0x06b3f548` | Confirms shared host interaction family with Cyrus. Not evidence of identical scheduling. |
| Separate native physics operators | `TFlow_OP_physxShape`, primary vtable RVA `0x06a9f9e8`; `TFlow_OP_physxSwitch`, `0x06b02170` | RTTI/class identity only; their physics implementation was not traced. |
| StartStroke prepares temporary state | RVA `0x02df0a90`, 297 bytes / 67 decoded instructions | Allocates state, calls preparation helpers, resets several containers/flags. Exact field types remain inferred. |
| PaintStroke returns success immediately | RVA `0x02deda10`, six bytes / two instructions | This sampled callback is a stub. Work must enter elsewhere; do not claim this function emits or solves particles. |
| Both EndStroke overloads use common helpers | RVAs `0x02ded920`, `0x02ded980`, each 91 bytes / 22 instructions | Shared finalization path, not a full reconstruction of emission. |
| CancelStroke clears transient state | RVA `0x02ded890`, 116 bytes / 29 instructions | Disposes private state and truncates selected ranges. Full semantic rollback requires runtime validation. |
| SystemEndPaintSession finalizes and exits | RVA `0x02df0bc0`, 103 bytes / 24 instructions | Shares completion helpers and adds session cleanup. |
| Undo connection is concrete | Helper RVA `0x02df3f90`, 204 bytes / 46 instructions | Imported Hold `Holding`, `Begin`, `Put`, `Accept` calls, plus UTF-16 label at RVA `0x06f844f8` (Birth Paint stroke). This proves an Undo integration path, not exact Ctrl+Z results. |

Seven canvas entries and three selected helpers were inspected. Detailed vendor listings remain private. The PainterDisplay entry at RVA `0x02deda20` has 12,197 selected bytes but only 12,193 decoded bytes and a type-propagation warning; no complete sampling algorithm is claimed from it. The helper at RVA `0x02df4060` starts in a short unwind fragment but decompilation reaches further code; its full bounds/chained ownership remain unresolved. Do not present either as a fully recovered function.

## Errors and corrections retained in the research record

The initial guessed schema routes returned 404; live discovery established `/mcp/schema`. A defined-string API search returned zero matches because the saved database had incomplete definitions. A fresh raw PE scan found the names; zero results were not treated as absence.

The first selected-function export yielded one-byte placeholders and zero instructions. Those outputs were rejected. Clearing only selected ranges in the copied database and defining bounded bodies yielded the final instruction ledgers. Decompiler success alone was insufficient. The unresolved PainterDisplay gap and unwind-fragment issue are retained above.

## What Cyrus can learn, and what remains open

Reuse Max Painter rather than assume a new input framework is necessary. Keep temporary preview, authored births and committed result separate. Couple a complete gesture to one Undo transaction. Make physics participation and collider groups explicit. Give the artist a deliberate cached/settled result.

OPEN: actual held-gesture evaluation entry, preview-particle handoff, exact birth storage/serialization, collider cooking/cache keys, PhysX version in this binary, solver threading and measured responsiveness. No original tyFlow source, full physics scheduler or complete collision algorithm was recovered. Earlier UI/display studies remain [historical context](../TyFlow_Architecture_Research_2026-10-06/README.md), not evidence that these gaps are closed.
