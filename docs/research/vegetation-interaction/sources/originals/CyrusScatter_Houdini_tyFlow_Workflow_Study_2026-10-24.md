# CyrusScatter Vegetation Interaction
## Practical Houdini and tyFlow Workflow Study

**Date:** 24 October 2026  
**Purpose:** Workflow-focused extension to the earlier *CyrusScatter Vegetation–Obstacle Interaction Engineering Research*.  
**Target Cyrus qualification host:** Autodesk 3ds Max 2027.  
**Scope:** Research and reproducible workflow design only. No Cyrus repository changes and no production implementation were performed.

---

## 1. What this report does—and does not do

This addendum does **not** repeat the earlier literature survey or re-argue the general choice between procedural fields, XPBD, rods, cloth, and rigid-body engines. It studies how two mature DCC applications expose the practical artist workflow for the same four scenes:

1. rooted grass bending around one fixed stone;
2. rooted grass constrained between two stones;
3. rigid pebbles settling on irregular terrain;
4. fallen leaves settling against a curb, with rigid and deforming leaves treated separately.

The purpose is to learn from documented authoring, initialization, constraint, collision, cache, rendering, and export behavior—not to infer any vendor’s private solver algorithms.

### 1.1 Evidence labels

Every workflow is marked with one or more labels:

| Label | Meaning |
|---|---|
| **D — Documented** | The stated node/operator capability is explicitly described in current official documentation. |
| **X — Inspectable vendor example** | The vendor documentation exposes a named loadable/launchable example or example `.max` scene. It was identified, but not executed here. |
| **P — Proposed recipe** | The node order is an engineering synthesis of documented components. The vendor does not document the complete end-to-end use case. |
| **T — Local test required** | A specific host test is necessary before the workflow can be treated as qualified. |
| **E — Executed here** | The workflow was run and measured in this research environment. **There are no E-labelled results in this report.** |

### 1.2 Execution boundary

No Houdini or 3ds Max/tyFlow runtime was available in this environment. Therefore:

- node and operator capabilities were verified against official documentation;
- official example names were recorded where public documentation exposes them;
- no `.hip` or `.max` scene was opened;
- no simulation timing, memory result, contact quality, renderer result, or export round-trip is claimed as measured;
- every proposed recipe has an explicit local acceptance test.

### 1.3 Version boundary

- The SideFX pages inspected are the **Houdini 22.0** documentation. `Guide Utility` and the expanded `Guide Deform` node are marked **Since 22.0**; Vellum Solver and Hair Generate are older, established nodes. [H-GUIDE-UTILITY] [H-GUIDE-DEFORM] [H-VELLUM-SOLVER] [H-HAIR-GENERATE]
- The current tyFlow version history inspected lists **tyFlow v2.010, 25 May 2026**, as the newest documented release. The current system requirements state that the latest build supports **3ds Max 2020 and above**. This places Max 2027 within the stated host-version range, but it is not a substitute for an executed Max 2027 qualification. [T-VERSION] [T-SYSTEM]
- tyFlow’s current system-requirements page states that CCCS requires an NVIDIA GPU supporting **CUDA 11.2 or higher** and that several core CCCS algorithms have no CPU fallback. An older FAQ page still says CUDA 10.0. This report treats the current system-requirements page as authoritative and records the FAQ discrepancy as a documentation risk. [T-SYSTEM] [T-CCCS-FAQ]

---

# 2. Decision summary

## 2.1 Best documented reference workflow by problem

| Problem | Houdini | tyFlow | Practical conclusion for Cyrus |
|---|---|---|---|
| Rooted grass, one stone | **D/X:** Vellum Hair guides, explicit position/orientation pins, external collision, guide-to-dense deformation | **D/P/T:** direct cloth-card workflow is documented; generic guide-chain + `tyParticleSkin` is only a proposed test | Houdini is the stronger reference for a source-guide contract and separate root controls. |
| Rooted grass, two stones | **D/P:** same Vellum setup with multiple colliders; infeasibility remains visible | **D/P/T:** cloth cards can collide; guide chain remains unqualified and point-radius collision is a limitation | Cyrus must expose “unresolved/infeasible,” not merely “solve completed.” |
| Pebbles on terrain | **D/X:** packed RBD + proxy geometry + Bullet | **D:** PhysX Shape + PhysX Collision | Both validate a transform-only rigid-body path; this is not the same architecture as deforming grass. |
| Rigid leaves at curb | **D/P:** packed RBD with a finite-thickness collision proxy | **D/P:** PhysX rigid bodies with box/convex/compound hull | Rigid leaves can retain source sharing until export/materialization. |
| Deforming leaves at curb | **D:** Vellum Cloth | **D/X:** Cloth Bind + Collision, optional CCCS | Per-leaf shape state breaks ordinary transform-only instancing. |

## 2.2 Central findings

1. **Root position and root orientation must remain separate controls.** Houdini documents this directly: `Pin Type` controls point position, while `Orientation Pin Type` controls hair orientation. tyFlow’s `Object Bind` likewise exposes Position and Rotation as separate bind types. [H-VELLUM-CONSTRAINTS] [T-OBJECT-BIND]
2. **Automatic obstacle fitting in both applications is normally a timeline solve.** Houdini Vellum Solver is explicitly dynamic; tyFlow bindings, Cloth Bind, and PhysX are evaluated through simulation time. A settled frame can be frozen, but that does not make the original process a static one-cook fit. [H-VELLUM-SOLVER] [T-BIND-SOLVER] [T-PHYSX]
3. **Houdini also exposes a manual static shaping workflow.** Guide Groom provides Brush, Deintersect, Sculpt with Physics, root locking/orientation, and Set Rest State. This is artist-directed grooming, not a documented automatic static obstacle fitter. [H-GUIDE-GROOM]
4. **Guide collision is not the same as final render-geometry collision.** A guide can be clear while a card, leaf width, or clump envelope still penetrates. Collision thickness must include the render envelope or the final geometry must be validated after deformation.
5. **Houdini’s sparse-guide-to-dense-output pattern is the strongest product reference.** Simulate a bounded guide set, then deform or regenerate dense render curves/meshes. `Guide Deform` 22.0 supports captured guide weights and a quasi-static Preserve Shape pass; `Hair Generate` can produce stable output when skin and guides carry rest data. [H-GUIDE-DEFORM] [H-HAIR-GENERATE]
6. **tyFlow’s generic particle Collision operator documents particle-radius collision, not segment/capsule collision.** A long binding can cross an obstacle while endpoint particles remain clear. A guide-chain workflow therefore needs short particle spacing and still requires a local crossing test. [T-COLLISION]
7. **`tyParticleSkin` is a real guide-to-mesh candidate, but not an end-to-end grass proof.** It deforms a regular mesh from a particle system or mesh and supports reference-frame capture, distance/falloff, influence count, reinitialization, and element-ID matching. The quality and isolation of a many-clump grass binding require testing. [T-PARTICLE-SKIN]
8. **tyFlow `Position Hair` is Ornatrix-specific.** It cannot be cited as generic spline/grass support. [T-POSITION-HAIR]
9. **Rigid and deforming leaves must be separate product modes.** Rigid leaves use one transform per leaf and can preserve instance sharing. Deforming leaves require vertex/guide state and become unique shapes unless approximated by reusable variants.

---

# 3. Root-position anchoring versus root-orientation stiffness

This distinction is important enough to define once before the recipes.

## 3.1 Root position

Root-position anchoring answers: **May the base of the plant move?**

Typical modes:

- **Fixed:** zero positional drift. In Houdini, a Permanent Vellum pin sets mass to zero; in tyFlow Cloth Bind, deactivated cloth particles have infinite mass. [H-VELLUM-CONSTRAINTS] [T-CLOTH-BIND]
- **Stopped/releasable:** hard position at first, but later dynamics can be restored. Houdini documents `Stopped` separately from `Permanent`. [H-VELLUM-CONSTRAINTS]
- **Soft:** the root is pulled toward its target with finite stiffness and damping. Houdini creates a zero-length distance constraint for Soft pins; tyFlow Object Bind offers linear/dynamic springs for position. [H-VELLUM-CONSTRAINTS] [T-OBJECT-BIND]

For the initial Cyrus feature, **Fixed** should be the default. A soft root is a future or advanced option because visible root drift undermines the “planted vegetation” contract.

## 3.2 Root orientation

Root-orientation stiffness answers: **May the first segment rotate at the root?**

- A fixed root position with **free orientation** allows the blade to hinge immediately at ground level.
- A **soft orientation** preserves the authored emergence direction but allows bending under contact.
- A **fixed orientation** preserves the first segment’s frame and pushes bending farther up the blade.

Houdini directly documents Orientation Pin Type as separate from Pin Type. Guide Groom also exposes `Constrain Root Orientation`. tyFlow Object Bind exposes a separate Rotation bind with Force %. [H-VELLUM-CONSTRAINTS] [H-GUIDE-GROOM] [T-OBJECT-BIND]

For Cyrus, the initial UI should not merge these into a single “root stiffness” slider. It should expose:

- Root position: `Fixed` / `Soft`;
- Root orientation: `Free` / `Soft` / `Fixed`.

---

# 4. Houdini: common asset and network contract

## 4.1 Supported source representation

For the grass workflows, use a low-resolution guide representation plus a separate visible representation:

### Guide input

- polygon curves with enough segments to bend;
- the **first vertex of each curve is the root**;
- root point group, normally named `roots`;
- stable curve identity (`id` or a piece/name attribute is recommended for a reproducible test);
- `rest` positions for stable capture/regeneration;
- `pscale` representing collision radius or half-envelope;
- `skinprim` and `skinprimuv` when roots are attached to a receiving surface;
- `orient`/`restorient` when transferring orientation through guide-based point deformation.

