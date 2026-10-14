# Viewport capacity research — 13 October 2026

**Recommendation, not an implemented or user-approved design:** combine explicit
display limits, cached inexpensive representations and a shared memory policy.
Expose a lighter **While navigating** budget and a higher **When idle** budget
instead of an ambiguous minimum/maximum allocation. Increasing memory alone
cannot bound the cost of drawing every triangle.

Scope: official Forest Pack, Chaos Scatter, tyFlow and Geo-Scatter documentation;
read-only analysis of locally installed Forest Lite and Chaos Scatter binaries;
comparison with current Cyrus source and the [Mesh test](MESH_TEST_2026-10-13.md).
No plugin implementation, installation, artist scene or vendor binary was changed.

## Documented approaches

| Product | Relevant documented behavior | Lesson for Cyrus |
| --- | --- | --- |
| Forest Pack | Cached GPU point clouds; 250,000 points per Forest object by default. Adaptive mode changes representation above a face threshold. Approximate viewport item cap. | Bound both drawn work and preview detail. [Display documentation](https://docs.itoosoft.com/forestpack/forest-plugin/display). |
| Chaos Scatter | Separate viewport instance/polygon limits; point-cloud percentage. Polygon limiting simplifies preview models. Adaptive Full mixes meshes and boxes during interaction. | Preserve useful coverage with cheaper representations. [Current Corona documentation](https://docs-chaos.atlassian.net/wiki/spaces/CRMAX/pages/124525180/Chaos%2BScatter). |
| tyFlow | Its global mesh cache retains processed geometry across flows and simulations until geometry changes. Separate diagnostics measure mesh and transform uploads. | Reuse source preparation across owners where identities match. [Cache](https://docs.tyflow.com/tyflow_objects/tyFlow/cache/), [diagnostics](https://docs.tyflow.com/tyflow_objects/tyFlow/debugging/). |
| Geo-Scatter | Viewport placeholders, point clouds, simplified display geometry and independent viewport visibility; its post-generation item limit does not prevent initial generation cost. | Keep display reduction separate from placement generation. [Optimization documentation](https://www.geoscatter.com/docs-optimization.html). |

Forest's `Max Items = 0` removes that cap, but `cloudPointsByObject = 0` restores
camera-dependent sampling. Its selection point limit is separate from display
density. These are different controls, not a universal zero convention.
[Forest display reference](https://docs.itoosoft.com/forestpack/forest-plugin/display).

Forest also documents a configurable 10 GB animation-sample cache with eviction
and zero disabling its ceiling. That is a **render-time animation cache**, not a
general viewport VRAM allowance. Its LOD feature selects user-supplied models by
distance or screen size. [Animation](https://docs.itoosoft.com/forestpack/forest-plugin/animation),
[LOD](https://docs.itoosoft.com/forestpack/forest-plugin/forest-lod).

Chaos distinguishes viewport limits from its overall scatter-generation safety
limit. Current documentation and the installed adapter's tooltips agree on mesh
simplification; older V-Ray documentation describing polygon hiding should not
be substituted for that current behavior. The portal did not render reliably in
the web reader, so the current Corona section was read through indexed official
page content. [Current Chaos reference](https://docs-chaos.atlassian.net/wiki/spaces/CRMAX/pages/124525180/Chaos%2BScatter).

More LOD models can increase retained memory even while reducing drawn triangles:
additional unique geometry must be stored. Camera clipping also needs careful
render semantics for off-camera shadows and reflections. [Chaos performance guidance](https://support.chaos.com/hc/en-us/articles/4953457092625-How-to-use-Chaos-Scatter-with-Corona-for-3ds-Max-Performance-and-Troubleshooting).

## Native evidence and its limits

The existing GitHub-origin [Ghidra MCP tool](https://github.com/bethington/ghidra-mcp)
was reused locally: Ghidra 12.1.4, MCP backend 6.0.0, isolated loopback endpoint,
copied binaries and owned project. GitHub searches did not establish an official
public source repository for either vendor plugin. This is selected binary
analysis, not recovered vendor source or a complete reverse engineering of either
product. Vendor pseudocode and binaries remain in ignored local evidence.

Forest Lite 9.4.3 / PE 9.4.3.766 matched the October 8 study's exact hash. The
earlier selected listings were re-read: marker realization at RVA `0x19f6b0`
guards an already-ready buffer and prepares 16-byte marker records; display at
`0x19f910` binds retained streams and issues the SDK draw call. The earlier SDK
witness identifies that call as `DrawInstanced`. This supports cached GPU marker
display. It does **not** establish Forest's full-mesh storage, all invalidation
conditions or comparative FPS. See [the original scoped study](../../ForestPack_Research_2026-10-08/NATIVE_FINDINGS.md).

Fresh Chaos analysis completed for nine selected adapter functions (11,532
decoded bytes across their analysis-defined bodies). All nine decompilations
completed; compiler-generated/unreachable-block and indirect-tail-call warnings
remain. Parameter types and inferred field meanings are not original source.
The assembly/reference receipts support these bounded observations:

| RVA | Observation | Confidence boundary |
| --- | --- | --- |
| `0x53460` | Calls `GenerateInstanceData` and `GenerateInstanceRenderItem` for grouped geometry; another branch uses `InstanceDisplayGeometry` and updates existing instance data when the count matches. | Actual call sites, stronger than imports alone. Does not establish all invalidation or allocation behavior. |
| `0x55eb0` | Constructs the mesh display context, calls the instance-item builder, and has a flag/counter-dependent branch that switches group descriptors to 12 faces / 8 vertices. | Consistent with adaptive boxes; exact interaction timing and all triggering conditions remain unmeasured. |
| `0x54cd0` | Looks up a source-keyed mesh entry, checks requested reduction ratio and revision/content-related values, and either returns a shared existing mesh or builds/replaces one. | Inferred preview-reduction cache from caller and data flow. The simplification algorithm and global cache scope were not established. |
| `0x92ab0`, `0xe2ac0`, `0xe28a0` | PointCloudItem preparation adds marker data; a flag guards the 16-byte buffer fill and is cleared afterward. Normal display delegates to the SDK marker item. | Retained marker preparation/display separation. No claim that every camera movement avoids every invalidation. |
| `0xb6a20` | Binds the adaptive and simplification explanations to display controls. | UI corroboration, not execution/performance evidence. |

The related read at `0x7f380` and instance accumulator at `0x531c0` were also
inspected. Autodesk documents the mesh helpers as combining mesh render items
with instance-transform data. [Max 2027 SDK](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/_render_item_handle_8h.html).

## What this means for Cyrus

The existing retained Mesh path already uses source geometry plus instance
transforms. Its admitted 2.66M-preview-triangle test reused placements, preparation
and uploads while navigating. However, the saved nine-layer preview held 16.44M
triangles and failed native memory admission, selecting the expensive CPU
triangle fallback. The measured scripted redraw timings are not presented FPS.
[Exact test scope and receipts](MESH_TEST_2026-10-13.md).

Current source has separate numeric-payload allowances: Point 64 MiB per owner /
128 MiB process; Mesh 512 MiB per owner / 1 GiB process. These include CPU and SDK
copies, not just VRAM. Proxy geometry shares the retained Mesh infrastructure.
The current GPU Mesh streams use 108 bytes per source triangle before SDK system
copies, CPU snapshots and scratch, plus 52 bytes per instance. This is per unique
source group, **not per rendered triangle multiplied by every instance**.
Memory use and visible triangle count therefore need separate controls.
[Admission](../../../AminScatter/include/preview_budget.h),
[accounting](../../../AminScatter/src/point_display.cpp),
[GPU streams](../../../AminScatter/src/mesh_display.inc).

Current preview limits apply per layer and can multiply across a controller.
Mesh admission also omits a whole source if its mesh exceeds the face allowance;
it does not create a simpler version. That explains missing palms/trees at lower
settings. [Geometry preparation](../../../AminScatter/src/geometry_preview.inc).

## Proposed controls and behavior

| Control | Recommended meaning |
| --- | --- |
| Point Cloud: navigating / idle | Maximum drawn points across the chosen scope. Optional per-layer overrides stay subordinate to the total. |
| Proxy: navigating / idle | Maximum displayed instances, with predictable primitive costs charged to the shared geometry budget. |
| Mesh: navigating / idle | Maximum drawn triangles; an advanced instance cap can bound transform/draw overhead separately. |
| Preview memory | Machine preference: Automatic or Custom allowance, accounted across all Cyrus controllers/layers in the Max process. Show estimated retained payload separately from actual device memory telemetry. |
| Adaptive preview | Switch among already prepared representations during interaction; settle to higher detail afterward without repeated preparation/upload. |

For numeric display caps, **0 means no user-imposed display cap**. It does not
disable overflow validation, finite source/placement admission, allocation
failure handling or a separately enabled memory policy. The UI must expose which
limit is active. A lower quality value should never force extra instances or force
an allocation merely to satisfy a minimum. If literal minimum/maximum controls
are retained, their quality-floor meaning needs an explicit product decision;
the user's original minimum is not yet defined.

The first implementation should retain the previous complete preview on failure
and prepare a complete, inexpensive replacement from the same published placement
epoch. Prefer cached point clouds/boxes over per-frame CPU mesh submission.
Reserve enough capacity for that replacement and old/new publication overlap;
never release the current result before the successor is ready. Large source
plants should remain represented rather than silently disappearing.

Display sampling should use stable IDs and nested subsets, with fair coverage
across layers/source types. Ordinary navigation should change draw selection,
not re-solve placements or regenerate static source geometry. A short settle delay
and separate switch thresholds can prevent repeated quality toggling. Manual
pending edits and final render populations remain governed by their existing
contracts (F04, F05, F06, F08).

Audit shared source geometry and the expanded triangle streams before choosing
larger default memory allowances. Prototype compact/indexed or SDK mesh items only
if they improve measured memory and draw cost while retaining required ownership
colors, selection behavior and failure recovery. Vendor API use is motivation for
that comparison, not proof a replacement is faster. Full automatic LOD generation
is a later, independently measured option; it need not block useful adaptive
proxies and explicit display caps.

## Acceptance before calling a future implementation complete

1. Reproduce the full nine-layer scene with useful representation of every source
   category and no CPU triangle fallback during normal navigation.
2. Measure actual presented frame times in a visible matched Max host, separately
   from cold preparation, upload time, memory residency and scripted redraw time.
3. Verify warm orbit/pan/zoom, rectangle selection and unrelated animation do not
   increment solve, static preparation or unchanged-buffer upload counters.
4. Exercise several controllers, low memory allowances, zero caps, oversized
   sources and old/new preview overlap. Retain the prior complete result on failure.
5. Verify stable placements/full transforms, Manual pending behavior, render
   equivalence, undo, save/reopen and device-resource recovery in supported hosts.

No default budgets or target FPS have been qualified by this research. No vendor
runtime benchmark was performed. The proposals are a basis for implementation
planning, not a release qualification.

## Reproducibility

Source checkout: `codex/workflow-0.75`, HEAD
`2b9ad12b24f9d91241db4567037f64db71fe9726`, existing dirty work preserved.
The local knowledge index failed full freshness verification; current source was
inspected directly and the index was not rebuilt or activated.

Local receipts: `build/viewport-policy-research-20261013-01/`, including
`capture.json`, static imports/strings/RTTI, owned analysis scripts/project and
bounded selected-function exports. `capture.json` pins seven relevant Cyrus source
files and the inputs below. Another checkout needs these ignored receipts to
independently verify native analysis.

| Input | SHA-256 |
| --- | --- |
| ForestPackLite.dlo, Max 2027 | `23b25adf28954a4cd6c3d7fe5f7ea90b6a6e9be480f8a422fa7ef8b99c9a325d` |
| ScatterMax_Release-2027.dll | `f7fdd25428e8374174501e6bb4ebd3b83e21c5ba2c33fcdc94280c022695b887` |
| ScatterCore.ForScatter_Release.dll, identity/static inventory only this pass | `069ababd0dbc09218928f24d5bdc860509b237f34af703581e3fd78ed5d3cf86` |

The Chaos package/API reports 9.0.671707; its PE version is 15.0.671707.
These identifiers should not be treated as interchangeable product major versions.
The Forest October 8 raw listings were reused only after rechecking the binary
hash and their relevant content.

Final verification: all seven captured Cyrus source hashes and all three original
and copied vendor binary hashes remain unchanged; all local report links resolve.
The nine selected Chaos bodies completed decompilation with matching decoded/body
byte counts, subject to the warnings above. `summary.json` and the 75-file
`evidence-manifest.json` retain the checks. The analysis project was saved and
closed; only the verified owned backend PID 92840 was stopped. Artist Max PID
42796 remained running. Research changed this report and its handoff link only
outside the ignored evidence folder. No build, installation, commit or push ran.
