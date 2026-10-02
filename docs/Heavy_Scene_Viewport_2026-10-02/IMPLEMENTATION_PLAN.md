# Heavy scene viewport implementation plan

Date: 2 October 2026. Starting product: Scatter 0.62 / Analyzer 0.14, including the existing uncommitted improvements. This plan follows the codebase research and the external reports supplied by the owner. It is an engineering plan, not a claim that these features already ship.

## Product contract

The owner wants **both a fast preview and full detail, with an explicit switch**. Placement, stable edit IDs, source choice, transforms and render output must stay exact. Preview density is a display choice. Full detail must identify any existing instance/face limit; it must not silently claim to show the entire render population.

The first target is a static heavy bird's-eye scene in Max 2027, followed by Max 2026 runtime qualification. Repeated navigation should reuse completed display data. A relevant edit may require calculation and publication; moving the camera should not rerun placement or resample source meshes.

## Recommended sequence

1. Preserve source, original scene, package and loaded-module identities. Keep the successful CPU and proxy changes. Use private build directories, a disposable Max scene and a private plugin configuration.
2. Establish the smallest useful display experiment: current native GraphicsWindow point submission versus an Autodesk Nitrous custom render item holding the **same points and source colors**, plus a no-scatter control. Measure first-use preparation separately from warmed navigation.
3. Use a native helper object as the experimental render-item owner. Its immutable point groups own CPU positions, a position-only vertex buffer and a stock solid-color material. `PrepareDisplay` / `UpdatePerNodeItems` attach persistent items; `Realize` uploads once per generation; `Display` draws point lists. Use the supported Max graphics interfaces and preserve render state. Do not keep an `IVirtualDevice` pointer between callbacks.
4. Prove visibility, bounds, color/point-size behavior, source counts, and zero extra uploads during camera motion. Run a point-budget sweep and a source-group sweep with alternating trial order. Test replacement, clear, hide/show, selection, clone/delete, scene reset and shutdown. A fast invisible result is a failed experiment.
5. If the experiment passes, integrate an optional retained preview into the controller lifecycle. Maintain one owner per controller, publish a completed generation on the host thread, and keep the current preview as allocation/error fallback. Add the Preview / Full Detail switch in the generator-owned UI. Integrate only after ownership and reload semantics are explicit.
6. Qualify supported source types before claiming the original artist scene is covered. The earlier BushesCenter point-cloud source-sampling error makes its old point-cloud timings incomplete. Test Corona proxy conversion separately and give unsupported sources a visible diagnostic or an explicit bounds fallback; never silently omit them.
7. Profile full Mesh separately with fixed geometry and colors. Test retained expanded geometry, then source-shared GPU instancing only if the expanded representation's cost or memory requires it. Preserve the existing mode as fallback until appearance, transforms, materials/UV scope, culling and selection are correct.
8. Add more elaborate detail selection only if fixed-budget retained points miss the quality/performance target. Prefer stable prebuilt levels and coarse spatial cells. Choose existing buffers using projected size and hysteresis; do not resample or upload the entire cloud on every camera change. Keep a global scene budget across controllers and viewports.

Forest Pack's documented fixed-budget GPU cache is the useful first reference. Its documentation warns that the older distance-dependent mode caused GPU updates on camera changes. Potree's hierarchical levels are a later reference for genuinely larger working sets, not justification for an octree before measuring a simple retained cloud. FStorm's public preview video establishes a product experience, not its private algorithm.

## First loop files

| File or directory | Purpose |
| --- | --- |
| `tools/performance/native_point_probe/` | Test-only native display owner, CMake target, build and fixture scripts; excluded from installers |
| `build/heavy-viewport-2026-10-02/` | Private SDK builds, plugin/Max INIs, transient scene and request transport |
| `docs/Heavy_Scene_Viewport_2026-10-02/` | Roadmap, research reconciliation, raw evidence, measured result and remaining work |
| `docs/README.md` | Link this loop beside existing dated evidence |

Production integration, if justified, belongs in `AminScatter/src/preview.cpp`, a dedicated native display-owner implementation, `AminScatter/CMakeLists.txt`, `AminScatter/tools/ui/display-modes.cjs` / `viewport-performance.cjs`, and the generated `AminScatter/scripts/AminScatterObject.ms`. Extract shared immutable preview data into a small header only when integration needs it. Keep renderer, sampling, RNG and CS Edit code outside this display change.

## Verification and acceptance

- Build the private native target with matching 2026 and 2027 SDKs. Run the interactive experiment in Max 2027 with verified module paths/hashes. SDK compilation does not substitute for Max 2026 runtime tests.
- Use supported mesh-only synthetic canopies first so a sampling failure cannot masquerade as a speedup. Record requested and actual points, source groups, bounds, data fingerprints, cache generation, upload count/bytes, draw count, viewport dimensions, display style, host and GPU identity.
- Compare identical camera paths and display populations in reversed repeat order. Report median, p95 and p99 **milliseconds**, first-correct-preview latency and memory. Keep CPU callback/redraw time separate from PresentMon presentation intervals and GPU metrics. Do not turn synchronous `redrawViews` time or `GetFPS` into a completed-frame claim.
- Provisional product target: heavy-scene navigation p95 at or below 16.7 ms on a named reference machine/viewport, and scatter overhead ideally within 2 ms of the disabled control. These are targets to negotiate through evidence, not guarantees for arbitrary geometry or hardware. A 120/144 Hz goal requires a stricter total frame budget.
- Accept retained display for integration only with visible correct data, zero unchanged-navigation rebuild/upload increments, bounded memory and a repeatable material reduction in display cost. A practical first gate is at least 20% p95 improvement when the baseline is outside budget; near the measurement floor, require an absolute benefit and no regression instead of chasing percentages.
- The prototype is not a release: renderer/IPR, undo/redo, save/open, source edits, multiple controllers/views, device recovery, empty/unsupported sources, Max 2026 and 32 GB hardware are separate integration gates. Do not package the test helper in the boss handoff.

## Continuous loop

For each loop: name one bottleneck and falsifiable hypothesis; capture baseline and identities; make one bounded change; verify correctness before speed; repeat a paired comparison; retain raw evidence; accept, revise or reject; update the backlog. Stop expanding that branch when it reaches the frame budget, the benefit disappears, or complexity outweighs the measured gain. GPU placement computation and a broad asynchronous engine remain deferred until operation-level traces show that calculation, rather than display, is the limiting stage.

## Primary references

- [Forest Pack display behavior](https://docs.itoosoft.com/forestpack/forest-plugin/display)
- [Autodesk custom render items](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_custom_render_item.html)
- [Autodesk MarkerRenderItem](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_utilities_1_1_marker_render_item.html)
- [Potree thesis, TU Wien, 2016](https://www.cg.tuwien.ac.at/research/publications/2016/SCHUETZ-2016-POT/)
- [FStorm preview reference supplied by the owner](https://www.youtube.com/watch?v=BgroiM6Mexo)

Local implementation references: SDK `howto/Graphics/GPUParticle/GPUParticle.cpp` demonstrates persistent render-item ownership; `samples/ParticleFlow/Actions/PFBoxGeometry.cpp` demonstrates the position-only stream. Read actual current signatures: some header example snippets are stale (`SetIndexBuffer` takes a handle reference; material `Terminate` has no argument). The Marker utility's default display depends on consolidation, so disabling immediate consolidation alone is not a retained implementation.
