# Root and branch repair 0.3.1 — Max 2027

25 October 2026. Corrective independent Vegetation Preparation Lab patch. Scatter stays 0.86.9.2/schema 59. Original A/B/C source and the frozen contract are unchanged. Earlier 0.3.0 source receipts/packages remain historical.

## Reproduced cause and implemented repair

The exact failing Lavender 01 source fingerprint is `17e97d9bd9ae884da5741e7f95e4e76ae6bcf83e1c4d7cf45093588b7534a0d6`, matching the user's report. It has 365,902 vertices / 563,380 triangles and 16,853 connected parts. Three thick basal shoots have roots near (0, 50, 0), (-43.301, -25, 0) and (43.301, -25, 0) mm. Source-predecessor attachment forced the latter two across approximately 86.6 mm of open space into the first cluster. This was a wrong inferred hierarchy, not a broken plant mesh.

Native analysis now estimates the basal plane from thicker tube endpoints, distinguishes low connected branches from independent basal shoots, and builds a spatial forest from endpoint-to-guide contacts. Tube radii, taper and ground path distance guide connections. Thin tips cannot become branch bases when the other endpoint is noticeably thicker. Each endpoint retains up to eight parent candidates; guide/part IDs stay fixed and an explicit parent-before-child permutation supports parents appearing later in the source. The private prepared-data validator rejects duplicate/missing traversal IDs, cyclic/backward traversal and unresolved guides before binding or radius propagation. Grounded roots pin their own original cross-section vertices. The 25 mm maximum connection ceiling is unchanged; local radius gates can be tighter. Elevated disconnected guides remain unresolved and block preparation. The overlay/status reports grounded roots and unresolved connections instead of claiming manual guides are necessarily required.

No worker SDK access was added. Numeric snapshots, immutable successor admission, cancellation/source-edit rejection, Undo and native geometry publication remain the independent Lab's existing ownership model. Candidate storage is at most 32,768 retained contacts; exhaustive numeric candidate search has an admitted worst case of 2048x2048x2x15 spans, with cancellation checks every 32 parents and between major stages. Graph/arcs scratch is bounded by these counts; actual allocator/process peak and scene-wide history pressure are uninstrumented.

## Executed native tests

`build/vegetation-root-plugin-20261025-03/test-receipt.json` records five successful executable runs with retained logs:

- Connectivity: multiple basal roots, parent after child, reversed tube, downward branch, elevated orphan, source-component permutation, deterministic traversal and cancellation.
- Preparation/rejection controls and both complete source assets. Lavender 01: 560 guides, 3 roots, 0 unresolved, largest accepted branch separation 4.976 mm, 44,086 preview triangles. Lavender 05: 1,290 guides, 1 root, 0 unresolved, largest separation 8.180 mm and unchanged 69,736 preview triangles.
- Lavender 01 actual mesh: rest reconstruction, all basal anchors, invalid/cyclic/duplicate/unresolved graph rejection, eight sphere positions with successful fitting, pose serialization round trips and six active full delivered-float audits. All audited gaps exceeded 1 mm, all basal roots stayed within 1 micrometre, and no rigid foliage edges changed above 10%.
- Lavender 05: nine successful legacy sphere positions, rest reconstruction, saved pose round trip and delivered-float contact regression. The tested x=0.42 m pose retained its previous approximately 8.703 mm minimum gap.

The stronger Lavender 01 sweep measured a maximum stem triangle-edge change near 73.4% at x=0.35 m, despite small guide-span length error and collision clearance. This existing mesh-binding deformation limitation remains open; the root/connectivity fix is not a claim of volume-preserving stem deformation. Rigid foliage held shape. Do not equate a successful guide fit with universally certified visible geometry.

## Executed Max 2027 qualification

`build/vegetation-root-host-20261025-02/receipt.json` passed, exit 0, original artist INI unchanged. Original source asset SHA-256: `ecfc86908a46a60bd9fa9028197074e099264f4d40679c8c1ec5e2fee60ee080`. Native Analyze returns can_prepare=true and Needs review for the user's exact source. Explicit review acceptance, Prepare, acceptance and object creation Undo/Redo, native collider movement, idle reuse, cancelled successor retention, in-flight source-edit rejection, unsupported box, row removal Undo/Redo, save/reopen with catalog/output references, guide overlay, full viewport and full Scanline rendering passed. The prepared source scene is a derivative; the original model file was only read.

Lavender 05 host regression `build/vegetation-root-regression-host-20261025-02/receipt.json` also passed the corresponding authoring/lifecycle/render fixture. This protects the formerly supported model while changing the hierarchy algorithm.

Lavender 01 numeric analysis took 0.182 s in the owned host run; host capture/worker publication wall time was 599.557d0 milliseconds. One-time mesh/binding cache realization is a separate cost. Warm changed-sphere viewport builds ranged 5.45–12.36 ms in this run, including native fitting and light mesh staging; these are CPU timings, not presented FPS.

Full delivered float audit at x=0.42 m, z=0.52 m, radius=0.12 m: minimum gap 31.998 mm, root ring error 1.98e-09 m, maximum rigid foliage relative edge change 0.00875%, zero rigid edges above 10%, maximum stem triangle-edge change 10.90%. Audit cost 102.9 ms is explicit and is not charged every pointer update.

## Exact native identity

MSVC 19.38 / C++20 Release, Max 2027 SDK. The build receipt pins every native source, private/frozen headers, SDK CMake helper and the reused collision/fitter/Jolt static libraries.

- DLX: `88bfccdc319c4f7d91c7b71d897e91c1fb87cd4e6e97911a846fd4867d974ab7`
- DLO: `15137532b63ba66b5114092fa18df049b07c3edcbf9d3fe42ee3d70111a6b393`

DLO remains the sole class registration owner. Scene field layout remains geometry schema 2 / catalog schema 1, but this prototype requires matching 0.3.1 scene/version strings so old inferred analysis is not silently described as repaired. Preserve 0.3.0 scenes with their matching kit; new tests load original source geometry in a fresh owned process. Package integrity and fresh launch execution are recorded separately beside the final MZP.

## Limits and next acceptance

This profile still requires recognizable ordered round tube sections. Reordering components and reversing ring direction are supported; arbitrary scrambled vertices or merged botanical topology are not. Ground inference assumes an upright plant and can be unreliable on cropped, horizontal or top-heavy geometry. Material/normal/opacity fidelity and arbitrary renderer qualification remain separate from the simple Scanline test. Only complete uniformly scaled standard Spheres are admitted. Cold missing-source recovery, true process peak memory, sustained mouse-held publication, manual guide correction/import and stem cross-section preservation remain open. No wind, self-collision, multi-collider Scatter layers or production integration was added. The original research matrix is not closed by these focused tests.


## Actual button-path placement correction

Actual Add/Analyze/Accept/Create Sphere/Prepare interaction exposed an existing factory defect: after Sphere creation in a Front viewport, the output node inherited a 90-degree construction-plane rotation. The staged vertices already use world coordinates, so this rotated the visible plant away from its analyzed guides. Both native creation entry points now explicitly set identity node transforms. The final Lavender 01 host fixture creates in Front view, asserts identity, and rejects a deliberately translated output during full-mesh auditing. This prevents a local-coordinate audit from silently claiming world-space clearance. Native source/scene identities above refer to final build 03; intermediate build 02 receipts remain historical. The original user's 0.3.0 session was preserved.
