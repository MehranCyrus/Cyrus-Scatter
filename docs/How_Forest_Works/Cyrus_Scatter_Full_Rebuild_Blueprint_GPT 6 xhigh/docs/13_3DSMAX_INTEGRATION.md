# 13 — Autodesk 3ds Max native implementation, SDK threading, painting, UI and Undo

## 1. Important boundary

**[SDK-VERIFY]** 3ds Max C++ APIs, renderer plugin interfaces and UI integration vary between Max releases. Do not copy illustrative signatures blindly; verify against the exact installed SDK headers and compiler/toolset. Autodesk states the 3ds Max SDK is generally not thread safe in concurrent render-session guidance. [Autodesk render sessions](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/3ds_max_sdk_features/rendering/new_rendering_api/render_session.html).

## 2. Division of labor: native C++ vs MAXScript/UI

| Responsibility | Preferred owner |
|---|---|
| Candidate generation, spatial indexes, collision, stable RNG | Native C++ compute library |
| Scene-node capture and mesh conversion | Native Max adapter on allowed host threads |
| Paint callbacks and viewport hit/overlay | Native Max adapter; UI controller |
| Undo persistence/save chunks/references | Native Max plugin/object integration |
| UI controls, presets, dialogs, command orchestration | Existing MAXScript/UI where reliable; native bridge |
| Renderer-native instances | Renderer-specific C++ integration/adapters |
| Long-running build scheduling/cache manager | Native runtime without off-thread host API calls |
| Library asset browsing/previews | UI + metadata services |

Do not transfer thousands of instance transforms over slow fine-grained MAXScript calls each brush update. Expose batched native methods.

## 3. What type of host plugin should represent a scatter?

Evaluate existing Cyrus object representation before choosing. Possible host classes: geometry/object with procedural render handling, helper object with output plugin, or utility plus scene-persistent controller. Selection affects transforms, mod stack, subobject picking, scene saving and renderer support. Decide based on actual SDK capabilities and existing plugin contract, not abstract preference.

Regardless of host plugin type, keep authoring configuration and generated instance buffers logically separate.

## 4. Scene snapshots

Before background evaluation:

1. On host-allowed thread evaluate relevant scene-node object at `TimeValue`.
2. Capture node transform, geometry snapshot, face/material IDs, mapping channels and source bounds.
3. Copy into owned native arrays with document-assigned stable `NodeRef` UUID.
4. Record node/content revision/time.
5. Release temporary host-evaluation locks or objects according to SDK ownership rules.
6. Dispatch immutable snapshots to worker pool.

Do **not** store an unprotected `INode*` in a worker task and later assume it's still valid after scene deletion/Undo.

## 5. Notifications and invalidation

Autodesk documents system notification codes and reference-change mechanisms. [Notification codes](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/group___notification_codes.html).

Monitor relevant changes: source node transform, topology, modifier evaluation, UV/maps, material reference, spline geometry, object deletion, rename (for name matching only), unit system, time, scene load/reset, renderer switch and camera state. Coalesce reentrant notifications; use guard flags to avoid infinite update loops when your own plugin modifies scene state.

Implement an explicit invalidation mapper rather than treating any `REFMSG_CHANGE` as a full plugin rebuild. A conservative full-rebuild fallback is still necessary when the change cannot be classified safely.

## 6. Painting interfaces

Autodesk documents `IPainterCanvasInterface_V5` with `StartStroke`, `PaintStroke` providing hit position/normal/face/bary/pressure and `EndStroke`/`CancelStroke`/`PainterDisplay`. [SDK reference](https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-CPP-API-REF/class_i_painter_canvas_interface___v5.html).

Decide whether to use host PainterInterface or custom interactive tool after prototyping latency and coordinate fidelity. Build one `PaintSessionController` that normalizes both into identical `StrokeSample` data. Keep brush overlay independent of generator rebuild; be robust to node deletion and scene close during active session.

## 7. Undo/Redo

