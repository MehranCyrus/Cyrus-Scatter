# Research and design decisions

> Original 26 October research/proposal. Implementation was subsequently authorized as 0.87.4. See [current decisions](IMPLEMENTATION_0874.md) and [executed evidence and remaining limits](DELIVERY_0874.md); planned rows below are not all passed.

26 October 2026. Proposed editor; inspected baseline is [0.87.3.2](../scatter-interactions-garden-20261025/DELIVERY_08732.md). Research, current implementation and future acceptance are distinguished below.

## What we already have

| Inspected source | What it establishes | What the editor still needs |
| --- | --- | --- |
| [analysis.hpp](../../../CyrusVegetationLab/experiments/stem-live/analysis.hpp), [analysis.cpp](../../../CyrusVegetationLab/experiments/stem-live/analysis.cpp) | Copied positions in metres, Z-up; faces, material IDs, bounded settings and geometry fingerprints. | Authored region/root/attachment inputs and editor-session revision handling. |
| [topology_analysis.cpp](../../../CyrusVegetationLab/experiments/stem-live/topology_analysis.cpp), `analyzeTopology` | Connected-component labels, tube/ribbon inference, crown endpoint voting and parent connections. | Reusable component inspection before a successful analysis; artist intent applied before guide inference. |
| [stem_core.hpp](../../../CyrusVegetationLab/experiments/stem-live/stem_core.hpp), [stem_core.cpp](../../../CyrusVegetationLab/experiments/stem-live/stem_core.cpp) | Guides with parents and anchor vertices; flexible, rigid-following and fixed parts; one binding per source vertex. | Stable authored guide identities and explicit overrides. Current fixed parts still carry a valid guide index internally; they are not fully independent data records. |
| [interactions_source.cpp](../../../AminScatter/src/interactions_source.cpp), `prepareSource`, `saveSource`, `fitSource` | Automatic preparation routes, saved definitions, actual-surface checks, immutable source data and per-instance poses. | Authoring-aware preparation/cache keys, validation and persistence. Do not bolt on a second deformation engine. |
| [interactions_host.cpp](../../../AminScatter/src/interactions_host.cpp), `capture` | Host mesh capture, unit conversion, source watches, retained visual channels and weak caches. | Independent capture/inspection access for models whose inference fails; safe popup lifetime and asynchronous numeric jobs. |
| [interactions-authoring.ms](../../../AminScatter/tools/ui/templates/interactions-authoring.ms), `interactionsPrepare` | Stable source-row association, staged definitions, one Prepare action and settings refresh. | Optional editor entry/commit bridge that preserves authored overrides during later automatic refreshes. |
| [interactions-ui.ms](../../../AminScatter/tools/ui/templates/interactions-ui.ms) | Current role/source controls, primary preparation settings and folded limits. | One additional editor button and concise source status. |
| [recipes.ms](../../../AminScatter/tools/ui/templates/recipes.ms) | Recipe export currently rejects contact definitions/collider links. | No recipe support is implied by this editor. `.max` persistence is the first delivery boundary. |

The original [source-preparation research](../../research/vegetation-interaction/03-SOURCE-PREPARATION.md) already identifies semantic parts, framed guides, stable rest bindings and the danger of assigning different motions to a shared vertex. Its historical prototype status remains unchanged; the current source and delivery establish what has since been implemented.

### The fern is a useful example, not a universal benchmark

The preceding delivery records 38,818 vertices, 50,382 triangles and 2,079 components for `Outdoor_Plants_01_Neottopteris_Nidus_Bush_Decorative05_001`. Of these, 1,930 are tiny 13-vertex pieces. The corrected automatic definition has 547 guides, including 36 broad-leaf crown guides, and 47 fixed decorative parts. These are historical observations from the exact qualified package, not measurements repeated during this research.

The proposed editor lets the artist explicitly mark the broad leaves as Bend and appropriate decorative components as Keep fixed. It must not assume that all other components are dispensable, or promise that the final rig will contain exactly 36 guides. Stems and attached details may still be required.

## Primary reference findings

These sources inform design; none demonstrates a Cyrus implementation or transferable performance result.

