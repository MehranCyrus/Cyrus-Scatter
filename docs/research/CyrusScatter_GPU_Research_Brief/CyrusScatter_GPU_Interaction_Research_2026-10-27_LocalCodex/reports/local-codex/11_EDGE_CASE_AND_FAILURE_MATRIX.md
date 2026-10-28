# Edge-case and failure matrix

**Status: P — required test cases, not a list of tests passed.** Executed coverage in this research is limited to the two standalone probes in document 10. Assign stable fixture IDs to the following cases when implementation starts.

## Geometry and contact

| ID | Case | Required behavior / check |
|---|---|---|
| G01 | Sphere crosses middle of a long span; endpoints outside | Detect whole-span contact; compare analytic capsule witness |
| G02 | Broad leaf crosses stone while guide is clear | Surface validator detects it; bounded refinement or explicit failure |
| G03 | Triangle crosses collider, vertices outside | Edge/triangle checks catch crossing |
| G04 | Root lies strictly inside collider, hiding disabled | Preserve root; report infeasibility rather than silently deleting |
| G05 | Contact just at tolerance | Stable signed-gap policy; no classification flicker |
| G06 | Degenerate/zero-length span | Explicit point treatment or rejected preparation; no NaN |
| G07 | Antiparallel consecutive tangents | Defined material-frame rotation and no quaternion flip |
| G08 | Welded multi-branch plant | Explicit authored separation/guide policy; no accidental single ribbon |
| G09 | Leaf attached midway to a bent parent | Attachment remains at correct material parameter |
| G10 | Several independent planted groups in one source | Hide/bend each group and its attachments consistently |
| G11 | Fixed trunk/pot intersects collider | Explicit fixed-decoration conflict; no attempt to bend fixed pieces |
| G12 | Root flare and radial roots | Compound/authored proxy follows footprint; cylinder limitation visible |
| G13 | Open leaf-card tree selected as solid | Reject invalid solid or request separate trunk proxy |
| G14 | Concave stone or wall recess | Do not replace concavity with a convex hull without artist choice |
| G15 | Nonmanifold/open/self-intersecting mesh | Invalid/ambiguous classification status; no fabricated outside result |
| G16 | Thin feature below SDF resolution | Exact fallback or admitted error; no false clearance certificate |
| G17 | Narrow-band field queried outside band | Unknown/incomplete status, not extrapolated clear space |
| G18 | Two colliders trap a rooted stem | Bounded solve, independent final check, coherent failed successor |
| G19 | Many overlapping collider proxies | Stable pair ordering, deduplication, no duplicate clearance application |
| G20 | More colliders than admitted per plant | Resource-limit result; never truncate silently |
| G21 | Large building next to tiny grass | Broad phase remains bounded; no fixed-grid explosion |
| G22 | Floating collider with Under collider enabled | Explicit downward footprint exclusion; distinct from volume mode |
| G23 | Hide margin changes, Contact gap constant | Only intended exclusion semantics change |
| G24 | Contact gap changes, hiding disabled | Bending clearance updates; geometry count remains deliberate |

## Coordinates, scale and data

| ID | Case | Required behavior / check |
|---|---|---|
| D01 | Millimetre, centimetre, metre and imperial scenes | Same physical result after conversion |
| D02 | Source units differ from current scene display units | Fingerprint/capture uses actual system units, not displayed suffix |
| D03 | Source rotated and uniformly scaled | Local query scale, normals, reach and gap correct |
| D04 | Negative/nonuniform scale or shear | Explicit unsupported handling until separately qualified |
| D05 | Large world coordinates, small gap | Rebased arithmetic remains within geometric tolerance |
| D06 | Rebase while old generation is drawing | Tagged origins; no mixed-coordinate frame |
| D07 | NaN/Inf in source, transforms or solver output | Rejected before publication; previous result retained |
| D08 | 32-bit product/count overflow | Checked host sizes and bounded dispatch offsets |
| D09 | Different source definition with same node name | Content/revision identity prevents wrong cache reuse |
| D10 | Preparation editor changes only one source | Invalidate its dependents; other source uploads reused |
| D11 | Preview blades 5% versus 100% | Display population changes; all relevant guides still solved |
| D12 | Shared vertex spans two visibility groups | No partial triangles or collapsing spikes |