`Guide Utility` 22.0 can snap roots to a skin and create a roots group from the first vertex. It uses or computes `skinprim`/`skinprimuv`. [H-GUIDE-UTILITY]

### Visible input

Choose one:

1. **Dense render curves:** use `Guide Deform` or `Hair Generate` after the guide solve.
2. **Polygonal grass cards or a clump mesh:** use `Point Deform` with rest-guide points and solved-guide points as the deformation lattice. `Point Deform` documents rest/deformed lattice inputs, capture weights, piece isolation, and normal transformation. [H-POINT-DEFORM]
3. **Procedurally generated blades:** regenerate geometry from solved guides, preserving width/UV/material rules downstream.

### Obstacle input

- one or more polygon meshes merged into the Vellum Solver third input in Full mode; or
- VDB Collider output when using Vellum Minimal mode or when a VDB representation is specifically desired.

A static VDB collider is sourced once and retained, while rigid/deforming animated modes have increasing update cost. [H-VDB-COLLIDER]

## 4.2 Collision thickness

Vellum visualizes thickness from `pscale`, and its failed-collision diagnostics identify points that have been removed from collision participation. The collision radius used for the guide must represent more than the mathematical centerline if the visible blade/card has width. [H-VELLUM-SOLVER]

A reproducible test should use:

```text
pscale = requested_clearance + visible_half_width + numerical_margin
```

The numerical margin must be measured in scene units; it is not a universal constant.

## 4.3 Dense-output deformation

`Guide Deform` 22.0 offers:

- Guide Shape Interpolation;
- Guide Weights using precomputed `guides`/`weights`;
- Guide Interpolation Mesh;
- Point Deform mode;
- capture-only and deform-only operation;
- a Preserve Shape pass described as Cosserat-rod quasi-static relaxation, with stretch stiffness, bend stiffness, reference-position strength, and root locking.

The Preserve Shape pass is valuable after guide-driven deformation, but it is **not documented as an obstacle collision solve**. It should not be mistaken for the stone-contact stage. [H-GUIDE-DEFORM]

## 4.4 Initialization rule

For reliable local tests, initialize guides and colliders without unresolved penetration. If the final stone overlaps the source rest shape, use one of these clearly labelled setups:

- **P — collider ramp:** start the stone clear and animate it into the final transform over a short interval;
- **P — scale ramp:** start the collider at reduced scale and grow it to final size while preserving topology;
- **P — authored clear start:** pre-shape the guide with Guide Groom, then run a short settle.

The public Vellum documentation supports animated third-input collision geometry with matching topology, but does not prescribe one of these exact vegetation recipes. They are controlled initialization proposals. [H-VELLUM-SOLVER]

## 4.5 Cache/freeze/output rule

- Use **Reset Simulation** after a source, constraint, or collider change.
- Save the sequence with **Vellum I/O** when constraints must also be retained, or **File Cache** for ordinary geometry caching. [H-VELLUM-IO] [H-FILE-CACHE]
- Enable Load from Disk after caching.
- Use **TimeShift** to retrieve the chosen settled frame. TimeShift does not cache by itself. [H-TIME-SHIFT]
- Export rigid packed objects with Alembic instancing where possible; export unique deformed geometry as deformed shapes or USD time samples. [H-ALEMBIC] [H-USD]

---

# 5. Houdini recipe H1 — rooted grass bending around one fixed stone

**Evidence:** D + X + P.  
**Automatic fitting:** timeline simulation required.  
**Manual static alternative:** available through Guide Groom, but artist-directed.  
**Recommended Houdini version for this exact recipe:** 22.0 because the workflow uses Guide Utility and the current Guide Deform.

## 5.1 Input geometry

| Input | Required preparation |
|---|---|
| Ground/receiving surface | Polygon mesh with stable topology; correct scale and normals. |
| Sparse grass guides | Polyline curves, root first, 4–12 segments per blade/guide as a starting test range, `rest`, `pscale`, stable piece/guide ID. |
| Dense curves or grass mesh | Rest-pose visible geometry corresponding to the guide set. |
| Stone | Closed or collision-suitable polygon mesh; static final transform, plus optional animation from a clear start. |

The segment-count range is a proposed benchmark range, not a SideFX requirement. The correct count depends on length and required curvature.

## 5.2 Node order

```text
GUIDE PREP
Guide curves
  → Guide Utility
      • Snap to Skin: Root Only
      • Create Roots Group: roots
  → Attribute/Rest preparation
      • rest, pscale, id/piece
      • orient/restorient when used by mesh deformation

CONSTRAINTS
Prepared guides
  → Vellum Constraints: Hair
  → Vellum Constraints: Pin to Animation (group = roots)
      • Position Pin Type: Permanent or Soft
      • Orientation Pin Type: Free / Same as Position / Soft
  → merge geometry and constraint streams

COLLISION SOLVE
Stone (+ ground if needed)
  → optional collision cleanup/proxy
  → Vellum Solver input 3

Guide geometry + constraints
  → Vellum Solver
      • Full mode
      • gravity off or reduced for contact fitting
      • Substeps: begin at 2; raise toward 5 if contact/stretch is unstable
      • Constraint Iterations: raise for stiff/long chains
      • Collision/Post-Collision passes: raise only after checking initialization

VALIDATE AND OUTPUT
Vellum Solver result
  → Vellum Post-Process / collision visualizers
  → Guide Deform (dense curves) OR Point Deform (polygon mesh)
  → final mesh/curve collision validation
  → Vellum I/O or File Cache
  → TimeShift at accepted settled frame
  → render / Alembic / USD / bgeo
```

SideFX’s `HairOrient` example is an official loadable example for stable guide orientation outside standard grooming tools. It is useful background for the orientation path, but it is not a stone-contact example. [H-VELLUM-EXAMPLES]

## 5.3 Root controls

### Root position

- `Permanent`: hard root; `mass=0`; simplest planted behavior.
- `Soft`: finite positional stiffness and damping; use only to test a deliberately compliant soil attachment.

### Root orientation

- `None/Free`: root can hinge immediately.
- `Same as Position`: hard orientation when the positional pin is hard.
- `Soft`: separate bend/twist stiffness; recommended production reference because it preserves emergence direction without making the whole blade rigid.

Do not evaluate a workflow that only reports root translation. Record both root drift and first-segment angular drift.

## 5.4 Collision representation and settings

- Full Vellum mode: polygon stone directly in solver input 3.
- Minimal mode: must use VDB Collider; animated pins and Attach to Geometry are not supported in Minimal mode, making it a poor first choice for the complete rooted-grass test. [H-VELLUM-SOLVER]
- Guide collision thickness: `pscale` must cover blade/card envelope.
- Stone friction: begin low-to-moderate so guides can slide around the stone rather than stick unnaturally.
- Self-collision: disable for the first isolated one-stone test; add later only if clump self-contact is required.

## 5.5 Timeline versus static fitting

### Automatic result

Requires stepping the Vellum simulation from the start frame to a settled frame. It is not a one-node static fit.

### Manual static alternative

```text
Guide Groom
  → Brush / Deintersect / Sculpt with Physics
  → Lock Root
  → Constrain Root Orientation as desired
  → Damped or Settle mode
  → Set Rest State
  → Apply
```

This can produce a frozen authored shape without maintaining a simulation timeline, but the artist must paint/sculpt the result. Guide Groom documents Deintersect, Maintain Length, Lock Root, root-orientation constraint, bend/stretch stiffness, and Set Rest State. [H-GUIDE-GROOM]

## 5.6 Initialization, reset, obstacle changes, caching

| Action | Procedure |
|---|---|
| Initialize | Frame 1 must be nonintersecting, or use a proposed animated collider ramp. Confirm roots and first-segment orientation before solving. |
| Reset | Press Vellum Solver **Reset Simulation**; if cached, disable Load from Disk or increment cache version before recomputing. |
| Move stone | Update its final transform; reset; re-run from the start. If using a ramp, update the final key while preserving a clear initial key. |
| Freeze | Cache the accepted frame range, enable Load from Disk, and TimeShift to the accepted frame. |
| Render | Render cached dense curves/mesh. Keep guide visualization disabled for final output. |
| Export | Alembic/USD/bgeo. Unique deformation is exported as unique shape data; guide-only export is insufficient unless the destination reproduces the same deformation. |

## 5.7 Geometry sharing and instancing

- Sparse simulated guides are compact and can share source preprocessing.
- Once different clumps produce different guide states, those guide states are per instance.
- Dense curves generated from guides are unique at the affected locations.
- A polygon grass source deformed with Point Deform becomes unique vertex geometry for each affected instance unless the result is quantized into reusable variants.
- Unaffected grass can remain ordinary packed/instanced geometry in a hybrid network.

## 5.8 Common failure cases and remedies

| Failure | Detection | Remedy |
|---|---|---|
| Roots move | Compare root `P` to rest; inspect pin visualization | Use Permanent pin; ensure only root group is pinned; do not confuse root-position and orientation settings. |
| Root direction collapses | First segment rotates excessively | Use Soft orientation pin; raise orientation bend/twist stiffness; pin a short root zone only if justified. |
| Solver reports orange external failures | Vellum failed external collision visualization | Fix initial penetration; lower thickness; increase guide segmentation/substeps; simplify collider; do not merely raise iterations on an impossible start. |
| Guide clears stone but card penetrates | Final mesh validation | Increase guide `pscale` by visible half-width; improve guide-to-mesh binding; add final mesh collision diagnostic. |
| Stretchy blades | Segment-length error | Increase Substeps first, then Constraint Iterations and stretch stiffness. SideFX explicitly recommends 2–5 substeps as a first response to stretchiness. [H-VELLUM-SOLVER] |
| Dense hair changes unpredictably | Compare dense IDs/roots between frames | Ensure `rest` exists on skin/guides; cache guide weights; use Capture then Deform. |
| Point Deform bleeds between clumps | Visual folds between adjacent sources | Use a piece attribute and pre-separate pieces; reduce capture radius; retain stable rest/deformed correspondence. [H-POINT-DEFORM] |
| Guide interpolation fails in tangled or dissimilar shapes | Stretching/cross-influence | Use Guide Weights with authored assignments or Point Deform/tet capture; Guide Deform documents this limitation. [H-GUIDE-DEFORM] |

