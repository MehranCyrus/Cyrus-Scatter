<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 11 — Edge-case and failure matrix

## Evidence labels

- **[V] Verified public source** — official specification/vendor documentation, original paper, or inspected public repository listed in [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md).
- **[P] Provided project fact** — supplied project context; not independently verified against the private repository.
- **[M] Provided measured observation** — reported by the supplied context and not reproduced here.
- **[E] Executed here** — artifact/hash/link/integrity work performed in this environment.
- **[A] Analytical estimate** — formula or byte count with explicit assumptions; not a benchmark.
- **[R] Recommendation / proposed design** — to be validated locally.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

## Status vocabulary

- **Supported:** required behavior for the initial qualified architecture.
- **Proposed:** design exists but requires local implementation/qualification.
- **Rejected:** intentionally outside the first contract or unsafe behavior.
- **Unknown:** blocked on host/source/runtime evidence.

“Expected behavior” describes the product requirement, not an executed result.

## Geometry, contact and solver cases

| Case / trigger | Expected behavior | Algorithm hazard | Mitigation / diagnosis | Reproducible test | Status |
|---|---|---|---|---|---|
| Clear rest pose | exact rest geometry and transform-only unaffected path | unnecessary solve/upload | dependency counters remain unchanged | source with distant collider; compare IDs, transforms, buffers and rest reconstruction | Supported |
| Endpoint-clear segment crosses sphere | reject/fit until entire capsule clears | vertex-only sampling misses interior | analytic segment–sphere minimum distance | authored segment endpoints outside sphere but midpoint inside; require visible clear result | Supported |
| Endpoint-clear segment crosses rotated box | same | endpoint/axis-only test misses OBB crossing | segment/capsule vs OBB or exact triangle proxy | diagonal span through rotated OBB with endpoints outside | Supported |
| Broad ribbon/card intersects while guide is clear | not accepted as final | guide centerline does not represent width | certified envelope plus visible triangle validation | offset card with centerline clear but edge inside sphere | Supported |
| Envelope too small for source | reject source/quality tier before solve | false conservative certificate | rest reconstruction and maximum offset audit | bind wide blade to narrow radius; require preparation failure | Supported |
| Whole visible triangle inside closed solid | reject/diagnose containment | surface-edge intersection can be absent | signed point/triangle containment plus distance | small triangle wholly inside sphere/closed mesh | Supported |
| Large triangle vertices outside but face intersects sphere | detect overlap | vertex-only mesh validator misses face interior | exact point-to-triangle / triangle-sphere distance | sphere through center of large triangle | Supported |
| Large triangle vertices outside but face intersects box | detect overlap | vertex-only/edge-only test misses SAT axis | full triangle–AABB/OBB separation test | OBB crossing triangle interior with all triangle vertices outside | Supported |
| Root inside required clearance | no root drift; fail or apply declared hide policy | solver may move root or explode | root classification before fit; explicit infeasible result | root at sphere center, hide disabled | Supported |
| Root inside hidden region | hide whole rooted group and attachments only | arbitrary blade removal | stable rooted-group ownership | expected hidden group IDs and no partial topology deletion | Supported |
| Narrow gap below two envelopes + gap | infeasible; retain last good | oscillation, stretch or hidden penetration | geometric gap precheck and residual diagnostic | two boxes squeezing one blade | Supported |
| Two competing colliders, feasible | fit against both | nearest-only query; contact order dependence | include all relevant colliders; stable contact reduction | authored S-curve between sphere and box | Supported |
| Deep initial penetration, movable nonroot spans | bounded depenetration or explicit failure | wrong normal/feature; huge correction | closest feature + step/strain caps; independent final validator | blade interior initially inside convex obstacle | Proposed |
| Sharp convex corner | stable contact without snapping through | discontinuous closest feature | multi-contact/active-set, conservative radius, stable tie rules | sweep rest pose around box corner | Proposed |
| Concave closed rock | respect cavities | convex proxy fills concavity; sign ambiguity | exact mesh BVH final tier; compound proxy declared approximate | U-shaped closed mesh | Supported final / Proposed interactive proxy |
| Thin closed obstacle | no tunneling at final pose | SDF/mesh tolerance exceeds thickness | exact mesh and scale-aware clearance; reject too-coarse field | thin shell thicker/slimmer than voxel sizes | Supported exact |
| Open mesh | surface-only or authored proxy; no false solid | parity/winding sign invalid | detect open/nonmanifold; require policy | single plane and open bowl | Supported diagnostic; solid semantics Rejected |
| Nonmanifold/malformed mesh | reject or use authored proxy | undefined inside/normal/BVH features | sanitize report, no silent repair claim | duplicate/degenerate/self-intersecting triangles | Supported diagnostic |
| One-sided card obstacle | explicit two-sided surface/proxy policy | back-face miss | authored collision policy | approach both sides of plane | Proposed |
| Contact after guide moves into new BVH region | regenerate local contacts | stale candidate triangles | conservative query expansion or re-query on movement bound | guide bends beyond initial leaf candidates | Supported |
| Excessive strain/bend | fail quality, retain old | solver clears by stretching | hard strain/max-angle limits | impossible sphere/gap fixture | Supported |
| Iteration limit with residual penetration | completed computation ≠ achieved quality | false success flag | residual and exact visible validator | low-iteration fixture designed not to converge | Supported |
| Near-zero span | preparation failure | division by zero/NaN frame | finite and minimum-length admission | zero and epsilon-length spans | Supported |
| Quaternion sign flip | same physical interpolation | long-path slerp | normalize sign for shortest path | `q` vs `-q` rest/deformed frames | Supported |
| Near-full-turn/ambiguous frame | reject preparation/pose | shortest-path collapse loses authored turn | explicit ambiguity threshold and artist correction | 360-degree twist over one span | Supported rejection |
| Parent/child branch attachment | socket remains continuous | child solved independently from stale parent | depth schedule/socket constraints | two-level branch around obstacle | Proposed |
| Fixed attachments | unchanged unless owning guide changes | blanket deformation | source role flags | mixed fixed rock/flower part and flexible stem | Supported |
| Visible self-fold/inverted triangles | reject or report quality | centerline valid but mesh invalid | signed area/Jacobian/normal checks | wide ribbon at extreme bend | Proposed |