## Editing, publication and display

| ID | Case | Required behavior / check |
|---|---|---|
| E01 | Collider leaves a plant neighborhood | Restore rest pose and hidden groups at old location |
| E02 | Collider teleports far away | Old/new endpoint neighborhoods updated for static semantics |
| E03 | Reacting instance itself moves | Correct target pose and relevant colliders; no source mutation |
| E04 | Multiple Cyrus Edit stone overrides | Both published and edited indexes considered |
| E05 | Repeated rapid reversal | Monotonic coherent publication, bounded lag, final target exact |
| E06 | Continuous input faster than kernels | Coalescing and no publish starvation/unbounded queue |
| E07 | Change stiffness/hide/preparation during compute | Semantic revision rejects incompatible completion |
| E08 | Undo/Redo before completion | No late result from undone state |
| E09 | Delete source/controller, then recreate node | Lifetime token prevents stale-owner publication |
| E10 | Open/reset scene while compute is pending | Safe retirement, no old scene references |
| E11 | Camera navigation and selection only | Zero contact refits and zero unchanged-buffer uploads |
| E12 | Offscreen affected plant becomes visible | Correct pose exists; visibility culling did not skip authoritative fit |
| E13 | Two viewports with different visual styles | Shared data, correct wireframe/material behavior in each |
| E14 | Strong bend outside rest bounds | Conservative draw/pick bounds avoid disappearing geometry |
| E15 | Hit-test a visibly bent leaf/stone | Correct stable instance identity and coherent geometry/proxy |
| E16 | Mesh, Textured mesh, Wireframe, Point Cloud | Correct output in each; no obsolete buffer assumption |
| E17 | Render/Bake/export during pending edit | Exact requested authoritative revision or explicit wait/fallback |
| E18 | Source/UV/material change after caching | Correct topology, corner/material mappings and upload invalidation |

## Device, performance and failure

| ID | Case | Required behavior / check |
|---|---|---|
| F01 | No NVIDIA runtime/device | CPU feature remains available; actionable accelerator status |
| F02 | CUDA and viewport on different adapters | Detect and avoid unsupported sharing |
| F03 | KHR sharing absent, NV sharing present | Query correct variant; local standalone case already demonstrated |
| F04 | Both sharing variants absent | Compact CPU bridge or CPU fallback; no null function call |
| F05 | VRAM allocation/staging admission fails | No partial result; identify required/available budget |
| F06 | Large active queue or pair list overflows | Incomplete/resource-limit status; no arbitrary drop |
| F07 | GPU timeout/device removal | Device epoch reset, safe invalidation, CPU/SDK reconstruction |
| F08 | Kernel fails after submission | Surface error status, retire resources, keep coherent prior state |
| F09 | Slow GPU plus many stale generations | Bounded ring/backpressure; memory cannot grow without limit |
| F10 | Shutdown/plugin unload with work pending | No callbacks into unloaded code or in-flight resource release |
| F11 | Many retained poses, one changed guide | Measure CPU map-copy/publication work separately from GPU kernel |
| F12 | Many resident plants, K=0 | Near-zero interaction work independent of dense source geometry |
| F13 | Render/compositor shares same GPU | Tail latency and memory pressure measured under realistic load |
| F14 | Cold JIT/cache miss/driver upgrade | One-time work identified; no compile per drag |
| F15 | CPU and GPU disagree on near-boundary sign | Resolve by defined tolerance/independent check; no arbitrary deletion |
| F16 | Backend switch with existing poses | Coherent geometry and visibility, no scene-data loss |

The matrix contains **70 cases**. A future pass count must identify fixtures, backends, source versions and environment. A checkbox alone does not establish execution, and cases spanning several modes need separate sub-results.