## 5.9 Artist preparation and major manual actions

**Prepared source already has guides:** approximately **10–12 major setup actions**.

1. bring in skin, guides, render geometry, stone;
2. create/snap roots group;
3. verify rest and thickness attributes;
4. create Hair constraints;
5. create Pin constraints;
6. set position pin;
7. set orientation pin;
8. connect collision geometry;
9. tune solver;
10. connect guide-to-render deformation;
11. cache;
12. choose/freeze/export frame.

**Unprepared arbitrary grass mesh:** add **4–10+ authoring actions** for root identification, guide creation, segmentation, piece IDs, and capture validation. Dense photogrammetry or opaque proxy sources may be unsuitable.

## 5.10 Reproducible local acceptance test

Create `H01_grass_one_stone.hip`:

- 20 identical clumps, 8 guides per clump, 8 segments per guide;
- one irregular stone;
- 10 affected clumps and 10 controls outside influence;
- hard root position, soft root orientation;
- record root drift, first-segment angular drift, length error, maximum residual guide penetration, final mesh penetration, cook time, and cached size;
- save the settled frame, reopen, verify the same guide IDs and geometry;
- render and export one frame; compare bounds and sampled vertices.

**Pass condition:** no control clump changes; roots remain within declared tolerance; no unresolved contacts in the feasible subset; viewport, render, and export agree within the declared geometric tolerance.

---

# 6. Houdini recipe H2 — rooted grass constrained between two stones

**Evidence:** D + P.  
**Automatic fitting:** timeline simulation required.  
**Core difference from H1:** all relevant obstacles must participate simultaneously, and the scene can be geometrically infeasible.

## 6.1 Node order

Use H1 unchanged, except merge both stones into the collision input:

```text
Stone_A ─┐
         ├─ Merge / collision proxy ─→ Vellum Solver input 3
Stone_B ─┘
```

If stones are animated into place for initialization, both must maintain stable topology. Move them symmetrically or in a deliberately staged order and record the choice because the final local minimum may differ.

## 6.2 Feasibility precheck

Before simulation, estimate the available gap:

```text
available_gap = minimum surface-to-surface distance
required_gap  = 2 × guide_collision_radius + visible_envelope + margin
```

If `available_gap < required_gap`, a collision-free result may be impossible without bending out of the gap, changing clearance, compressing geometry, or moving a root. The workflow must not silently delete the plant or move the root.

## 6.3 Root controls

- Root position: hard by default.
- Root orientation: start soft. A hard orientation may make a narrow-gap solve impossible even when a free hinge could escape.
- Record whether a successful solve required reducing orientation stiffness; that is a product-relevant diagnostic.

## 6.4 Important settings

- More substeps/collision passes than H1 may be necessary because the guide can alternate contacts between two surfaces.
- Increasing iterations does not make an impossible gap feasible. SideFX notes that impossible configurations leave error; smoothing can distribute error more attractively but does not satisfy incompatible constraints. [H-VELLUM-SOLVER]
- Friction should be low enough for the blade to slide out of a pinch.
- Keep collision thickness physically honest; do not “solve” the test by shrinking the blade below its visible width without reporting it.

## 6.5 Reset/change/freeze

Same as H1. Moving either stone invalidates the simulation from the start frame. Cache versioning should include both collider identities and transforms.

## 6.6 Sharing and output

Same as H1. Two-stone contact generally increases per-instance uniqueness and makes reusable bend variants less reliable because the shape depends on two distances, normals, and the route out of the gap.

## 6.7 Failure cases

| Failure | Artist-facing interpretation | Remedy/order |
|---|---|---|
| Guide remains trapped | Infeasible or local-minimum result | Lower orientation stiffness; allow more segments; initialize with staged collider motion; reduce clearance only with explicit approval. |
| Oscillation between stones | Insufficient damping/substeps or high friction | Raise substeps; add damping; lower friction; slow collider ramp. |
| Root inside either stone | Invalid input | Mark root as infeasible; do not move it automatically. Ask artist to move stone/root or permit an override. |
| Final mesh folds | Guide-to-mesh binding failure | Increase guides, reduce capture radius, use piece isolation, or reject the source. |
| Post-process detangle damages shape | Large correction required | Do not rely on detangle for primary solve; SideFX warns large independent corrections can look ugly. [H-VELLUM-POST] |

## 6.8 Artist actions

Approximately **11–13 major setup actions** with a prepared source—H1 plus adding/merging the second collider, performing a gap check, and tuning feasibility-related settings.

## 6.9 Reproducible local acceptance test

Create three two-stone gaps:

1. feasible by a wide margin;
2. just feasible at declared clearance;
3. intentionally infeasible.

The third case must end with an **unresolved/infeasible** status rather than disappearing vegetation or hidden root movement.

---

# 7. Houdini recipe H3 — rigid pebbles settling on irregular terrain

**Evidence:** D + X.  
**Simulation:** timeline Bullet solve required.  
**Purpose for Cyrus research:** demonstrates transform-only rigid settling and packed-instance preservation, not deformable vegetation.

## 7.1 Input geometry and attributes

| Input | Preparation |
|---|---|
| Pebble sources | Closed meshes; consistent scale; packed pieces; primitive/point `name` attributes kept consistent. |
| Proxy geometry | Convex hulls or simplified collision proxies. |
| Terrain | Static irregular polygon mesh or heightfield; collision-suitable scale and normals. |

The RBD Bullet Solver uses input 1 for render geometry, input 3 for proxy geometry, and input 4 for collision geometry. [H-RBD-SOLVER]

## 7.2 Node order

```text
Pebble meshes
  → Assemble / Pack / name pieces
  → RBD Configure
      • Active = on
      • Enable Sleeping = on
      • Geometry Representation = Convex Hull (default first test)
      • Density / friction / bounce / damping
      • Collision Padding + Shrink Amount
  ────────────────→ RBD Bullet Solver input 1 (render geometry)
Collision proxies ─→ RBD Bullet Solver input 3 (proxy geometry)
Terrain ───────────→ RBD Bullet Solver input 4 (collision geometry)

RBD Bullet Solver
  → simulate until sleeping
  → File Cache / RBD I/O
  → TimeShift settled frame
  → render packed pieces
  → Alembic with Use Instancing Where Possible / USD
```

Official RBD Bullet Solver examples are loadable from the node documentation, including a general `RBDBulletSolver` example. [H-RBD-EXAMPLES]

## 7.3 Collision representation

- Pebbles: Convex Hull first. It is the default and normally appropriate for rounded stones.
- Concave pebble: Compound if the concavity materially affects settling; Concave is slower and should be used only when necessary. [H-RBD-CONFIG]
- Terrain: static concave polygon collision or a suitable terrain representation.
- Padding: scale with scene units; pair with shrink so pebbles do not visibly float.

## 7.4 Important settings

- Bullet Substeps: raise if fast/small pebbles tunnel through terrain.
- Constraint Iterations: affects collision/constraint accuracy.
- Bullet World Scale: use when very small pieces behave poorly; SideFX documents this specifically. [H-RBD-SOLVER]
- Friction: high enough to stop endless sliding, low enough to allow natural settling.
- Sleeping: enabled so the accepted settled frame is stable.

## 7.5 Initialization/reset/change/freeze

- Start pebbles above terrain without overlap.
- Reset Simulation after changing terrain, source geometry, mass, hull type, or initial transforms.
- Moving terrain invalidates the solve.
- Cache the frame range; TimeShift to a frame after all relevant pebbles sleep.

## 7.6 Geometry sharing and instancing

- Packed pebbles can preserve shared source geometry and carry only unique transforms.
- Alembic can use instancing where possible for packed objects. [H-ALEMBIC]
- If every pebble is unpacked/deformed before export, sharing is lost.
- This path is directly analogous to a Cyrus rigid-settle feature and fundamentally different from per-instance grass deformation.

## 7.7 Failure cases and remedies

| Failure | Remedy |
|---|---|
| Pebbles pass through terrain | Raise Bullet Substeps; verify collision proxy and scale. |
| Pebbles float | Reduce effective padding or increase shrink; inspect collision geometry. |
| Tiny pebbles jitter/explode | Use Bullet World Scale; check mass and initial overlap. |
| Concave hull is slow | Use Convex or Compound proxy. |
| Names are lost/mismatched | Normalize `name` attribute ownership/type before solver; SideFX warns mixed point/primitive names produce bad results. |
| Simulation never settles | Increase damping/friction or sleeping thresholds; inspect constant forces/interpenetration. |

## 7.8 Artist actions

Approximately **6–8 major setup actions** after pebble and proxy assets exist.

---

# 8. Houdini recipe H4 — fallen leaves against a curb

## 8.1 H4-R: rigid leaves

**Evidence:** D + P.  
**Simulation:** timeline Bullet solve.  
**Visual model:** each leaf is an undeformed rigid plate.

### Inputs

- visible leaf mesh with UVs/material;
- finite-thickness collision proxy—thin box, convex hull, or small compound hull;
- curb and ground collision geometry.

