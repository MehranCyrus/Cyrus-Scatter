# Physics Lab 0.1.2 automatic collision proxies

16 October 2026. User's normal 32-segment sphere on a simple Plane exposes the
0.1.1 automatic-proxy gap: source geometry is copied as the proxy and rejected
above 128 vertices. This is a product limitation, not an invalid artist setup.

Scope: correct automatic collision-shape preparation in the independent lab;
preserve full render geometry, custom-proxy overrides, retained results, bounds,
units and native UI. No Scatter integration, presets, Computer Use, artist
installation/restart, commit or push. Initial HEAD
`5aee4ef2242307b92e16c96e0106ee095d6a4215`, branch `codex/workflow-0.75`.
Existing tracked documentation and unrelated untracked assets are preserved.
Knowledge generation `44bb5752…` is stale and does not enroll the lab; current
source and pinned dependency headers are inspected directly.

Version decision: **0.1.1 -> 0.1.2**, a correction enabling normal detailed sources
through bounded automatic convex proxies. Saved schema 1, parameter order and
registration IDs stay unchanged. New authoring uses `cpl-leaf-3`; old retained
profile 1/2 results keep their recorded profile and poses until explicit authoring.
Independent Scatter/Analyzer/MCP/licensing versions are unaffected.

Acceptance: reproduce the real Max Sphere32 rejection; retain the exact render
mesh while reducing collision geometry within engine limits; exercise the real
Pick/Start/Painter/timer path with a 32.788 mm Sphere32, a subdivided Plane and an
extra collider; test custom proxy rejection/override/reset, append/Undo, scene
roundtrip, old cached scenes and failure retention. Qualify a fresh Max 2027 exact
pair and MZP in owned profiles only. Physical input remains artist acceptance.

## Reproduction and correction

`build/physics-lab-012-baseline-01` used the frozen delivered 0.1.1 native/script
pair, a genuine Max Sphere with 32 segments and 32.788 mm radius, millimetre system
units and a 4x4-segment Plane. The actual source pick/Start handlers reproduced
the rejection. Max reported **482 vertices / 960 faces** for that sphere.

The source renderer is now independent of collision detail. Sources up to the
existing combined 200,000 render vertices/faces admission remain eligible. When
the automatic source has over 128 vertices, a conservative convex approximation
is generated from 98 fixed support planes in an AABB-normalized frame. All plane
triples are bounded and tested against the other half-spaces. At most 192 distinct
vertices are retained; invalid/degenerate results fail before publication. The
small existing proxy path is unchanged. Open meshes retain the documented
thickness-envelope behavior before reduction.

The support directions are primitive integer vectors in [-2,2]^3; there are 98.
Axis planes make the intersection bounded. Euler's polyhedron bound gives at
most 2*98-4 = 192 vertices. Double precision, normalized coordinates and relative
outward padding handle scale/roundoff. This is an approximate convex collision
shape, not mesh decimation of the rendered asset, concave decomposition or a
promise of identical surface contact at every orientation. Curved/concave details
may have a visible collision gap; a custom convex proxy remains an override.

Pinned vendor headers independently bound the convex representation: Jolt
`Jolt/Physics/Collision/Shape/ConvexHullShape.h` has `cMaxPointsInHull=256`;
PhysX `physx/include/cooking/PxConvexMeshDesc.h` gives a hard 255-vertex limit.
These are from the commits in the build receipt; neither solver was modified.

Native preparation now checks cumulative render-source admission before cooking
the next shape. Errors identify the source model. Picking an oversized explicit
custom proxy rejects it before changing its reference. The Collision rollout
shows Automatic/Custom; **Use auto** clears only the selected model's override.
Changing a proxy with saved bodies still requires deliberate Rebuild/Clear;
switching back to the same automatic shape permits authoring without moving the
old rows. Browsing the proxy mode reads references without cooking geometry.

## Initial witnesses

- Current numerical source passes **3,174 checks**. Added cases cover the detailed
  sphere, unchanged full render geometry, bounded/deterministic cooking, support
  containment in many directions, anisotropic open geometry, a dense planar
  source, small-proxy equivalence and resting-height checks in both engines.
