# Sources, method and continuation

Researched 16 October 2026, user timezone Asia/Tehran. This is a bounded static study. Follow links at their recorded scope; current vendor pages can change after this date.

## Primary online sources

| ID | Source | Used for |
| --- | --- | --- |
| T01 | [tyFlow Birth Paint](https://docs.tyflow.com/tyflow_operators/particles/birth_paint/) | Painted births, timing, brush controls and temporary preview |
| T02 | [tyFlow PhysX Shape](https://docs.tyflow.com/tyflow_operators/particles/physx_shape/) | Body creation and hull/profile controls |
| T03 | [tyFlow PhysX Collision](https://docs.tyflow.com/tyflow_operators/particles/physx_collision/) | Scene colliders and filtering |
| T04 | [tyFlow PhysX Switch](https://docs.tyflow.com/tyflow_operators/particles/physx_switch/) | Participation roles |
| T05 | [tyFlow simulation loop](https://docs.tyflow.com/tyflow_particles/simulation/) | Integration order, history and static reuse |
| T06 | [tyFlow PhysX settings](https://docs.tyflow.com/tyflow_particles/object/physx/) | Solver settings and sleep criteria; page may describe an older revision than other operator pages |
| H01 | [SideFX Stroke](https://www.sidefx.com/docs/houdini/nodes/sop/stroke.html) | Interactive stroke records |
| H02 | [SideFX Attribute Paint](https://www.sidefx.com/docs/houdini/nodes/sop/attribpaint.html) | Masks, caching and correspondence |
| H03 | [SideFX Scatter](https://www.sidefx.com/docs/houdini/nodes/sop/scatter.html) | Procedural emitter points and stability limits |
| H04 | [SideFX RBD Configure](https://www.sidefx.com/docs/houdini/nodes/sop/rbdconfigure.html) | Per-piece roles and emission |
| H05 | [SideFX RBD Bullet Solver](https://www.sidefx.com/docs/houdini/nodes/sop/rbdbulletsolver.html) | Input roles, solve controls and diagnostics |
| H06 | [SideFX SOP simulation guide](https://www.sidefx.com/docs/houdini/destruction/sop_sim.html) | Procedural simulation/emission workflow |
| H07 | [SideFX Convex Decomposition](https://www.sidefx.com/docs/houdini/nodes/sop/convexdecomposition.html) | Proxy preparation |
| H08 | [SideFX RBD Convex Proxy](https://www.sidefx.com/docs/houdini/shelf/rbdconvexproxy) | Shelf-level proxy workflow |
| H09 | [SideFX Transform Pieces](https://www.sidefx.com/docs/houdini/nodes/sop/xformpieces.html) | Match transforms by attributes |
| H10 | [SideFX instance attributes](https://www.sidefx.com/docs/houdini/copy/instanceattrs.html) | Pivot/orientation/scale precedence |
| H11 | [SideFX File Cache](https://www.sidefx.com/docs/houdini/nodes/sop/filecache.html) | Explicit persisted result versus recook |
| H12 | [SideFX RBD Paint](https://www.sidefx.com/docs/houdini/nodes/sop/rbdpaint.html) | Attribute/fracture painting distinction |
| H13 | [SideFX Vellum](https://www.sidefx.com/docs/houdini/vellum/index.html), [Vellum Solver](https://www.sidefx.com/docs/houdini/nodes/sop/vellumsolver.html) | Deformable scope and wind/drag reference |
| A01 | [Autodesk Max 2027 Painter canvas](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_painter_canvas_interface___v5.html) | Host callback meaning and ordering |
| E01 | [Jolt architecture](https://jrouwe.github.io/JoltPhysics/) | Center-of-mass and repeatability conditions |
| E02 | [PhysX 5.5 collision](https://nvidia-omniverse.github.io/PhysX/physx/5.5.0/docs/RigidBodyCollision.html) | Collider representation and SDF exception |
| E03 | [PhysX 5.5 advanced collision](https://nvidia-omniverse.github.io/PhysX/physx/5.5.0/docs/AdvancedCollisionDetection.html) | CCD concepts |
| E04 | [PhysX 5.5 dynamics](https://nvidia-omniverse.github.io/PhysX/physx/5.5.0/docs/RigidBodyDynamics.html) | Mass/inertia, damping and sleeping |
| R01 | [Kinematic LAB PhysX Painter](https://www.kinematiclab.com/products/physx-painter) | Close artist-workflow reference; brush/rigid-body placement and listed Max 2027 support; not inspected natively |

These references support only their cited claims. Online behavior was not measured. Houdini 22 documentation is not evidence about a particular local installation. Neither upstream PhysX nor tyFlow documentation proves the private solver version used by another product.

## GitHub tools and source

The GitHub connector fetched [Ghidra MCP README at v6.0.0](https://github.com/bethington/ghidra-mcp/blob/v6.0.0/README.md). Its marketing/tool count is independent of the actual installed runtime schema. The [existing nine-tool inventory](../GitHub_Tools_Inventory_2026-10-15/README.md) located our Ghidra stack, original project and helper scripts; stale version/roadmap paragraphs there do not supersede today's repository instructions.

Source files/revisions inspected through GitHub search/fetch are tabulated in [ENGINES.md](ENGINES.md) and [EVIDENCE.json](EVIDENCE.json). Jolt `AllowedDOFsTest` and Bullet `InstancedRendering` searches were preliminary routing only; the latter returned no results and supports no absence claim. The final findings use the relevant fetched update/hull/build files.

No third-party proprietary pseudocode or assembly is included in this Git folder. Neutral conclusions, addresses and hashes are included; original implementations remain separate from the proposed Cyrus design.

## Local source and native method

Startup: README, current I06 handoff, workflow, relevant architecture/backlog/foundation sections and engineering/knowledge skills. Branch/HEAD, dirty scope and hashes were captured before research edits. The knowledge service reported `stale_evidence`; no index refresh/activation was attempted. Direct originals supplied current source evidence.

Private run:

`F:/Cursor/_Cyrus_Apps/CyrusScatter/build/scatter-physics-research-20261016-01`

It contains the baseline, input identity, copied Ghidra project, live schema, request/response receipts, raw RTTI leads, selected assembly/decompilation, native ledgers, source receipts and collector scripts. It is ignored by Git and needs separate backup if preservation is required on another computer.

Sequence actually used:

1. Verified installed/input tyFlow 2027 hashes and copied the `.gpr`/`.rep` project pair into the fresh run.
2. Started the existing hidden Java backend, loopback-only port 18091. Read `/mcp/schema`; opened the copied project and loaded its stored program.
3. Verified program image base/hash/path. Scanned raw PE data for question-selected strings/RTTI; decoded the Birth Paint class hierarchy and Painter vtable.
4. Used bounded inline Ghidra scripts to inspect references and decode selected callback/helper bodies. Compared SDK callback order and reviewed import/assembly evidence. Recorded missing definitions, fragment bounds and warnings.
5. Saved/closed the copied project, verified the owned process executable/command line/run, and stopped only that PID.
6. Rehashed originals and source, recorded concurrent controller/recipe drift, rechecked the relevant current sections, checked document links and preserved the final receipts. Native originals were unchanged; a frozen whole-tree source identity is not claimed.

The launcher supplies a private Java userhome and project root. Ghidra initialization still uses its conventional AppData logging/preferences path; the startup log records this. Do not claim zero filesystem activity outside the run. Installed binaries and original analysis project are separately hash-checked.

## Continue without repeating broad reconnaissance

First read this folder's evidence and open decisions. For a native follow-up, use a new run, verify input SHA-256, copy the saved project and discover the actual served schema again. The scripts in the private run show the exact successful requests. Existing reusable launch/export helpers are under `docs/ForestPack_Research_2026-10-08/reproduce/`; read their assumptions and limits before invoking them.

The best remaining native question is where held-gesture sampling enters when `PaintStroke` is a success stub. Follow the PainterDisplay/session callers and resolve complete unwind ownership before claiming a sampling algorithm. The open solver-quality decision is better answered by the controlled engine experiments than by attempting to decompile an entire vendor solver.

All later host work uses Max 2027 only, owned profiles/scenes and verified exact script/native identities. Preserve artist sessions, Test Scene assets, original Ghidra projects and unrelated licensing/gallery changes. New research reports do not authorize implementation, installation or publishing.