A zero-thickness render card is not a robust rigid collision shape. The proxy may be slightly simplified but must represent leaf thickness and edge extent.

### Node order

```text
Leaf source(s)
  → Copy/pack leaves; assign stable name/source ID
  → RBD Configure
      • Active
      • Box / Convex / Compound representation
      • low mass, moderate angular damping
      • friction and restitution
  → RBD Bullet Solver
      • curb + ground on collision input
      • substeps appropriate to thin fast objects
  → cache
  → TimeShift settled frame
  → packed render / Alembic instancing / USD
```

### Sharing

Rigid leaves can reuse one or a small set of source meshes. Only transforms differ until export or materialization. This is the most efficient leaf mode.

### Failures

- Card tunnels through curb: increase thickness proxy/substeps.
- Leaf balances unnaturally on edge: improve proxy and center of mass; add damping.
- Visible gap: collision proxy is thicker than render leaf.
- Interpenetrating initial pile: spread initial transforms or solve a staged drop.

### Artist actions

Approximately **6–8 major setup actions** after source and proxy creation.

## 8.2 H4-D: deforming leaves

**Evidence:** D.  
**Simulation:** timeline Vellum Cloth solve.  
**Visual model:** the leaf can bend/fold around the curb.

### Input preparation

- leaf polygon mesh with enough subdivisions for desired curvature;
- UV/material attributes retained;
- optional `rest` state;
- finite collision thickness;
- curb and ground collider mesh.

### Node order

```text
Leaf meshes
  → Vellum Constraints: Cloth
      • high stretch stiffness
      • appropriate shear stiffness
      • moderate bend stiffness
      • thickness / friction
      • no root pins for fully fallen leaves
      • optional petiole/root group for attached leaves
  → Vellum Solver input 1/2
Curb + ground
  → Vellum Solver input 3
  → solve / validate failed collisions
  → Vellum Post-Process
  → Vellum I/O or File Cache
  → TimeShift settled frame
  → render/export unique deformed mesh
```

### Root distinction

A fully fallen leaf has no root constraint. If testing a leaf still attached by its petiole:

- position-pin the petiole point/group;
- choose orientation pin separately;
- do not treat broad-leaf bend stiffness as root orientation stiffness.

### Sharing

Each deformed leaf has unique vertex state. Ordinary transform-only instancing is lost. A future system can recover some efficiency by clustering similar final shapes into reusable variants, but exact per-leaf deformation does not preserve one shared mesh.

### Failures/remedies

- Leaf stretches: increase substeps and stretch stiffness.
- Leaf remains too flat: lower bend stiffness or increase subdivisions.
- Leaf folds sharply at coarse edges: improve topology/segmentation.
- Curb penetration: improve initialization, thickness, substeps, collision passes.
- Post-process detangle causes visible damage: reduce the amount of correction required in the primary solve.

### Artist actions

Approximately **8–10 major setup actions** per leaf class, excluding modeling/subdivision.

---

# 9. tyFlow: current documented capability boundary

## 9.1 Current host/version

The official version history lists v2.010 dated 25 May 2026. The current requirements page supports Max 2020+. [T-VERSION] [T-SYSTEM]

## 9.2 Three relevant simulation systems

1. **Particle Bind Solver:** solves inter-particle bindings created by Particle Bind, Angle Bind, and cloth conversion. It has its own step count and can use OpenCL with CPU fallback. [T-PARTICLE-BIND] [T-BIND-SOLVER] [T-SYSTEM]
2. **PhysX:** rigid-body simulation through PhysX Shape/Collision; PGS is the documented default, while TGS is described as experimental for bindings. [T-PHYSX-SHAPE] [T-PHYSX-COLLISION] [T-PHYSX]
3. **CCCS:** GPU cloth collision solver. Current requirements: NVIDIA/CUDA 11.2+, with no CPU fallback for several core algorithms. [T-SYSTEM]

Do not combine these labels into a generic claim that “tyFlow physics supports rooted grass.” Each workflow below states which subsystem is actually involved.

## 9.3 Cache/reset/output behavior

- **Auto reset:** input/settings changes can clear caches and re-simulate to the current frame.
- **Manual reset:** caches remain; critical changes freeze the simulation until refresh; non-critical changes can produce history-inconsistent results and trigger a warning. [T-RESET]
- Playback cache supports real-time timeline playback; caching subframes increases memory. [T-CACHE]
- `tyCache` modifier can preserve changing topology, animated UVs, and explicit normals, but its file format is not interchangeable with Particle Export’s tyCache format. [T-TYCACHE]
- Mesh operator `Triangle Mesh` produces editable mesh output; `Render Instances` is available for compatible renderers. Trimesh is documented as compatible with all 3ds Max renderers. [T-MESH] [T-RENDER]
- Particle Export can create scene objects or write multiple formats, including Alembic modes and tyCache. [T-EXPORT]

---

# 10. tyFlow recipe T1 — rooted grass bending around one fixed stone

There are two materially different approaches. They must not be presented as one qualified workflow.

## 10.1 T1-A — direct cloth-card/clump workflow

**Evidence:** D + P.  
**Support level:** practical for polygon grass cards/clumps; not a hair-guide workflow.  
**Simulation:** timeline required.  
**Root-position control:** documented.  
**Independent root-orientation control:** limited; not a direct documented scalar equivalent to Vellum’s Orientation Pin Type.

### 10.1.1 Input preparation

- one grass card or connected clump mesh per particle shape;
- enough subdivisions for bending;
- root faces/vertices assigned a dedicated material ID;
- UVs/material IDs preserved;
- stone and ground as scene geometry;
- finite collision thickness.

### 10.1.2 Operator order

```text
Birth Objects / Position Object / Shape
  → Cloth Bind: Shape to Cloth
      • De-activate by material ID = root strip
      • root-strip particles become infinite mass
      • Stretch stiffness: high
      • Shear stiffness: high enough to preserve card width
      • Bend stiffness: source-dependent
      • optional stiffness maps near root
      • Object collisions: on
  → Collision
      • stone + ground as colliders
      • Absolute radius = desired collision thickness
      • friction tuned for sliding
  → forces / gravity as required
  → optional CCCS for difficult cloth contact
  → settle on timeline
  → Cloth Bind: Cloth to Shape when a particle shape is needed downstream
  → Mesh operator: Triangle Mesh for universal rendering
  → playback cache / tyCache / Particle Export
```

Cloth Bind documents Shape-to-Cloth conversion, material-ID activation/deactivation, infinite mass for deactivated particles, stretch/shear/bend stiffness, and object collision through a Collision operator. Only Collision’s Absolute Radius is used as the object-collision thickness. [T-CLOTH-BIND]

### 10.1.3 Root position versus orientation

- **Position:** the deactivated root strip is hard-fixed because those particles have infinite mass.
- **Orientation:** there is no documented root-orientation pin field in Cloth Bind. Approximate orientation resistance with:
  - a short fixed root strip rather than one fixed row;
  - higher bend stiffness near the root using a texmap;
  - sufficient topology above the root.

This approximation couples root orientation to mesh topology and bend stiffness. It is not equivalent to the separate Vellum orientation pin and should be reported as a limitation.

### 10.1.4 Collision and settings

- Collision operator supports static/deforming geometry.
- Its documented collision radius is particle-based; cloth object collisions use Absolute Radius as thickness. [T-COLLISION] [T-CLOTH-BIND]
- CCCS may improve difficult cloth intersections, but requires compatible NVIDIA hardware under the current requirements.
- Start with a nonintersecting state. The CCCS FAQ recommends lower timesteps, more collision steps, and avoiding direct position edits when artifacts occur. [T-CCCS-FAQ]

### 10.1.5 Initialization/reset/change/cache

| Action | Procedure |
|---|---|
| Initialize | Place cloth clumps clear of stone or animate stone into place; root strip already fixed. |
| Reset | Auto mode reinitializes after changes; Manual mode requires explicit refresh for a history-consistent result. |
| Move stone | Refresh from the start frame. Do not continue from an old cache and call it equivalent. |
| Freeze | Keep playback cache for review; export a tyCache/Alembic or convert the accepted frame to scene geometry. |
| Render | Use Mesh Triangle Mesh for universal compatibility; verify UV/material continuity. |
| Export | Particle Export or tyCache/Alembic; the cloth shape is unique. |

### 10.1.6 Sharing and instancing

Shape sharing is lost once each grass card/clump deforms differently. Before conversion, particles may share an input shape; after cloth deformation the vertex state is per cloth element. Triangle Mesh materializes the result.

### 10.1.7 Failures and remedies

| Failure | Remedy |
|---|---|
| Root peels off | Confirm correct root material ID is deactivated and border inclusion is appropriate. |
| Root is fixed but hinges too freely | Use a deeper fixed strip or root-weighted bend map; report that orientation is topology-controlled. |
| Card stretches | Increase stretch stiffness and bind-solver steps; use Constrained stiffness mode where appropriate. |
| Stone penetrates thin card | Increase mesh subdivisions, collision thickness, solver steps, or CCCS collision steps; start nonintersecting. |
| CCCS freezes/errors | Verify current CUDA 11.2-compatible GPU/driver and DLL requirements; inspect warnings; cache accepted runs. |
| Direct reposition creates artifacts | Reinitialize rather than editing simulated particle positions mid-history; the CCCS FAQ warns against direct position edits. |

### 10.1.8 Artist preparation and steps

- Source preparation: **3–6 major actions**—subdivide, assign root material ID, verify UV/materials, create collision thickness/proxy if needed.
- Flow setup: **8–11 major operator/configuration actions**.

This is practical for card grass but not an efficient representation for thousands of independently deforming clumps.