- `build/physics-lab-012-proxy-01` passed the actual Max Sphere32/Plane source
  pick/Start/Painter path, append/Undo, early custom-proxy rejection, low-poly
  override/reset, full-mesh retention and save/reopen. Its exported automatic
  state has **482 render vertices / 960 faces / 192 collision vertices** per
  source, four saved sphere bodies and profile 3.
- `build/physics-lab-012-layout-01` passed the new optional proxy actions and
  existing six native sections at 150% Max custom-control scale. Final exact-pair
  regression and installer receipts will be recorded separately below.

## Final delivery and acceptance

Ordinary frozen build: `build/physics-lab-012-delivery-20261016-01`. Final-source
numerical checks passed (3,174); the source and shared dependency fingerprints
match the build receipt. Jolt/PhysX body-contact tests and the previously captured
pyramid-on-Plane append regression remain passing.

- `build/physics-lab-012-final-01`: full Max 2027 regression passed at 100% custom
  control scaling. Includes the actual Sphere32/Plane/button/Painter path in mm,
  full-render retention, append/Undo, custom override/reset and rejection retention,
  save/reopen, existing brush and timeout controls, basic/extended authoring, clone,
  transformed/cm inputs, unchanged profile 1/2 cached scenes and the 60-leaf demo.
- `build/physics-lab-012-final-02`: Sphere32/proxy, existing brush and timeout tests
  passed at 150% custom-control scaling. All six sections and 61 native children
  fit at 108 logical pixels without caption clipping or control intersections;
  the 100% run fits at 162 logical pixels. These are not mixed-monitor DPI tests.
- Both exported Sphere32 results retain 482 render vertices / 960 faces and use
  192 automatic collision vertices. Automatic and custom exports have identical
  complete render geometry, including UV/smoothing arrays. The full Start handler
  took 109 ms / 107 ms respectively in these owned runs; those are local whole-
  handler observations, not solver-only costs, renderer timings or presented FPS.
- `build/physics-lab-012-faults-01`: fingerprinted private native build passed the
  existing pre-commit/post-assignment fault, timeout-retention and unfinished JSON
  roundtrip cases. The private modules and Painter probe are excluded from MZP.
- `build/physics-lab-012-installed-01`: installer parsing, payload hash checks,
  owned registration, automatic startup after restart and the **Sphere32** button/
  Painter/custom-proxy/roundtrip fixture passed using the installed pair. Normal
  Max INI, plugin registration and lab startup files match before/after hashes.
  No artist installation/restart was performed and owned Max sessions have exited.

Package: `dist/CyrusPhysicsLab-0.1.2-20261016/CyrusPhysicsLab-0.1.2-Max2027.mzp`
(657,416 bytes), SHA-256
`81b97157e364ea44fa11d58dc595d024014836e972f96faed966ad094714acae`.
Archive integrity, exact native/script hashes, Max/version guards, absence of
private commands and source/build/package agreement were verified. Exact hashes,
raw results, scene/fixture identities, owned native renders and normal-profile
fingerprints are in [AUTO_PROXY_012_EVIDENCE.json](AUTO_PROXY_012_EVIDENCE.json).
The 0.1.1 package and its historical evidence remain unchanged.

Run this MZP through **Scripting > Run Script**, save work and restart **Max 2027**.
Use the original detailed sphere as the model and the Plane as receiver; no manual
proxy copy is required. If an override was previously assigned, **Collision and
proxies > Use auto** returns that selected model to automatic collision geometry.
Saved results still require explicit Rebuild/Clear after a deliberate shape change.

Remaining acceptance: physical mouse/tablet feel, real Windows/mixed-monitor DPI,
arbitrary collider contact, dense production piles and general production memory/
performance. Convex approximation fills concavities and can leave collision gaps;
it preserves rendering detail but is not exact curved-body or concave simulation.
No preset, main-plugin integration, artist-profile control, commit or push belongs
to this correction. Concurrent forest/preset-document edits in Git status were
preserved and excluded from the lab's package.