Autodesk documents `theHold.Begin()`, `Put(RestoreObj*)`, `Accept()` and `Cancel()`. Each started undoable operation must be accepted or canceled. [Hold SDK](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_hold.html).

For our persistent custom data, implement appropriate `RestoreObj`/parameter-block recording. `BeginStroke` starts one user transaction; intermediate samples alter a working data version; `EndStroke` commits one Undo item; cancel aborts/reverts. Don't create a separate undo record for every mouse-motion callback. Handle nested `theHold` activity and exceptions with RAII-style transaction guard.

```cpp
// Illustrative only; actual SDK ownership/lifecycle requires verification.
class ScopedMaxUndo {
    bool active = false;
public:
    ScopedMaxUndo() { theHold.Begin(); active = true; }
    void Commit(const MSTR& label) { theHold.Accept(label); active=false; }
    ~ScopedMaxUndo() { if (active) theHold.Cancel(); }
};
```

Undo invalidates any worker jobs built against the undone revision. Pending jobs must not republish undone state.

## 8. Viewport display and selection

Autodesk documents `ViewportDisplayCallback` and `NodeDisplayCallback` for host viewport rendering/interaction. [Viewport callback](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_viewport_display_callback.html) · [Node display callback](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_node_display_callback.html).

Use SDK-approved display facilities for the installed Max version. Avoid assuming unrestricted direct GPU-API access or that callback drawing will automatically support millions of points. Test rendering backend, device loss, multiple simultaneous viewports, selection hit-testing, zoom/orbit and high-DPI tablets.

## 9. ParamBlocks and UI state

Define persistent property IDs and versioned semantics; map source/area/field/effect UUID lists to UI models. A MAXScript rollout should issue a typed command such as `SetAreaFalloff(areaUUID, curveSpec)` rather than directly mutating unsupported internal caches. Native engine returns diagnostics and updated state; UI should never infer success simply from a spinner changing value.

Exposed scripting API needs permission boundaries and validation: source references, create/delete area, set transform ranges, paint create/erase, refresh surface, generate, get stats, export. Provide batch operations for automation and MCP integration without allowing arbitrary unsafe C++ callbacks.

## 10. MAXScript vs native ownership

MAXScript can remain valuable as the interface layer, asset coordination and artist automation surface; moving compute-heavy loops to C++ is generally appropriate. However, existing Cyrus architecture may already contain efficient native work. **Audit first.** Blindly rewriting stable host code introduces compatibility and regression risks.

## 11. Thread safety and snapshot → compute → publish

Main thread: scene reads/writes, UI, Undo, host-render entrypoints as required, publish host-visible state. Worker pool: immutable triangles, arrays, noise, fields, collision, deterministic sampling and candidate sorting. Renderer export must follow each renderer's entrypoint contract. Avoid calling host `Texmap` or SDK scene methods off-thread unless explicitly documented safe.

Cancellation requires no incomplete scene mutation; publish only a completed, revision-validated immutable snapshot. At scene shutdown, cancel tasks and release host callbacks in safe order.

## 12. Host-specific acceptance tests

- Load/save/clone/merge/XRef scatter objects across supported Max versions.
- Undo/Redo a long paint stroke, delete source object, change render engine, close scene mid-compute.
- Modify terrain and source while viewport orbit runs; no deadlocks, crashes, stale republish.
- Change system units and verify canonical brush size/height/collision radii.
- Animate receiver, camera and source mesh across frame scrubbing.
- PFlow/reference adapters respect host evaluation time.
- MAXScript batch commands do not need to ship 1M per-instance values individually.
- All callbacks unregistered and resources released on plugin unload/shutdown.

## 13. Version/platform build plan

Choose a **supported version matrix** (e.g. initial Max release verified with your toolchain), build one SDK plugin against it, then add later Max versions using version-specific adapters/build jobs. Windows x64, runtime libraries, renderer header availability, binary compatibility and packaging differ across releases. Maintain per-version CI or reproducible local build scripts and compile-time capability guards.