## Scale, transform and numerical cases

| Case / trigger | Expected behavior | Algorithm hazard | Mitigation / diagnosis | Reproducible test | Status |
|---|---|---|---|---|---|
| Very small asset | consistent metre-scale tolerance or unsupported diagnostic | universal epsilon dominates geometry | scale-relative admission/tolerances | same fixture scaled 1, 1e-3, 1e-5 within admitted range | Proposed |
| Large world coordinate | same local result after rebase | FP32 cancellation | plant/request-local origin and high-precision host transform | translate fixture by large architectural offset | Supported architecture |
| Unit change | invalidate/rebuild snapshots; no stale pose | cached metres mismatch | units/frame revision in request key | change Max units and reload | Supported |
| Positive uniform scale | clearance/length scale exactly once | double scaling | explicit conversion boundary | scales 0.1, 1, 10 | Supported |
| Nonuniform scale | diagnostic and CPU unsupported path; no approximate GPU pose | sphere/capsule/frames become anisotropic | reject current contract or separately implement affine metrics | scale `(2,1,0.5)` | Rejected first release |
| Mirrored/negative scale | diagnostic | handedness, winding, frames | reject current contract | negative axis scale | Rejected first release |
| Shear/nearly singular transform | diagnostic | invalid inverse, frame collapse | determinant/condition check | synthetic shear and near-zero axis | Rejected first release |
| NaN/Inf input or output | atomic failure, last good retained | propagation through kernels/bounds | finite checks at capture, dispatch outputs and validation | inject NaN transform/node | Supported |
| CPU/GPU reduction order difference | stable status within tolerances | bitwise comparison false alarms | stable IDs/keys and tolerance metrics | repeat across GPU/driver/CPU | Supported policy |

## State, host and resource cases