## 10.2 T1-B — guide-chain + bindings + `tyParticleSkin`

**Evidence:** D for individual components; P + T for the complete chain.  
**Support level:** research prototype only until a Max 2027 scene proves adjacency, collision, root frame behavior, skin isolation, and export.  
**Simulation:** timeline required.

### 10.2.1 Why this route is attractive

It resembles the recommended Cyrus architecture:

- sparse guide particles;
- distance bindings for segment length;
- angle bindings for bend shape;
- independent root position and rotation binds;
- guide visualization through splines;
- high-resolution mesh deformation through `tyParticleSkin`.

The problem is that the official docs document each component, not the complete vegetation workflow.

### 10.2.2 Proposed operator order

```text
Authored guide splines
  → Birth Spline
      • Distance Along Spline or Interpolated Knots
      • Save birth index to a custom channel
  → assign each spline/strand to an isolated family/cluster/group [P/T]
  → Particle Bind
      • create only adjacent-chain distance binds [P/T]
      • constrained stiffness
      • rest/min/max length limits as required
  → Angle Bind
      • applied after regular binds
      • maintain local angular offset
  → select root particles [P/T]
  → Object Bind (Position)
      • Lock to surface / ground
      • hard or spring position behavior
  → Object Bind (Rotation), separate operator/stage
      • Force % controls orientation resistance
  → Collision
      • stone + ground
      • Absolute radius
  → Particle Bind Solver
      • timestep and bind steps tuned
  → Spline Paths
      • export bindings/relationships to tySplines for inspection
  → tyParticleSkin on the visible grass mesh
      • Ref frame = initialization frame
      • element-ID matching where multiple clumps share one object
      • distance/falloff/max count
      • Re-initialize after topology/reference changes
  → cache/render/export
```

Documented facts behind the proposal:

- Birth Spline can distribute particles by distance/knots and save the source-spline birth index. [T-BIRTH-SPLINE]
- Particle Bind creates persistent binds solved by the global bind solver. [T-PARTICLE-BIND]
- Angle Bind works on adjacent existing binds and must be applied after regular binds. [T-ANGLE-BIND]
- Object Bind independently binds Position and Rotation; Rotation has a Force %. [T-OBJECT-BIND]
- Spline Paths can convert bindings/relationships into splines. [T-SPLINE-PATHS]
- `tyParticleSkin` deforms a regular mesh from a particle system or mesh and supports reference-frame capture and element matching. [T-PARTICLE-SKIN]

### 10.2.3 Unresolved points that require a local test

1. **Adjacent-chain construction:** Birth Spline gives particles and a spline index, but the docs do not provide a complete operator-only recipe that guarantees binds only between sequential particles on each spline. Family/cluster assignment and nearest-neighbor settings must be proven.
2. **Segment collision:** Collision is documented in terms of particle radii. A long bound segment can cross a stone between clear endpoints. The test must include the “endpoints outside, segment crosses” case.
3. **Root orientation:** Binding the rotation of a root particle may not by itself create the intended first-segment frame. The test must compare one root particle versus a two-particle root frame.
4. **Skin bleed:** `tyParticleSkin` may capture vertices to nearby particles from another clump. Element-ID matching, reference frame, influence distance, and particle mesh consideration must be qualified.
5. **Topology changes:** after guide count/topology changes, `tyParticleSkin` must be explicitly reinitialized.
6. **Performance:** no capacity claim is justified for many clumps.

### 10.2.4 Collision limitation

Because Collision uses particle radius rather than a documented segment/capsule shape, a conservative test should keep guide particle spacing below the smallest collider feature that must not be crossed. Even then, the workflow remains an approximation until the crossing fixture passes.

### 10.2.5 `Position Hair` exclusion

`Position Hair` positions particles on **Ornatrix** hair strands. It is not evidence that arbitrary grass splines can be imported and solved as generic hair. [T-POSITION-HAIR]

### 10.2.6 Artist effort

Approximately **11–14 major setup actions**, plus the creation of guide splines and a `tyParticleSkin` modifier. Because multiple steps remain unqualified, this is not recommended as the production reference until the local test passes.

---

# 11. tyFlow recipe T2 — grass constrained between two stones

## 11.1 Direct cloth-card workflow

**Evidence:** D + P.  
Use T1-A with both stones in the Collision object list.

### Required additions

- evaluate the available gap against card thickness and collision radius;
- use lower friction if the card must slide out of a pinch;
- raise timestep resolution/collision steps before raising stiffness indefinitely;
- keep root material-ID anchoring unchanged;
- report unresolved contact if the gap is smaller than the card envelope.

### Initialization

Start with stones clear or with the cloth outside both stones. A staged inward motion is more reproducible than starting deeply intersecting.

### Failure policy

- Do not reduce the root fixed region automatically.
- Do not change collision thickness silently.
- Do not accept a result where the cloth exits through the stone between frames without recording tunneling.
- A visually compressed card may technically satisfy particle collision but be unacceptable as grass.

## 11.2 Guide-chain workflow

**Evidence:** P + T.  
Use T1-B, add the second collider, and add the following test gates:

- segment-crossing test against each stone;
- narrow-gap feasibility test;
- bind-order independence/stability test;
- root-position and root-rotation drift test;
- `tyParticleSkin` fold/inversion test.

The two-stone case is the decisive qualification scene for the proposed guide-chain route. If the chain can only succeed by using extremely dense particles or many bind steps, it is not a good reference architecture for Cyrus.

## 11.3 Artist actions

- Cloth-card: **9–12 major flow actions** plus source preparation.
- Guide-chain: **12–15 major actions** plus guides/skin setup and local debugging.

---

# 12. tyFlow recipe T3 — rigid pebbles settling on irregular terrain

**Evidence:** D.  
**Simulation:** timeline PhysX solve.  
**Recommended solver:** PGS first; TGS is documented as experimental when bindings are involved. [T-PHYSX]

## 12.1 Inputs

- pebble source shapes assigned to particles;
- terrain mesh;
- optional low-resolution pebble collision shapes;
- correct scene scale and nonintersecting initial transforms.

## 12.2 Operator order

```text
Birth Objects / Position Object
  → Shape (assign pebble source mesh)
  → PhysX Shape
      • Hull: Convex Hull for rounded pebbles
      • Compound for materially concave dynamic stones
      • mass / density
      • static + dynamic friction
      • restitution
      • damping and sleep-related behavior
  → PhysX Collision
      • terrain collider
      • Mesh for static detailed terrain, or SDF when justified
      • collider friction/restitution
  → Global PhysX settings
      • PGS default
      • gravity
      • simulation steps/substeps
  → Mesh
      • Render Instances for compatible renderer
      • Triangle Mesh for universal renderer path
  → playback cache / Particle Export / tyCache
```

## 12.3 Collision-shape rules

- PhysX Shape documents Box, Compound, Convex Hull, Mesh, SDF, and Sphere.
- Dynamic Mesh hulls are not supported; particles using Mesh hull are set kinematic. Use Compound for dynamic concave bodies. [T-PHYSX-SHAPE]
- SDF collision is most accurate for SDF-to-SDF. Mixed SDF/other hull pairs fall back to less-accurate mesh procedures, and SDF generation can be slow. [T-PHYSX-SHAPE] [T-PHYSX-COLLISION]
- Terrain is static, so Mesh is a reasonable first reference. Use SDF only after measuring contact and preprocessing cost.

## 12.4 Initialization/reset/change/cache

| Action | Procedure |
|---|---|
| Initialize | Spawn pebbles above terrain with no overlap; ensure shape is assigned before PhysX Shape. |
| Reset | Auto mode re-simulates after input changes; Manual mode requires refresh for consistent history. |
| Change terrain | Full refresh from start; collider hull/SDF may need rebuilding. |
| Freeze | Use playback cache for review; export accepted frames to tyCache/Alembic or scene objects. |
| Render | Prefer Render Instances where renderer support is verified; use Triangle Mesh as universal fallback. |
| Export | Particle Export can create scene objects or save supported formats. |

## 12.5 Sharing and instancing

- Particles can share source shape meshes and differ only by transform.
- Mesh `Render Instances` preserves this efficiency for compatible renderers.
- Triangle Mesh combines shapes into editable geometry and loses ordinary object-level instance sharing.
- Exporting scene objects can preserve references only if the export mode/target supports it; validate per output format.

## 12.6 Failures and documented remedies

| Failure | Remedy |
|---|---|
| Dynamic pebble becomes kinematic | Do not use Mesh hull; use Convex or Compound. |
| Concavity is ignored | Use Compound or SDF/SDF pair; inspect displayed hull. |
| SDF is slow/heavy | Increase cell size, use simpler proxy, or return to convex/compound. |
| Pebbles tunnel | Increase simulation time resolution; check scale and collider shape. |
| Pebbles never sleep | Increase damping/friction, remove constant forces, inspect penetrations. |
| Render differs from viewport | Use Triangle Mesh control path, then qualify renderer-specific instance mode. |

## 12.7 Artist actions

Approximately **6–8 major flow actions** after source meshes exist.

---

# 13. tyFlow recipe T4 — fallen leaves against a curb

## 13.1 T4-R: rigid leaves

**Evidence:** D + P.  
**Simulation:** PhysX timeline solve.

### Input preparation

- visible leaf card/mesh;
- finite-thickness collision proxy represented by Box, Convex, or Compound;
- curb and ground mesh colliders;
- mass, friction, damping tuned for light rigid plates.

### Operator order

```text
Birth Objects / Position Object
  → Shape
  → PhysX Shape
      • Box / Convex / Compound
      • low mass
      • angular damping
      • friction/restitution
  → PhysX Collision
      • curb + ground
  → Global PhysX (PGS first)
  → Mesh: Render Instances or Triangle Mesh
  → cache/export
```

