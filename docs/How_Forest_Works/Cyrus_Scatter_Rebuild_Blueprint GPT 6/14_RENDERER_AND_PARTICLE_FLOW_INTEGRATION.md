# 14 — Renderer adapters and Particle Flow transport

**Status: integration design; vendor ABI routes remain qualification gates, not completed implementations. Research basis: R0 §§5.2, 5.5–5.6.**

## 1. Rendering is an early feasibility gate

A fast core is not a useful production scatter plugin if it must duplicate every mesh or create millions of host nodes to render. Prove one end-to-end output route early, before building the entire feature surface.

The project context identifies Particle Flow render transport in existing Cyrus work. Preserve that as a baseline candidate. This task did not read or test the current bridge, so no specific API or current performance is assumed.

ForestPack's rendering reference describes renderer-native instancing for compatible integrations [S26]. That does not establish that an equivalent public interface is available to Cyrus for every renderer/source combination.

## 2. Renderer-neutral logical contract

```text
RenderSceneSnapshot
    coherent dependency revision set
    coordinate / unit / time profile
    prototype descriptors
    instance pages
    material and per-instance attributes
    animation sample references / shutter samples
    visibility policy
    capability requirements
```

A prototype is reusable geometry or a qualified procedural provider at a particular source/time/material structure. An instance references a prototype and supplies transform, ID, and supported attributes.

The renderer adapter does not regenerate candidate positions or choose collision winners. It can choose output representation such as LOD under the saved output policy.

## 3. Capability negotiation

Each adapter reports capabilities and limitations for its exact installed versions:

| Capability | Required evidence |
|---|---|
| Reusable mesh prototypes | Two instances reference one translated prototype |
| Opaque renderer proxies | Correct bounds, transform, material, and farm resolution |
| Per-instance tint/user data | Same prototype shades differently without mesh duplication |
| Element identity/edge mask | Correct source-element and instance data at shading time |
| Transform motion blur | Correct shutter-time matrices |
| Deformation samples | Shared animated prototypes at required times |
| Shear/negative scale | Correct geometry, normals, and handedness |
| Interactive updates | Stable add/change/delete lifecycle without leaks |
| Headless rendering | No dependency on viewport/UI state |
| Network/farm assets | Reproducible paths and plugin dependencies |

A boolean “supports Corona” is too broad. The matrix should identify which of these work on each qualified host/renderer pair.

## 4. Particle Flow output bridge

Treat PFlow as a transport adapter, not the authoritative engine. It receives final instances and maps them to particles/source instances under the bridge's tested capabilities.

Maintain a stable mapping from candidate IDs to transport IDs. Do not equate the current PFlow array index with procedural identity. Incremental transport updates must preserve animation/source/material correspondence.

Prevent feedback cycles when a setup both reads and writes PFlow. Output objects owned by Cyrus should be tagged and excluded from its input collection unless explicitly connected through a validated noncyclic arrangement.

### Bridge qualification steps

Create a fixture containing one source and a known set of transforms. Send it through the bridge. Verify count, pivot, nonuniform scale, material, normals, and world placement. Add a second source and per-instance variation. Render locally and headlessly. Measure node count, translated prototype count where observable, memory, and export time.

Keep the bridge only if it satisfies the required contract. A working image alone does not prove that geometry is shared efficiently.

## 5. Native renderer adapters

The adapter discovery task is concrete: identify the supported SDK version, extension registration point, prototype/instance mechanism, shader/user-data mechanism, update lifecycle, and permitted redistributable components. Compile the vendor's minimal sample before integrating the scatter engine.

A V-Ray SDK documentation entry was located [S19], but its body was not available in readable form during this task. This package therefore does not invent V-Ray class names or plugin registration code. Corona and Max-to-Arnold extension routes also require acquired, version-matched evidence. A generic Arnold core instance capability is not proof that a Max plugin can inject it through the installed Max-to-Arnold translator.

These are external integration gates, not an excuse to leave the design unspecified: the neutral contract, fixtures, failure behavior, and fallback rules are defined here. The exact ABI implementation belongs in the qualified adapter module.

## 6. Bounded generic fallback

For small fixtures, a fallback may emit standard Max instances or a combined render mesh. This provides a diagnostic route and a way to verify basic placement without a native adapter.

Before conversion, estimate instance/node count, face count, memory, and time-sample expansion. Require an explicit policy and limit. Above the limit, fail with a clear unsupported-output error. Do not silently flatten millions of plants because the native bridge failed.

A fallback may not support per-instance shader data or element trimming. Advertise the degraded capability before rendering. Never label point-boundary output as successful Edge-mode parity.

## 7. Time and render snapshots

A final render acquires a coherent snapshot for scene time and shutter interval. It must evaluate current authoritative state unless the artist explicitly selected a frozen/cached render.

Motion blur can require multiple transforms or deformation samples. Snapshot keys include source time, algorithm profile, input validity, and renderer requirements. A viewport's last sampled frame is not sufficient.

Headless evaluation must not require an active viewport, selection, modal dialog, or UI timer. Use a render-entry synchronization path that completes required evaluation or fails cleanly. Avoid a worker waiting for a main-thread task while the main thread blocks waiting for that worker.

## 8. Prototype and sample lifetime

Create each reusable prototype once per relevant source/material/time key. Reference-count or otherwise track its use across instance pages and active renders. Release it only according to the renderer lifecycle.

A prototype cache entry cannot be evicted while a renderer references it. At the end of a render, release transient samples and preserve only valid reusable data within budget. Interactive renderer updates have different lifetimes from offline renders and need separate tests.

## 9. Materials and IDs

The adapter maps stable candidate IDs, source IDs, element IDs, and material attributes into the renderer's supported channels. Shader code must not hash transient node pointers or particle array indices.

Avoid one material per plant when per-instance data can express the variation. Conversely, do not assume user data is available: classify that path as unsupported or use a bounded explicit alternative when the renderer cannot supply it.

## 10. Asset paths and farm behavior

Resolve all source/proxy/texture assets before export. Produce an asset manifest with logical URI, resolved location, content fingerprint where practical, and required renderer/plugin versions. Preserve missing assets as errors or diagnostic placeholders according to the render policy.

The package format must not embed third-party assets without the user's rights to redistribute them. Recipes can reference external assets instead.

Farm output must be deterministic from the saved scene and declared dependencies. A successful interactive preview on the artist's workstation is not a farm qualification test.

## 11. Acceptance gate

Do not mark an adapter production-ready until fixtures cover static instances, groups, source replacement, missing assets, instance tint, edge behavior where supported, animation, negative scale, cancellation, repeated renders, scene reopen, and headless execution. Record exact versions and observed limitations in the compatibility matrix.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S19]: https://documentation.chaos.com/space/VMAX/113575055
[S26]: https://docs.itoosoft.com/forestpack/rendering/rendering-best-practice
