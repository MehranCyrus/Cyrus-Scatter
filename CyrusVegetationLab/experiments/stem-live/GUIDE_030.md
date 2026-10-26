# Vegetation Preparation Lab 0.3.0 — Max 2027

An independent foundation for preparing plant geometry once and reusing lightweight stem guides during collider interaction. The scene retains the original mesh, model catalog, inferred guides, review acceptance and prepared bindings. CyrusScatter integration and wind/tree dynamics are future work.

## Start

Save current Max work. Run **CyrusVegetationPreparationLab-0.3.0-Max2027.mzp** through **Scripting > Run Script**. It copies a versioned kit into your user scripts folder and reports the launch path. It does not change plug-in registration or restart Max. If an earlier Stem Lab module is already loaded, save work and restart **Max 2027** before running the new kit.

- **OpenTest.ms** verifies the kit, loads the matching native pair and opens **Vegetation_Preparation_Max2027.max** with its sphere selected. Save your work first; the opener rejects unsaved scenes.
- **OpenLab.ms** loads the preparation panel in your current scene so you can add your own model. Keep the kit together; load its matching modules before reopening native scenes.

The portable folder supports these launchers without installation. A different native binary loaded from another folder is detected before loading, preventing duplicate class registration.

## Prepare a model

1. Select an original mesh and click **Add selected model(s)**. Catalog rows have stable IDs and save in the scene. **Remove catalog row** keeps scene objects and supports Undo; removed IDs are not reused within the eight-slot foundation catalog.
2. Set minimum stem length and preview foliage percentage, then click **Analyze model**. Settings apply when you analyze. Analysis runs in native C++ on copied geometry; no Python is needed. **Cancel analysis** retains earlier preparation.
3. Enable **Show inferred guides and root markers**. Inspect base-to-tip direction, roots and branch attachments. The report describes the profile and uncertain topology. **Accept reviewed guides** records acceptance of this analysis.
4. Pick a complete standard Sphere or **Create test sphere**, then **Prepare interactive model**. Source hiding happens after successful creation. Repreparing hides the previous output and retains it in the scene.
5. Drag the sphere with the Move gizmo. **Pause interaction**, **Full viewport geometry** and **Validate full mesh** help compare behavior. Rendering/conversion request full geometry; the reduced viewport is approximate.

Lavender 05 has 577,792 vertices and 832,240 triangles. The native profile finds 1,290 actual stem guides and 27,486 connected parts. Default preview: 69,736 triangles. Leaves, flowers and small irregular pieces follow rigid attachment frames.

## Supported profile and limits

The analyzer recognizes separated, round, ordered tube stems. Consecutive vertex rings must match actual triangle connectivity; authored ring order defines base-to-tip direction. Branches attach to earlier source guides. It works for the tested lavender; arbitrary merged meshes and trees may need authored guides or another preparation profile. Large unresolved parts, mixed-material components and distant attachments block preparation. Botanical correctness requires visual review. There is no manual guide editor yet.

Contact uses deterministic fitting from rest, with a bounded socket-rotation fallback for difficult child stems. Wind, inertia, self-collision, multiple colliders and Scatter layers are not implemented. Keep source geometry/transforms/system units unchanged after preparation. Source edits mark analysis stale and require Analyze/Review/Prepare again. Move the collider; the UI locks prepared output transforms.

Only complete standard Spheres with uniform positive scale and no modifiers are supported. Hemisphere, Slice and Base-to-Pivot must be off. Radius: 1 mm–2 m. Test clearance: 1 mm plus an internal fitting guard. Failed fits retain an older pose, which can be stale relative to the collider; read the status. Warm cached geometry survives missing/invalid dependencies. Recovery with missing source geometry after cold reopening is unqualified.

Limits: eight catalog slots, 1M source vertices, 2M triangles, 40k parts, 2048 guides and 160k preview triangles. One worker/catalog; 16 MiB metadata/model and 32 MiB serialized catalog. These bound payload/work, not actual process peak memory or total scene history/catalogs. Closing the UI requests cancellation; document destruction joins the worker. Capture/publication briefly occupy the Max thread.

The supplied scene uses simple test materials. Original Corona/texture/opacity fidelity, explicit normals and arbitrary renderer integration are unqualified. Stem tube triangles can stretch more than rigid foliage; **REPORT_030.md** records measured distortion and remaining gates. Save new scene copies and retain the exact kit. Earlier labs remain separate.