### Sharing

Rigid leaves preserve source sharing until a Triangle Mesh or unique scene geometry is created.

### Failures

- zero-thickness cards tunnel or sit edge-on: use finite-thickness proxy;
- visible floating: proxy too thick;
- excessive spinning: increase angular damping and adjust mass/inertia via a more representative hull;
- kinematic behavior: avoid dynamic Mesh hull.

### Artist actions

Approximately **6–8 major flow actions**, plus proxy preparation.

## 13.2 T4-D: deforming leaves

**Evidence:** D + X + P.  
**Simulation:** Particle Bind/cloth timeline solve; optional CCCS.  
**Official example reference:** `tyFlow_cloth_CCCS_papers_001.max` is listed as an example of CCCS preventing cloth intersections with sharp colliders. It was not executed here. [T-EXAMPLE-SCENES]

### Input preparation

- subdivided leaf mesh with UVs/materials;
- curb and ground colliders;
- optional material ID for a petiole/root region if testing attached leaves;
- nonintersecting initial placement.

### Operator order

```text
Birth Objects / Shape
  → Cloth Bind: Shape to Cloth
      • fallen leaf: Activate all
      • attached leaf: De-activate petiole/root material ID
      • high stretch and shear stiffness
      • moderate bend stiffness
      • thickness and friction
      • object collisions enabled
  → Collision
      • curb + ground
      • Absolute radius defines collider thickness used by cloth
  → optional CCCS
      • only on qualified NVIDIA/CUDA system
  → settle
  → Cloth Bind: Cloth to Shape if required downstream
  → Mesh: Triangle Mesh
  → playback cache / tyCache / Particle Export
```

### Root distinction

- Fully fallen leaf: no root position or orientation constraint.
- Attached petiole:
  - root position can be made hard by deactivating the petiole vertices;
  - root orientation is not a separate Cloth Bind control. Approximate with a fixed strip and root-zone bend stiffness, or build a separate binding rig and qualify it as a proposed extension.

### Important settings

- Stretch/shear high enough to preserve leaf area.
- Bend low enough to fold at the curb but high enough to avoid cloth-like collapse.
- Absolute collision radius consistent with visible thickness.
- CCCS collision steps/time step tuned conservatively.

### CCCS failure remedies from documentation

- lower simulation timestep—often to 1/4 frame or smaller for difficult cases;
- begin without intersections;
- increase maximum collision steps;
- avoid direct position changes that bypass solver history;
- inspect warnings in the MAXScript Listener;
- cache accepted simulations because GPU collision results should not be assumed reproducible across all hardware/settings without testing. [T-CCCS-FAQ]

### Sharing

Each deforming leaf produces unique vertex state. Render Instances is no longer the natural representation unless the simulation is baked into a small reusable variant library.

### Artist actions

Approximately **8–11 major flow actions**, excluding mesh subdivision and root material setup.

---

# 14. Guide collision and guide-to-mesh deformation: direct comparison

## 14.1 Houdini

### Guide collision

- Curves are first-class Vellum Hair geometry.
- Position and orientation pins are explicit and separate.
- External collision comes through the solver’s collision input; thickness is visible/debuggable.
- Failed external collision points are visualized in orange.
- Official HairOrient and DynamicAttach examples provide inspectable reference networks, though not the exact stone scene. [H-VELLUM-EXAMPLES]

### Guide-to-visible deformation

- Guide Deform/Hair Generate for dense curves.
- Point Deform for arbitrary mesh driven by rest/deformed guide lattices.
- Piece attributes can isolate clumps.
- Capture can be separated from deform for caching and repeatability.
- Guide Deform’s Preserve Shape can repair stretch/bend after guide interpolation but does not replace contact collision.

## 14.2 tyFlow

### Guide collision

- Particle Bind + Angle Bind can create a chain-like constrained particle structure.
- Object Bind separates position and rotation constraints.
- Collision is documented as particle versus scene geometry using particle radius.
- No current official page inspected documents segment/capsule collision for generic bind chains.

### Guide-to-visible deformation

- `tyParticleSkin` can deform a regular mesh from particles or another mesh.
- It captures at a reference frame, uses distance/falloff/max influence count, and can match element IDs.
- It must be reinitialized after binding/topology/reference changes.
- The complete grass guide-chain workflow remains P/T because adjacency, root frame, collision crossing, and clump isolation are not documented as one solution.

## 14.3 Product lesson for Cyrus

A Cyrus implementation should not copy either DCC graph literally. It should preserve the useful contract:

```text
stable placement
  + source-level prepared guides/binding
  + separate root position/orientation constraints
  + segment/capsule obstacle contact
  + validation
  → sparse per-instance deformation
  → dense viewport/render/Bake representation
```

The DCC studies strengthen the previous recommendation to make guide state sparse and final-mesh validation explicit.

---

# 15. Initialization, reset, caching, rendering, and export matrix

| Application/workflow | Initialization | Change obstacle | Reset | Freeze/cache | Render | Export |
|---|---|---|---|---|---|---|
| Houdini Vellum grass | Nonintersecting guides/collider or proposed collider ramp | Reset from start; preserve topology | Vellum Reset Simulation | Vellum I/O or File Cache; TimeShift accepted frame | Dense curves/Point-Deformed mesh | Alembic/USD/bgeo; unique deformed shape |
| Houdini Bullet pebbles/rigid leaves | Packed pieces above collider | Reset from start | RBD Reset Simulation | File Cache/RBD I/O; TimeShift | Packed render geometry | Alembic instancing where possible/USD |
| Houdini Vellum deforming leaves | Nonintersecting subdivided leaves | Reset from start | Vellum Reset Simulation | Vellum I/O/File Cache | Deformed mesh | Alembic/USD unique mesh |
| tyFlow cloth grass/deforming leaves | Nonintersecting cloth, root material set | Auto re-sim or Manual refresh | Auto/Manual refresh rules | Playback cache; tyCache/Particle Export | Triangle Mesh universal; renderer-specific modes only after test | tyCache/Alembic/scene objects |
| tyFlow proposed guide chain | Guides and capture initialized at reference frame | Full refresh + reinitialize skin if needed | Manual/Auto reset plus `tyParticleSkin` Re-initialize | Playback cache/Particle Export | `tyParticleSkin` mesh | Materialized mesh/cache; guide splines alone are insufficient |
| tyFlow PhysX pebbles/rigid leaves | Nonoverlapping particles with valid shape | Full refresh; rebuild hull/SDF if required | Auto/Manual refresh | Playback cache/Particle Export | Render Instances or Triangle Mesh | Scene objects/tyCache/Alembic |

---

# 16. Geometry sharing and instancing consequences

## 16.1 Transform-only rigid results

Pebbles and rigid leaves are the favorable case:

```text
shared source mesh + per-instance transform
```

Both Houdini packed RBD and tyFlow PhysX can retain this representation through most of the pipeline. Renderer/export decisions determine whether sharing survives final output.

## 16.2 Guide-deformed grass

Exact deformation introduces per-instance guide state. Three representations are possible:

1. **Sparse guide state + shader/procedural deformation:** best sharing, highest renderer integration burden.
2. **Sparse guide state + CPU-materialized affected mesh:** easiest correctness path, higher memory and upload cost.
3. **Quantized reusable variants:** middle ground; approximation and cache-management risk.

Houdini’s guide pipeline demonstrates the value of simulating sparse guides before generating dense output, but its exported deformed geometry is still unique where the shapes differ.

## 16.3 Cloth leaves/cards

Cloth directly produces per-vertex state. Transform-only instancing is lost unless the final shapes are clustered into reusable variants. Triangle Mesh and ordinary geometry cache output materialize the unique state.

## 16.4 Practical Cyrus implication

For a first Cyrus prototype:

- unaffected instances stay on the current transform-only path;
- affected instances receive sparse deformation records keyed by stable placement ID;
- viewport/render/Bake qualification may initially materialize only affected geometry;
- memory and upload counters must distinguish guide state from expanded mesh state.

---

# 17. Common failure taxonomy across both applications

| Category | Example | Detection | Correct response |
|---|---|---|---|
| Invalid root | Root lies inside stone | point-in-solid/closest-distance test | Mark invalid; preserve root and previous result; request artist correction. |
| Infeasible gap | Two stones narrower than visible envelope | gap/clearance precheck + residual contact | Mark infeasible; do not delete or move root. |
| Under-segmented source | Card/guide forms one sharp hinge | curvature and segment-count check | Request more segments/guides; do not hide with smoothing alone. |
| Collision discretization | endpoints outside but segment crosses obstacle | segment/capsule test | Reject point-only workflow or increase sampling; Cyrus should use segment/capsule contact. |
| Initial penetration | solver immediately reports failed contacts | start-frame overlap diagnostics | use clear start/ramp; do not treat iteration count as cure. |
| Binding bleed | one clump influenced by neighboring guide | piece/element ID audit | isolate pieces, reduce capture radius, or reject source. |
| Visible-envelope mismatch | guide clears but card/leaf penetrates | final-mesh collision validation | increase guide radius or improve binding. |
| Cache staleness | obstacle moved but old result shown | dependency revision mismatch | show Pending/Stale; preserve old complete result until explicit update. |
| Renderer divergence | viewport differs from render/export | sampled geometry/bounds comparison | use materialized control path; block unsupported output mode. |
| Budget/iteration limit | solver stops with residual penetration | residual count/depth and iteration flag | label partial/unresolved; never call it successful solely because computation ended. |

---

# 18. Artist preparation and manual-step comparison

Counts below are **major authoring actions**, not mouse clicks. Modeling an asset from scratch is excluded but required metadata/preparation is listed separately.

