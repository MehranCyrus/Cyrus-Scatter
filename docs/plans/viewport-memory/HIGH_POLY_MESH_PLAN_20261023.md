# High-poly trees in Mesh mode — implementation plan

23 October 2026. **Planning only; implementation is not authorized by this file.**

User objective: remove the artificial viewport restriction preventing detailed
trees from displaying as full meshes, without changing scatter results. Preserve
the existing material/leaf-opacity behavior as well. No plugin code, source
assets, scenes, installer or website is changed in this planning task.

Baseline: [Scatter 0.86.8.6/schema 59](../combined-installer/DELIVERY_08686.md),
branch `codex/workflow-0.75`, HEAD
`3d387550cacf37fe1aeae7a01455f7644d9cf08b`, with substantial pre-existing dirty
and untracked work. The gallery correction reused the preceding native binaries.
These findings are from inspected working-tree source, not a clean HEAD checkout.
Knowledge generation `8a58031bf6efb27cf7c8e30a81d6059206b292269b5e5e24bf1045b704989059`
has changed enrolled sources; the exact-symbol search returned no evidence.
Direct source inspection is the basis of this plan. No host, build or tests were
run for this planning task, and the reported trees' actual costs are not measured.

## 1. What must change

The screenshot reports **“Viewport material resources exceed the appearance
allowance.”** This is an admission rejection, not a measurement of exhausted
VRAM. The existing renderer already instances source meshes: source geometry is
stored once per prepared source group and accepted transforms are separate.
Replacing the placement engine or building another renderer is unnecessary.

Several restrictions must be addressed together:

| Current restriction/cost | Inspected source | Consequence |
| --- | --- | --- |
| Appearance estimate `CPU + 2 × GPU > 256 MiB` | [material_preview.inc:374](../../../AminScatter/src/material_preview.inc#L374) | The reported error happens before the mesh preview is published. |
| Two float32 `Point3` UV records per triangle corner | [point_preview.h:64](../../../AminScatter/include/point_preview.h#L64), [material_preview.inc:309](../../../AminScatter/src/material_preview.inc#L309) | 72 CPU bytes per triangle, plus the same UV stream on the GPU. The preceding appearance test weights UVs alone at 216 bytes/triangle. |
| Three expanded geometry streams | [mesh_display.inc:165](../../../AminScatter/src/mesh_display.inc#L165) | 108 submitted geometry bytes per source triangle, plus 36 retained CPU bytes and upload/SDK copies. This is per source, not multiplied into CPU triangles per placement. |
| 512 MiB owner and 1 GiB process mesh allowances | [preview_budget.h:45](../../../AminScatter/include/preview_budget.h#L45), [point_display.cpp:174](../../../AminScatter/src/point_display.cpp#L174) | A mesh can pass the appearance check and later become boxes or fail another admission check. |
| 2,000,000 inspected/retained source-face limits | [geometry_preview.inc:33](../../../AminScatter/src/geometry_preview.inc#L33) | Large individual trees or several detailed sources can fail independently of the appearance limit. |
| Separate 2,000,000-face metadata inspection limit | [source_geometry.inc:5](../../../AminScatter/src/source_geometry.inc#L5) | This also gates calculation metadata and Auto Radius; it requires separate treatment from retained display memory. |
| Appearance charged even when the generation selects boxes | [point_display.cpp:204](../../../AminScatter/src/point_display.cpp#L204) | Draw-plan estimates can include resources the box representation does not upload, while genuinely retained CPU data still needs accounting. |

The present CPU/GPU-copy multipliers are estimates. A reservation overlap is not
automatically a duplicate allocation: distinguish an ownership transfer from real
coexisting storage before changing a charge. Existing artist draw caps, source
cardinality, placement limits and material capability limits are separate
contracts; this repair does not remove them.

## 2. Preservation contract

Apply [F02/F04–F08/F11](../../ENGINEERING_FOUNDATION.md): conditional placement
stability, Manual/Live behavior, complete publication, bounded memory/work,
host-thread access, buffer reuse and persistence.

- Keep candidate/accepted identities, accepted order, source choices, transforms,
  scales, radii, collision/clearance decisions, Paint coverage and layer ownership
  identical for the same supported inputs. Do not alter the solver, random
  channels, source weights, Count, spacing, cleanup or source geometry.
- Keep exact output, render instancing, Bake and PFlow bound to the same accepted
  publication. Preview buffers remain derived data and never feed calculation.
- Preserve source pivots and transforms, material slots, separate color/opacity
  UV channels, float32 UV precision, atlas pixels and resolution, color conversion,
  filtering, flat shading and the current 0.5 opacity cutoff. Ordinary Mesh must
  retain leaf cutouts; Textured mesh must retain supported source color.
- Preserve Manual pending edits and relevant Live updates. Switching display,
  selecting, browsing, unrelated animation and warm navigation must not solve
  static placements or re-upload unchanged resources.
- Keep the previous complete result and valid resources on failed preparation,
  admission or upload. Preserve Undo/render/history pins; never clear history or
  truncate accepted placements to obtain memory.
- Keep schema 59, recipe 8, existing class IDs and material capabilities. No LOD,
  geometry decimation, half precision, changed normal calculation, automatic
  proxy substitution presented as success, or new saved performance setting.

## 3. Recommended implementation sequence

### HPM0 — Freeze and measure the actual failure

After implementation is authorized, use a disposable Max 2027 profile and an
owned copy of the reported tree scene/assets. Do not run reset/mutation fixtures
in the artist session. Record exact source/package/loaded module hashes.

Reproduce the two-tree case first, then the reported mix of flower, grass, leaf
and tree layers. Record source faces, material slots, used map channels and the
stage rejecting the preview. Separate retained CPU allocations, SDK system
copies, GPU resource sizes, conversion cost, temporary upload storage and old/new
coexistence. Record distinct resources and references so sharing can be verified.
Use existing `cyrusPreviewResourceStats`, retained-stream/material counters and
mesh stats; add narrowly scoped native diagnostic detail where those cannot
explain the actual rejection. Do not label reservation counters as actual VRAM.

Capture a bounded exact placement witness from the functioning Proxy/Point mode:
IDs, source choices, complete transforms, radii, ordered rows, fingerprint and
epoch. Record accepted, prepared and actually drawn counts separately.

**Exit:** a reproducible tree failure with a resource breakdown and an unchanged
placement baseline. No arbitrary new memory numbers are selected beforehand.

### HPM1 — Correct ownership and peak accounting

In `preview_budget.h`, `point_preview.h`, `point_display.cpp`,
`geometry_preview.inc`, `material_preview.inc` and `mesh_display.inc`, give each
owned immutable allocation/reservation a clear lifetime and resource category.
Use the existing native ownership/RAII model; keep the change local to previews.

The cost model must distinguish:

1. retained source geometry and instance/provenance arrays;
2. retained appearance UV/atlas data;
3. SDK system copies and device buffers;
4. upload/conversion scratch and item/palette overhead;
5. genuinely new resources and old/new resources that coexist during replacement.

Count a shared physical allocation once at process scope. Count each distinct
resource referenced by a controller once in that controller's logical footprint.
Do not equate matching sizes, names or hashes with an already shared allocation.
Broader cross-layer source-cache sharing is unnecessary unless measurement shows
it is required and its geometry/material/revision ownership can be proven.

Transfer the charge when a staging vector's storage moves into a snapshot;
retain both charges when both allocations really exist. Resource handles shared
between generations must keep their reservation alive until their last owner
releases them. Retirement must not depend on a now-deleted controller pointer.
The [production publication path](../../../AminScatter/src/point_publication.inc)
must continue to account for the previous complete generation during admission.

Plan-specific GPU estimates should describe the buffers that will be realized.
Box plans may omit full-mesh UV/texture GPU charges, but must still count CPU
appearance objects or full GPU resources that remain pinned. Do not change which
accepted placements or sources the existing draw policy selects.

**Exit:** exact-boundary, sharing, ownership-transfer, failed-acquisition and
last-owner-release tests; measured retained/peak estimates agree with the traced
allocation graph. No weakened failure retention or undercounted SDK copies.

### HPM2 — Replace the unrelated fixed memory ceilings

Replace the separate 256 MiB appearance rejection and fixed 512 MiB/1 GiB mesh
ceilings with one coherent, finite preview-admission policy based on the complete
resource plan. Keep CPU commitment and device-resource constraints separate.

- Admit additional CPU/SDK/system-copy peak against available system commit,
  with explicit physical-memory/host headroom so the operation does not rely on
  heavy paging. Existing committed bytes are already reflected in OS headroom;
  do not subtract them twice. Keep shared process bookkeeping for other Cyrus
  controllers and in-flight successors.
- Device admission must include new GPU allocations and outstanding uploads.
  If querying Windows video-memory budgets, establish that the queried adapter
  is the active Nitrous adapter. Max's inspected `DeviceCaps` exposes feature
  level only; do not assume GPU 0 is the active device or describe installed
  VRAM as available memory.
- Use a documented, finite calibrated policy when reliable adapter telemetry is
  unavailable. Choosing its tested ceiling, margins and update behavior is an
  HPM0/HPM2 engineering decision, recorded with the target hardware and peak
  costs. It must admit the reported full-mesh workload on the qualified machine.
  An unknown budget must never become “unlimited.”
- Sample admission information at preparation/commit boundaries. Budget pressure
  can reject a new successor; it must not mutate placements, evict pinned
  history or rebuild static scenes on every viewport frame. Do not request a
  different GPU device or bypass Nitrous resource ownership.
- Keep checked arithmetic, finite resource/work bounds and all-or-nothing
  reservations. Allocation success remains an independent requirement even if
  estimated headroom is sufficient.

**Exit:** the reported trees pass both appearance and full-generation admission,
including a material refresh with old/new overlap and a second controller. Low
headroom, unavailable telemetry and actual allocation failure retain a complete
previous result and give a specific diagnosis.

### HPM3 — Remove the separate high-poly face bottlenecks safely

Split metadata inspection admission from retained display geometry admission;
both currently use `sourceInspectionFaceLimit` but have different costs.

For [metadata inspection](../../../AminScatter/src/source_geometry.inc#L30),
preserve the existing streaming bounds/signature algorithm exactly: face count
hash, float32 pivot-local transform expression, face/corner traversal, repeated
corner hashing, negative-zero canonicalization and ordered bounds accumulation.
Preserve weak-reference invalidation and validity intervals. Do not use coarse
object bounds, decimated vertices or viewport bounds for Auto Radius. The Max
`ConvertToType` call may still materialize a complete host mesh; measure/admit
that cost separately from the constant-extra-storage metadata loop.

Replace the 2M aggregate cutoff with an explicit finite inspected-work policy
qualified for the target trees. For display retention, use checked source-byte
and SDK index/vertex-count admission under HPM2 rather than the same aggregate
face constant. Validate before allocating large retained arrays. Keep every
source triangle and its order for successful full Mesh preparation. Use 64-bit
checked counters, including conversion to SDK draw/count types.

`procRadiusGeometry` and the Manual geometry-correspondence guard retain their
current meaning. For previously admitted scenes, require exact geometry
signatures, bounds, Auto radii and placements. For sources the old version
rejected above 2M faces, use a frozen ordered reference scan and synthetic known
bounds/placements; do not invent an old successful output for an unsupported
input. Leave placement cardinality, 512-source, material-slot and population
rules unchanged.

**Exit:** an individual source above 2M faces and multiple sources whose aggregate
exceeds 2M can pass in qualified full Mesh workloads; malformed meshes and
genuinely excessive work/memory still reject with complete-result retention.

### HPM4 — Reduce proven temporary/storage waste only where required

Keep the current source-local geometry, instanced transforms and transformed-edge
flat-shading calculation initially. No indexed renderer, normal rewrite or new
GPU subsystem is needed to replace the incorrect admission boundaries.

Bound upload scratch using supported Nitrous buffer initialization/locking where
measurement demonstrates a full temporary stream is redundant. The SDK supports
initialization without initial data and range locks; verify actual system-copy
and realization lifetimes before selecting this path. Preserve original float
values and vertex order, release locks/resources on every failure, and do not
move Max scene evaluation to workers or drawing callbacks.

Lossless UV compaction is an optional measured step. Two float32 UV pairs and one
exact material slot can replace the duplicated slot in two float3 records, if
the supported stream/shader layout proves equivalent. A straightforward
24-to-20-byte layout saves only 16.7% of UV storage: the old appearance formula
would still admit only about 1.49M triangles before atlas/overhead. It is not a
substitute for HPM1–HPM3 and is not required if the measured target already fits.
No float16, UV quantization, reduced atlas resolution or unqualified seam/vertex
welding is included. Keep unsupported-material fallbacks unchanged.

**Exit:** a measured peak-memory reduction with exact UV/material data parity and
matching flat shading/cutouts; otherwise omit this optimization from the repair.

### HPM5 — Qualify complete behavior and report the actual envelope

Use Max 2027 only for new host/SDK qualification. Existing 2024/2026 receipts
retain their original scope; this plan does not claim new qualification for them.

| Test family | Required proof |
| --- | --- |
| Reported scene | Both tree sources at Count 2, then all reported layers: actual full-mesh triangles presented, correct materials/cutouts and no appearance error. Box fallback is not a pass. |
| Source geometry stress | Inputs below/above the old appearance boundary; one >2M-face source; multiple sources >2M in aggregate; repeated instances and shared/unshared resources across layers/controllers. Resource costs scale with distinct source data plus instance arrays. |
| Placement equality | Exact ordered IDs, sources, transforms, radii, accepted counts and fingerprints before/after all display changes. Compare render/output/Bake/PFlow on bounded fixtures. Preserve original Auto-radius signatures/bounds. |
| Appearance | Opaque/color-only and opacity-card controls; independent UV1/UV2; Multi/Sub IDs and seams; negative/nonuniform transforms; supported Standard/Corona paths; unchanged atlas bytes, 0.5 clipping, color conversion and flat shading. |
| Invalidation/reuse | Material/opacity/UV edits refresh appearance; relevant geometry edits obey Manual/Live. Radius/instance edits retain unchanged source geometry/material resources. Selection, library/panel browsing, warm redraw and unrelated animation cause zero additional solves or unchanged-buffer uploads. |
| Failure/recovery | Inject failure at snapshot/appearance allocation, reservation, first/later group upload and replacement. Previous complete placement/output stays valid; no partially updated sibling layers or mixed epochs. Verify presented display recovery as well as CPU publication. |
| Lifetime/persistence | Close/delete/recreate owners, Undo/Redo, mode switches, repeated refresh, scene reset and save/reopen. Shared resources remain valid; eventual unpinned resources and reservations release without clearing history. |
| Honest performance | Record cold preparation, host conversion, upload, warm draw, actual presented frame timing and retained/peak memory separately. Resource counters and redraw duration are not VRAM or presented FPS. No speed/FPS promise precedes measurement. |

Extend the production [publication tests](../../../AminScatter/tests/publication_tests.cpp)
and [viewport-policy tests](../../../AminScatter/tests/viewport_policy_tests.cpp)
with shared-resource/admission cases. Add focused native geometry-metadata and
resource-plan tests around the extracted production helpers, not mirror-only
test implementations. Reuse the host isolation/stream witnesses from
[source-clearance validation](../../../tools/source_clearance_08681/README.md),
adapting fixture owners/versions explicitly.

The [million-leaf witness](../source-clearance/VIEWPORT_MILLION_LEAVES_20261021.md)
has only 516 source triangles and does not establish high-poly support; retain it
as an unaffected large-placement/reuse control. Small opacity-card tests remain
appearance controls. Add the actual high-poly sources as the missing workload.

**Delivery gate:** full meshes really display within a recorded tested resource
envelope; all placement/material/persistence/recovery checks pass. Actual hardware
exhaustion remains bounded and reported. Do not advertise arbitrary mesh sizes or
unlimited memory. Any future user-test release needs its exact qualified
script/native/Gallery pair and runnable Max 2027 MZP with guards/hash verification.
Select its version under the version policy at that time; this plan changes no
version, installer or website.

## 4. Expected edit boundary after approval

Required native files: `preview_budget.h`, `point_preview.h`,
`source_geometry.inc`, `geometry_preview.inc`, `material_preview.inc`,
`point_display.cpp`, `mesh_display.inc` and focused test/build registration.
Change `point_publication.inc` only where allocation ownership requires it,
preserving its transaction and recovery behavior. `script_memory_budget.h` is an
existing headroom reference, not an invitation to change script heap behavior.

UI/error reporting, if needed, belongs in the authoritative
`tools/ui/templates/unified-core.ms` and generated outputs. Keep it bounded:
identify the failed source/layer, requested representation, required/available
resource category and retained result. Do not report five independent layer
failures when one display transaction was rejected. No UI redesign is included.
Update current artist guidance only after the new behavior is proven.

This is separate from the earlier [SP06 readability proposal](../code-quality/SCATTER_SIMPLIFICATION_PLAN_20261022.md),
which intentionally preserved the old formulas. The present user request
explicitly investigates changing capacity/admission while preserving results.
It authorizes this plan, not implementation or unrelated roadmap work.

## Primary API references checked

- [Autodesk Max 2027 IVirtualDevice](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_virtual_device.html): existing instanced drawing and buffer binding. Local Max 2027 headers were inspected for `DeviceCaps`, `VertexBufferHandle::Initialize`, range `Lock` and `RealizeToHWMemory`; this is API availability, not runtime qualification.
- [Microsoft QueryVideoMemoryInfo](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_4/nf-dxgi1_4-idxgiadapter3-queryvideomemoryinfo) and [budget structure](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_4/ns-dxgi1_4-dxgi_query_video_memory_info): process/adapter budget and usage. The ability to identify/query the active Nitrous adapter remains an implementation gate; no telemetry was sampled from the artist's session.