| Reference | Verified lesson | Cyrus decision |
| --- | --- | --- |
| [Autodesk: Using Qt with 3ds Max plug-ins, 2027](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-Developer/files/writing_plug-ins/using_qt_with_3ds_max_plug-ins.html) | Qt UI integration and SDK examples are documented. | Use a Max-owned modeless Qt window; inspect `QtMax` helpers and `qtObjectDemo` before implementation. |
| [Autodesk: SDK requirements, 2027](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-Developer/files/about_the_3ds_max_sdk/sdk_requirements.html) | The host targets Qt 6.8.3 and the Max 2027 SDK/toolchain. | Match the host's Qt ABI; do not redistribute a competing generic Qt runtime or infer older-host compatibility. |
| [Qt 6.8: QOpenGLWidget](https://doc.qt.io/qt-6.8/qopenglwidget.html) | A widget can render an owned OpenGL view; context destruction/reparenting requires explicit resource cleanup. | A compact source-only shaded viewer is feasible in principle. Prove it in Max before committing the UI architecture. Keep all graphics calls on the UI thread. |
| [Autodesk: ViewWindow](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_view_window.html), [gfx.h/createGW](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/gfx_8h.html) | Extended views are custom windows; `createGW` is documented as internal. The installed `maxapi.h` explicitly describes non-3D extended windows. | Do not assume these APIs create a supported standalone Nitrous scene viewport, and do not reparent Max's existing viewport HWND. |
| [SideFX: Guide Groom](https://www.sidefx.com/docs/houdini/nodes/sop/guidegroom.html) | Guide curves can be selected, grouped, moved and masked independently of surrounding geometry. | Borrow the small interaction pattern: choose a part, see its guide, correct it. Defer the many grooming/sculpting tools. |
| [SideFX: Joint Capture Paint](https://www.sidefx.com/docs/houdini/nodes/sop/kinefx--jointcapturepaint.html) | Region selection, component fill and surface-aware painting support controlled deformation; point-count changes require explicit snapshot handling. | Start with categorical component roles and topology-guarded bindings. Continuous weight painting and remapping belong to a later contract. |

Local inspection also found `Qt6Core`, `Qt6Gui`, `Qt6Widgets`, `Qt6OpenGL` and `Qt6OpenGLWidgets` DLLs at version `6.8.3.Adsk-002` in the installed Max 2027 directory. This establishes runtime presence, **not** a compiled viewer, available matching development libraries, driver compatibility or measured responsiveness.

## Selected architecture and alternatives

| Decision | Recommendation and reason |
| --- | --- |
| Normal workflow | Keep automatic Prepare. The editor is optional and reachable even when analysis fails. |
| Popup rendering | Native C++ Qt window with an owned, source-only mesh view. Neutral shading, part colors, guides and a private test sphere; no renderer integration required for selection. |
| Viewer feasibility fallback | If the Qt/OpenGL spike fails, evaluate a floating control window using the existing Max viewport with native command-mode picking. Record the changed UX before implementation; do not silently substitute it for the promised popup. [CommandMode](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_command_mode.html) documents viewport mouse interaction, not an embedded viewer. |
| Browser/Three.js viewer | Technically another option, but adds geometry transfer, a separate rendering/input stack and deployment work. No measured need justifies it for this native host editor. |
| Selection unit | Whole connected piece first. The current decoder has one binding per vertex; arbitrary face labels cannot safely express conflicting motions on a shared vertex. |
| Role representation | A small override per selected piece, layered over existing inference. “Exclude from analysis” alone is insufficient: excluded geometry must either follow a guide or remain fixed. |
| Guide corrections | Root-end hints, direction, existing control points and parent/attachment selection first. Preserve source rest shape when recomputing bindings. |
| Computation | Native numeric model and selection data; generated MAXScript only opens/commits and binds the current owner. |
| Updates | Auto-refresh the draft after a completed editing gesture; one explicit scene commit. Coalesce work, never discard authored geometry to keep the UI responsive. |
| Reuse | One source-slot definition reused by its instances; compatible immutable compiled data may be deduplicated. Do not make edits global to every layer referencing the same scene node. |

## Important limits

1. **Connected geometry is not botanical identity.** A welded bush can be one piece. Conversely, seams and coincident shells can make one leaf look like several pieces. Material IDs are selection aids, not proof of a leaf boundary. No automatic proximity weld is introduced.
2. **A selected region is not a smaller input mesh.** Preserve full geometry and relevant root/parent context. Restrict guide candidates, then bind every retained vertex. Cropping the snapshot changes root detection and breaks correspondence.
3. **Fixed roots can make contact impossible.** Authored guides cannot make a solid sphere pass through an immovable base without intersection. Report the affected root/part and retain the prior complete result. Do not hide failures as successful bends.
4. **Selection is separate from display percentage.** Editing must expose all admitted source pieces. Scatter's 5%/100% foliage preview must not decide which parts are selectable or processed.
5. **Fewer guides do not imply fewer render polygons.** Preparation/solve cost can decrease, but full geometry capture, source storage and final drawing remain. Benchmark the complete path before claiming an optimization.
6. **An alpha card is one geometric surface.** Multiple painted leaves in a texture are not independently bendable blades. The first editor shows solid geometry and does not reconstruct alpha silhouettes.

## Evidence limits and open gates

Read-only knowledge verification checked 64 enrolled parents: 50 matched and 14 were stale. Generation `637cdc784e7dba8eab31f2703578abc9011bd792d70fa553095aa37fd1b4613a` is therefore not current evidence. An exact path search for `interactions_source.cpp` returned no excerpts. This plan relies on the directly inspected files pinned in [SOURCE_EVIDENCE.json](SOURCE_EVIDENCE.json), not on a fresh-corpus claim.

The working tree already contains substantial unrelated changes. Branch/HEAD alone cannot reproduce this baseline. No native build, Max launch, UI experiment or new performance measurement was executed for this research. Remaining feasibility gates: matching Qt development inputs, popup/context lifetime, precise selection on dense leaves, meaningful root hints, latest-only worker cancellation, and complete commit/Undo behavior.