| Workflow | Source prep | Network/flow setup | Cache/output | Typical major actions | Evidence confidence |
|---|---:|---:|---:|---:|---|
| Houdini grass, one stone | 3–8 | 7–9 | 2 | 10–19 | High for nodes; medium for exact vegetation tuning |
| Houdini grass, two stones | 3–8 | 8–10 | 2 | 11–20 | High/medium |
| Houdini pebbles | 2–4 | 4–5 | 2 | 6–11 | High |
| Houdini rigid leaves | 2–4 | 4–5 | 2 | 6–11 | High/medium |
| Houdini deforming leaves | 3–5 | 6–8 | 2 | 8–15 | High |
| tyFlow cloth grass, one stone | 3–6 | 6–8 | 2–3 | 8–17 | Medium-high |
| tyFlow cloth grass, two stones | 3–6 | 7–9 | 2–3 | 9–18 | Medium |
| tyFlow guide chain + skin | 5–10 | 9–12 | 2–3 | 11–25 | Low until test |
| tyFlow pebbles | 2–3 | 4–6 | 2 | 6–11 | High |
| tyFlow rigid leaves | 2–4 | 4–6 | 2 | 6–12 | High/medium |
| tyFlow deforming leaves | 3–5 | 6–9 | 2–3 | 8–17 | High for cloth components; medium for leaf tuning |

The largest recurring preparation cost is not “adding a physics node.” It is defining roots, creating adequate segmentation/guides, choosing a collision envelope, and proving how sparse deformation reaches the final render mesh.

---

# 19. Required local validation scenes

## 19.1 Houdini 22.0 package

Create:

- `H01_grass_one_stone.hip`
- `H02_grass_two_stones.hip`
- `H03_pebbles_terrain.hip`
- `H04a_leaves_rigid.hip`
- `H04b_leaves_cloth.hip`

Each file must include:

- a `README` sticky note with exact node versions and units;
- source, guide, collider, and output nulls;
- a parameter preset with baseline solver settings;
- diagnostic geometry for roots, guide thickness, failed contacts, and final mesh collision;
- a File Cache/Vellum I/O path using a relative project directory;
- a frozen accepted frame;
- Alembic/USD export nodes where relevant.

## 19.2 tyFlow 2.010 / Max 2027 package

Create:

- `T01a_grass_cloth_one_stone.max`
- `T01b_grass_guides_skin_one_stone.max`
- `T02a_grass_cloth_two_stones.max`
- `T02b_grass_guides_skin_two_stones.max`
- `T03_pebbles_terrain.max`
- `T04a_leaves_rigid.max`
- `T04b_leaves_cloth.max`

The guide-chain scenes are qualification experiments, not assumed supported workflows.

## 19.3 Measurements common to both applications

Record:

- software/build number, Max/Houdini version, CPU/GPU/driver;
- scene units;
- guide/vertex/particle/triangle counts;
- collider representation and preprocessing time;
- root positional drift;
- root first-segment angular drift;
- segment-length/stretch error;
- residual penetration depth and count for guides and visible mesh;
- settled frame and total solve time;
- peak RAM/VRAM where observable;
- cache size;
- viewport/render/export agreement;
- reset/recompute behavior after moving one stone by a known transform.

## 19.4 Specific decision rules

- **Houdini guide workflow passes** if sparse guides remain stable, dense deformation stays in the correct clump, and the final mesh passes collision tolerance.
- **tyFlow cloth-card workflow passes** if hard roots remain fixed and the result is visually acceptable without impractical subdivisions/solver steps.
- **tyFlow guide-chain workflow passes** only if:
  1. chain adjacency is deterministic per spline;
  2. the segment-crossing fixture does not penetrate;
  3. root position and orientation can be tuned independently in practice;
  4. `tyParticleSkin` does not bleed between clumps;
  5. reset/reinitialize/cache/export is reproducible.
- **Rigid workflows pass** if packed/instance sharing survives the intended render/export path and collision proxies do not create visible float or tunneling.

---

# 20. Proposed Cyrus artist workflow

The DCC workflows suggest a small, explicit Cyrus workflow rather than exposing a general simulation graph.

## 20.1 What the artist selects

1. Select a **vegetation Scatter layer**.
2. Enable **Vegetation Contact Fit**.
3. Pick one or more obstacle bindings:
   - ordinary scene objects;
   - explicitly ordered obstacle Scatter layers.
4. For each source model, choose or validate its preparation profile:
   - Auto root from pivot/local height **only when the asset contract passes**;
   - authored root group and guide set;
   - visible-mesh binding to guides;
   - collision envelope.

## 20.2 Controls the artist needs

### Layer controls

- Enable Interaction
- Obstacles
- Influence Distance
- Quality / Work Budget
- Manual / Live
- Update / Fit
- Reset Deformation
- Show Affected
- Show Guides
- Show Unresolved Contacts

### Source controls

- Root definition
- Guide definition / segment density
- Root Position: `Fixed` / `Soft`
- Root Orientation: `Free` / `Soft` / `Fixed`
- Bend Stiffness / Flexibility
- Shape Preservation
- Collision Thickness / Clearance
- Maximum Bend
- Binding mode and validation status

### Obstacle-binding controls

- enabled/disabled;
- collision proxy choice if available;
- clearance override;
- priority/direction when binding to another Scatter layer;
- diagnostic display.

Do not expose substeps, solver iterations, compliance formulas, or internal tolerances as primary artist controls unless testing proves they solve a meaningful artistic decision. Quality/Work Budget should map to bounded internal settings.

## 20.3 What Update does

```text
1. Host thread snapshots:
   accepted placements + stable IDs
   source/preparation revisions
   obstacle geometry/transforms
   authored interaction settings

2. Native worker stage:
   select affected instances
   reuse source guide/binding preprocessing
   build/query obstacle acceleration
   solve static root-preserving fit
   deform/validate visible envelope
   collect diagnostics and cost counters

3. Validation:
   root drift
   orientation drift
   length/stretch error
   residual penetration
   maximum bend
   budget/iteration status
   final mesh/bounds validity

4. Publication:
   if complete and current, atomically publish successor
   if cancelled/stale/failed, keep prior complete result
```

Unlike Houdini Vellum and tyFlow, the initial Cyrus feature should not require the artist to choose a start frame, play a timeline, or select a settled frame. The DCC workflows are evidence for the asset and control contract; Cyrus should compute the bounded static result directly.

## 20.4 How failures appear

Use explicit categories, not a single red “failed” label:

- **Orange — residual contact:** solve completed but penetration exceeds tolerance.
- **Magenta — invalid/infeasible:** root inside obstacle, impossible gap, or max bend/length contract cannot be satisfied.
- **Yellow — budget-limited:** work/iteration/memory budget ended before quality target.
- **Blue — stale/pending:** an obstacle or source changed; previous complete result remains visible until Update.
- **Gray — unsupported source:** missing guides/root/binding, opaque proxy, or insufficient segmentation.

The artist should be able to isolate affected instances and unresolved guides in the viewport. Cyrus must distinguish **computation completed** from **contact quality achieved**.

## 20.5 What happens after moving a stone

### Manual mode

1. Keep the previous complete deformation visible.
2. Mark the layer **Pending: obstacle changed**.
3. Do not recompute while the artist continues moving the stone.
4. On Update, recompute only instances whose influence/contact region or obstacle dependency changed.
5. Publish atomically if successful.
6. If the new configuration is infeasible or fails, retain the old complete result and overlay diagnostics; do not silently show a half-built successor.

### Live mode

1. Relevant obstacle transform/geometry revision schedules a bounded recompute.
2. Coalesce rapid edits and cancel stale jobs.
3. Camera motion, selection changes, unrelated animation, and browsing do not invalidate the fit.
4. Publish only a complete result whose dependency revisions still match.

### Removed obstacle

Recompute affected instances toward their source rest shape while preserving placement IDs. Reset does not regenerate scatter distribution.

### Source edit

Guide topology, root metadata, rest mesh, or binding changes invalidate source preprocessing and all dependent deformation. A material-only change should not invalidate geometry unless it changes opacity-derived visible envelope or collision contract.

---

# 21. Direct answers

## Which application offers the strongest reference for Cyrus grass interaction?

**Houdini 22.0.** It has the clearest documented chain from roots and hair constraints, through separate root-position/orientation pins and external collision, to sparse-guide deformation of dense output, caching, diagnostics, and export.

## Is tyFlow still useful to study?

Yes. Its rigid-body and cloth-card workflows are practical references for Max-side artist expectations, reset/cache behavior, renderer output, and collision-shape choices. Its generic guide-chain + `tyParticleSkin` path is a valuable experiment, not yet a qualified reference.

## Does either application prove that Cyrus needs timeline physics?

No. They show how general-purpose DCCs expose simulation. The earlier Cyrus recommendation remains stronger: implement a bounded static fit for the first release. The DCC study informs controls, asset preparation, validation, and output—not the requirement to copy a timeline solver.

## What preparation is unavoidable?

For deformable grass: root definition, sufficient guide/mesh segmentation, stable rest state, collision envelope, and guide-to-visible binding. Arbitrary unprepared meshes cannot be assumed to produce meaningful rooted bending.

## What should be copied into Cyrus?

- separate root position and root orientation;
- sparse guides before dense output;
- explicit collision thickness;
- final visible-geometry validation;
- clear reset/stale state;
- cache/reuse of source preprocessing;
- unresolved-contact diagnostics;
- transform-only sharing for unaffected/rigid instances.

## What should not be copied?

- a visible general-purpose node graph;
- mandatory timeline playback for a static archviz fit;
- point-only guide collision;
- silent auto-reset during every edit in Manual mode;
- a claim that a completed solve is necessarily a successful contact fit;
- renderer-specific output without a materialized universal control path.

