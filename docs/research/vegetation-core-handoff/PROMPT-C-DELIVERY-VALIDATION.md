# Paste into GPT Web chat C: mesh delivery and independent validation

You are implementation owner C for CyrusScatter Vegetation Core Handoff v1. The same ZIP is supplied to independent owners A and B. You do not need their implementations or 3ds Max. Your validator is the independent check that prevents a mathematically clear centerline from hiding a blade/triangle collision.

Inspect `START-HERE.md`, handoff `DOCUMENT-LIST.md`, `WORKFLOW.md`, `SHARED-CONTRACT.md`, `FROZEN-FILES.json`, the frozen header and `fixtures/catalog.json`. State role, edition and actual frozen header SHA-256. Read research 01/03/04/05/07/08/09, the R11 preparation/binding evidence and R13/R14 validation caveats. Do not generalize the v1 sampler to arbitrary library vegetation.

Implement `evaluate_ribbon` and `validate_candidate`. You own **only** `docs/research/vegetation-core-handoff/starter/delivery/`. Export `cyrus_vegetation_delivery`, link `cyrus_prototype_contract`, and prefix CTest names `delivery_`. Include private geometry helpers, source/tests, optional diagnostic OBJ exporter, README and execution evidence. Do not edit frozen files or other modules. Describe a needed shared change in your module's `CONTRACT_CHANGE_REQUEST.md`.

Evaluator requirements:

- Explicit one-guide span/u bindings with full xyz rest offset; linear center and normalized shortest-path quaternion slerp shared by rest and deformed evaluation. Reject unsupported full-turn/ambiguous frame cases, rather than collapsing them silently.
- Check rest reconstruction against supplied positions. Keep semantic IDs through the binding association, seam distinctions, UVs, triangle indices, face material assignments and source revision. Coincident positions do not authorize welding. Finite geometric normals and exact mesh bounds are required; authored custom normals/tangents are deferred explicitly.
- Validate array/index/frame/envelope data, finite geometry, budgets and cancellation before returning a complete privately staged mesh. No source edits or partial successful output.

Validator requirements:

- Use independent sphere/OBB/triangle mathematics. **Do not call A, B, Jolt or a mock of A to determine acceptance.** Re-evaluate the pose independently enough to check that supplied output corresponds to its declared inputs; never trust an acceptance flag or plausible bounds.
- Check fixed root and root mode, lengths, frame validity, source reconstruction, envelope sufficiency, source/mesh correspondence, topology/UV/material/bounds/normals and visible triangle clearance against every obstacle. Vertex-only sampling misses triangle-interior intersections. Surface absence must not miss a wholly contained triangle.
- For spheres use triangle minimum distance including face interiors. For OBBs provide a sound full-triangle separation test; the contract permits conservative axis-expanded boxes for clearance if declared. Do not call conservative proxy depth an exact physical penetration distance. Ambiguous/unsupported geometry cannot Pass.
- Test clear rest, authored feasible sphere pose, root violation, bad length/frame/source revision, width penetration with a clear guide, large triangle with all vertices outside but its interior intersecting a sphere/box, containment, rotated box, two obstacles, changed topology/UV/bounds, nonzero longitudinal offset, seam IDs, quaternion sign, unsupported full turn, cancellation and resource limit. Include controls that Pass, not just rejection tests.
- A catalog fixture with too-small span radius is deliberately invalid. Reject its envelope and demonstrate the visible surface overlap independently. It is not evidence that an admitted conservative envelope failed.

Use authored poses for testing so you are independent of the fitter. An OBJ export is optional diagnostic output, not a renderer or Max Bake pass. A per-fixture report may include root/length/reconstruction/visible penetration measurements and reasons. Distinguish exact metrics, conservative certificates, expected results and actual executions.

Return a complete source ZIP, machine-readable manifest, commands/logs, test summary, known limitations and contract hash as required by `RETURN-CHECKLIST.md`. No SDK, binaries, web frontend, host adapter or full asset extractor is requested. If tools cannot compile, state Not executed; do not invent test logs, timings, visual checks or host results. End with a short local integration note.