| Case / trigger | Expected behavior | Algorithm hazard | Mitigation / diagnosis | Reproducible test | Status |
|---|---|---|---|---|---|
| Manual pending edit | old publication remains until Update | partial live publish | owner mode in request gating | move collider in Manual, inspect counters, press Update | Supported |
| Live relevant edit | coalesced newest complete publish | event flood | one in-flight + newest pending | high-rate transform events | Proposed async |
| Camera/selection/wireframe | no solve or unchanged upload | view event coupled to interaction revision | separated display revision | navigate/F3/select; inspect counters | Supported |
| Collider departs/removes | old neighborhood restores rest/retained pose removal | only new bounds queried | union old/new, deletion tombstone | move far/delete/Undo | Supported |
| Collider teleport | endpoint quasistatic newest pose; no CCD claim | skipped path mistaken for sweep | explicit semantics and old/new candidate union | teleport across plants | Supported endpoint semantics |
| Source geometry edited | invalidate preparation/all dependent poses | stale vertex/binding layout | source fingerprint/revision | modify topology/position/UV split | Supported |
| Material-only edit | geometry solve reused if vertex identity unchanged | over-invalidation | separate stream/material revision | change bark/leaf material | Proposed |
| Placement population changes | stale results discarded; stable surviving IDs | merge against old rows | placement revision and stable-ID map | regenerate density/update while request in flight | Supported architecture |
| Undo/Redo during in-flight work | stale completion discarded; correct restored generation | callback publishes after history change | request revision recheck | issue Undo before fence completion | Proposed async |
| Delete owner/instance during work | no use-after-free/publication | raw scene pointer lifetime | owned IDs + scene epoch + host queue | delete layer/controller while job runs | Proposed async |
| Scene reset/load/merge | cancel/retire/rebuild transient caches | callbacks into destroyed scene | scene epoch and shutdown barrier | reset/load during pending request | Proposed async |
| Cancellation at each stage | no partial successful output | partial buffer mistaken complete | private generation + complete bit | inject cancellation after capture/query/solve/validate | Supported architecture |
| Work/contact/memory admission exceeded | explicit over-budget and last-good | unchecked allocation or silent subset | preflight counts, chunk/fallback | exceed pair/guide/scratch bounds | Supported |
| Missing CUDA runtime/driver | plugin loads CPU path | hard link/startup failure | optional delayed/dynamic backend | remove/rename runtime; start Max | Proposed distribution |
| OpenCL loader present, no platform | CPU path; clear diagnostic | loader mistaken for device | platform/device enumeration | no vendor ICD | Proposed distribution |
| Unsupported extension | fallback path | optional OpenCL feature assumed | capability queries and kernel variant | device without command buffer/D3D sharing | Proposed |
| Shader/kernel compile failure | CPU fallback, cache error | persistent broken cache | versioned cache and invalidation | inject bad shader/kernel | Proposed |
| VRAM allocation failure | chunk/CPU fallback/last good | partial eviction/publication | admission and allocation rollback | constrained budget/fault injection | Proposed |
| TDR/device removal/recreation | invalidate transient GPU resources, retain CPU scene/result | stale device handles | device generation + callbacks + lazy rebuild | controlled device reset if safe | Proposed |
| Multi-adapter mismatch | compact host transfer or CPU; no zero-copy claim | sharing across wrong LUID | adapter identity gate | Intel/AMD display + NVIDIA CUDA | Unknown until Max probe |
| Remote desktop/headless | CPU/fallback and supported display behavior | graphics device unavailable/different | runtime detection | RDP/headless session | Proposed |
| GPU renderer contention | stable but possibly slower; budget-aware | VRAM/queue starvation | realistic concurrent benchmark | selected renderer active on same GPU | Unknown renderer-specific |

## Output fidelity cases

| Case / trigger | Expected behavior | Algorithm hazard | Mitigation / diagnosis | Reproducible test | Status |
|---|---|---|---|---|---|
| UV seams/coincident positions | remain distinct | welding by position | semantic render-vertex IDs/topology equality | duplicated seam vertices | Supported |
| Changed topology/UV/material correspondence | validator rejects mismatch | plausible positions hide wrong source | fingerprints and exact arrays | mutate one index/UV/material | Supported |
| Custom normals/tangents | declared fidelity or fallback | naive frame transform changes authored shading | separate contract and CPU geometric comparison | hard-normal/atlas card asset | Proposed/deferred |
| Bounds too small but plausible | reject and recompute | GPU geometry clipped/culling wrong | exact evaluated bounds audit | shrink supplied bounds | Supported |
| Picking differs from display | selection uses declared proxy/materialized pose | rest-mesh hit test | CPU pose proxy or exact hit path | click deformed extremity | Proposed Max |
| Renderer differs from viewport | no release claim until selected renderer passes | viewport-only shader | canonical CPU materialization | image/mesh comparison | Unknown renderer-specific |
| Bake/export differs | exact topology/UV/material/pose contract | transient GPU-only data | CPU evaluator and stable IDs | Bake/export/reimport | Proposed Max |
| Approximate interactive tier shown as final | forbidden | status lost at publication | quality flag and required final Update | proxy SDF intentionally misses thin feature | Supported policy |

## Failure record

Every rejected request should retain a machine-readable record:

```json
{
  "request_serial": 0,
  "status": "infeasible|invalid-input|over-budget|stale|cancelled|device-failure",
  "quality": "final|interactive-approximate",
  "placement_id": 0,
  "guide_id": 0,
  "span_id": 0,
  "collider_id": 0,
  "metric": "visible_penetration_m",
  "value": 0.0,
  "limit": 0.0,
  "certificate": "exact|conservative|approximate",
  "message": "..."
}
```

A conservative proxy overlap depth must never be labelled exact physical penetration.