---

# 22. Official source map

| Key | Official source | What it establishes |
|---|---|---|
| H-GUIDE-UTILITY | SideFX Guide Utility, Houdini 22.0 | Root is first curve vertex; roots group; skinprim/skinprimuv; since 22.0. |
| H-GUIDE-DEFORM | SideFX Guide Deform, Houdini 22.0 | Guide interpolation/capture, Point Deform mode, Preserve Shape quasi-static pass; since 22.0. |
| H-HAIR-GENERATE | SideFX Hair Generate 2.0 | Dense hair from guides; stable output with rest attributes. |
| H-VELLUM-CONSTRAINTS | SideFX Vellum Constraints | Position Pin Type and separate Orientation Pin Type. |
| H-VELLUM-SOLVER | SideFX Vellum Solver | Dynamic solve, collision input, reset, Full/Minimal limits, substeps/iterations, diagnostics. |
| H-GUIDE-GROOM | SideFX Guide Groom | Manual sculpt/deintersect, physics brush, root lock/orientation, Set Rest State. |
| H-VELLUM-POST | SideFX Vellum Post-Process | Collision correction and failed-collision visualization; detangle limitation. |
| H-VELLUM-IO | SideFX Vellum I/O 2.0 | Save/load geometry and optional constraints. |
| H-FILE-CACHE | SideFX File Cache 2.0 | Write once/read from disk workflow. |
| H-TIME-SHIFT | SideFX TimeShift | Retrieve a specific frame; not itself a cache. |
| H-VDB-COLLIDER | SideFX VDB Collider 1.0 | Static/rigid/deforming VDB collider modes; since 20.5. |
| H-POINT-DEFORM | SideFX Point Deform | Rest/deformed lattice, piece isolation, capture/deform, normals/attributes. |
| H-RBD-CONFIG | SideFX RBD Configure | Bullet collision representations, padding/shrink, sleeping. |
| H-RBD-SOLVER | SideFX RBD Bullet Solver | Input contract, proxy/collision geometry, reset, substeps/world scale. |
| H-ALEMBIC | SideFX Alembic ROP | Packed transforms and Use Instancing Where Possible. |
| H-USD | SideFX USD ROP | USD file and animation output. |
| H-VELLUM-EXAMPLES | SideFX Vellum Solver examples | HairOrient, DynamicAttach and other loadable examples. |
| H-RBD-EXAMPLES | SideFX RBD Bullet Solver examples | General loadable Bullet examples. |
| T-VERSION | tyFlow Version History | v2.010 dated 25 May 2026. |
| T-SYSTEM | tyFlow System Requirements | Max 2020+; CPU/GPU fallbacks; current CCCS CUDA requirement. |
| T-BIRTH-SPLINE | tyFlow Birth Spline | Particle birth along curves and source-spline index channel. |
| T-OBJECT-BIND | tyFlow Object Bind | Independent Position/Rotation/Scale binds and rotation Force %. |
| T-PARTICLE-BIND | tyFlow Particle Bind | Persistent inter-particle binds solved globally. |
| T-ANGLE-BIND | tyFlow Angle Bind | Angular constraint between adjacent existing binds. |
| T-BIND-SOLVER | tyFlow Particle Bind Solver | Global bind solver and step tuning. |
| T-COLLISION | tyFlow Collision | Particle radius against static/deforming scene geometry. |
| T-SPLINE-PATHS | tyFlow Spline Paths | Convert trajectories/bindings/relationships to splines. |
| T-PARTICLE-SKIN | tyFlow tyParticleSkin | Deform regular mesh from particles/mesh; capture and element matching. |
| T-POSITION-HAIR | tyFlow Position Hair | Ornatrix-specific hair positioning. |
| T-CLOTH-BIND | tyFlow Cloth Bind | Shape/cloth conversion, infinite-mass deactivated particles, cloth stiffness, object collision. |
| T-CCCS | tyFlow CCCS | Global CUDA cloth collision settings. |
| T-CCCS-FAQ | tyFlow CCCS FAQ | Troubleshooting; contains older CUDA 10.0 wording. |
| T-PHYSX-SHAPE | tyFlow PhysX Shape | Dynamic rigid bodies and collision hull choices/limitations. |
| T-PHYSX-COLLISION | tyFlow PhysX Collision | Static collider hull choices and SDF behavior. |
| T-PHYSX | tyFlow PhysX rollout | PGS/TGS guidance and global world settings. |
| T-RESET | tyFlow Reset FAQ | Auto/manual reset and consistency warning behavior. |
| T-CACHE | tyFlow Cache | Playback cache and subframe memory. |
| T-TYCACHE | tyFlow tyCache modifier | Changing-topology cache and format non-interchangeability. |
| T-EXPORT | tyFlow Particle Export | Scene-object and file-format export. |
| T-MESH | tyFlow Mesh operator | Triangle Mesh and Render Instances modes. |
| T-RENDER | tyFlow Rendering FAQ | Trimesh universal renderer compatibility. |
| T-EXAMPLE-SCENES | tyFlow Version History example list | Named CCCS example scenes, including papers against sharp colliders. |

---

# Reference links

[H-GUIDE-UTILITY]: https://www.sidefx.com/docs/houdini/nodes/sop/guideutility.html
[H-GUIDE-DEFORM]: https://www.sidefx.com/docs/houdini/nodes/sop/guidedeform.html
[H-HAIR-GENERATE]: https://www.sidefx.com/docs/houdini/nodes/sop/hairgen.html
[H-VELLUM-CONSTRAINTS]: https://www.sidefx.com/docs/houdini/nodes/sop/vellumconstraints.html
[H-VELLUM-SOLVER]: https://www.sidefx.com/docs/houdini/nodes/sop/vellumsolver.html
[H-GUIDE-GROOM]: https://www.sidefx.com/docs/houdini/nodes/sop/guidegroom.html
[H-VELLUM-POST]: https://www.sidefx.com/docs/houdini/nodes/sop/vellumpostprocess.html
[H-VELLUM-IO]: https://www.sidefx.com/docs/houdini/nodes/sop/vellumio.html
[H-FILE-CACHE]: https://www.sidefx.com/docs/houdini/nodes/sop/filecache.html
[H-TIME-SHIFT]: https://www.sidefx.com/docs/houdini/nodes/sop/timeshift.html
[H-VDB-COLLIDER]: https://www.sidefx.com/docs/houdini/nodes/sop/vdbcollider.html
[H-POINT-DEFORM]: https://www.sidefx.com/docs/houdini/nodes/sop/pointdeform.html
[H-RBD-CONFIG]: https://www.sidefx.com/docs/houdini/nodes/sop/rbdconfigure.html
[H-RBD-SOLVER]: https://www.sidefx.com/docs/houdini/nodes/sop/rbdbulletsolver.html
[H-ALEMBIC]: https://www.sidefx.com/docs/houdini/nodes/out/alembic.html
[H-USD]: https://www.sidefx.com/docs/houdini/nodes/out/usd.html
[H-VELLUM-EXAMPLES]: https://www.sidefx.com/docs/houdini/nodes/sop/vellumsolver.html#examples
[H-RBD-EXAMPLES]: https://www.sidefx.com/docs/houdini/nodes/sop/rbdbulletsolver.html#examples

[T-VERSION]: https://docs.tyflow.com/download/version/
[T-SYSTEM]: https://docs.tyflow.com/download/system_requirements/
[T-BIRTH-SPLINE]: https://docs.tyflow.com/tyflow_operators/particles/birth_spline/
[T-OBJECT-BIND]: https://docs.tyflow.com/tyflow_operators/particles/object_bind/
[T-PARTICLE-BIND]: https://docs.tyflow.com/tyflow_operators/particles/particle_bind/
[T-ANGLE-BIND]: https://docs.tyflow.com/tyflow_operators/particles/angle_bind/
[T-BIND-SOLVER]: https://docs.tyflow.com/tyflow_objects/tyFlow/particleBindSolver/
[T-COLLISION]: https://docs.tyflow.com/tyflow_operators/particles/collisions/
[T-SPLINE-PATHS]: https://docs.tyflow.com/tyflow_operators/particles/spline_paths/
[T-PARTICLE-SKIN]: https://docs.tyflow.com/tyflow_modifiers/tyParticleSkin/
[T-POSITION-HAIR]: https://docs.tyflow.com/tyflow_operators/particles/position_hair/
[T-CLOTH-BIND]: https://docs.tyflow.com/tyflow_operators/particles/cloth_bind/
[T-CCCS]: https://docs.tyflow.com/tyflow_objects/tyFlow/cccs/
[T-CCCS-FAQ]: https://docs.tyflow.com/faq/CUDA_collisions/
[T-PHYSX-SHAPE]: https://docs.tyflow.com/tyflow_operators/particles/physx_shape/
[T-PHYSX-COLLISION]: https://docs.tyflow.com/tyflow_operators/particles/physx_collision/
[T-PHYSX]: https://docs.tyflow.com/tyflow_objects/tyFlow/physx/
[T-RESET]: https://docs.tyflow.com/faq/reset/
[T-CACHE]: https://docs.tyflow.com/tyflow_objects/tyFlow/cache/
[T-TYCACHE]: https://docs.tyflow.com/tyflow_modifiers/tyCache/
[T-EXPORT]: https://docs.tyflow.com/tyflow_operators/particles/export/
[T-MESH]: https://docs.tyflow.com/tyflow_operators/particles/mesh/
[T-RENDER]: https://docs.tyflow.com/faq/rendering/
[T-EXAMPLE-SCENES]: https://docs.tyflow.com/download/version/
