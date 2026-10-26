# Cyrus Vegetation Lab 0.1.0 — Max 2027

**Current independent preparation experiment: [Vegetation Preparation Lab 0.3.1](experiments/stem-live/GUIDE_031.md).** It includes native model analysis, basal-root/spatial-branch inference, guide review, a persistent catalog and automatic sphere interaction with Lavender 01 and Lavender 05. See its [qualification report](experiments/stem-live/REPORT_031.md). The 0.1.0 manual-fit laboratory below keeps its own source and historical qualification; the independent lab tools retain their own qualification. CyrusScatter 0.87.0 now reuses the preparation/fitting core for its separate [integrated Interactions trial](../docs/plans/scatter-interactions-garden-20261025/DELIVERY_0870.md). Lab sphere tests do not qualify Scatter integration.

An independent prototype for fitting rooted grass around a spherical stone. It combines the reviewed native collision queries, rooted guide fitting, and independent visible-mesh validation. It does not change CyrusScatter or Physics Lab.

## Install and try

1. In **3ds Max 2027**, choose **Scripting > Run Script** and run `CyrusVegetationLab-0.1.0-Max2027.mzp`.
2. Save your work and restart Max 2027 so its exact native modules load together.
3. Run `OpenCyrusVegetationLab.ms` using **Scripting > Run Script**, then click **Create Demo**.
4. With `CVL_Grass` selected, open **Modify** and click **Fit grass to stone**.
5. Move or resize `CVL_Stone`, reselect the grass, and click **Fit** again. Try **Reset grass** to compare the original shape. **Bake Mesh** creates a regular mesh copy.

The class is also available in **Create > Geometry > Cyrus Labs > Cyrus Vegetation Lab**. The launcher macro is in **Customize User Interface > Cyrus Labs > Grass and Stone Lab**. The launcher adds its three demo nodes to the scene and preserves existing nodes.

## What to expect

- Seven prepared blades by default, selectable from 1 to 21 when creating a demo. Each blade has eight flexible spans and 16 triangles.
- Roots stay planted. The free base direction lets a blade bend away from the stone. **Lock base direction** additionally pins its first direction; fitting can fail if the stone blocks that fixed base.
- **Clearance** is the requested surface gap, from zero to 5 cm. Changes wait for **Fit**. The solver uses an additional 0.1 mm host conversion guard; the independent checker uses the requested gap on the actual float mesh delivered to Max.
- A rejected fit retains the complete previous mesh. Read the status in the Modify panel or press **Print validation details** for the Listener report.
- Fit and Reset support Undo/Redo. Source roots, accepted poses and collider snapshot save in the Max scene. Copy creates independent state. Use Copy rather than Instance for separately fitted patches.
- Moving the sphere or changing animation time does not solve automatically. Viewport and renderer read the same accepted mesh.

## Deliberately small test scope

This version accepts a complete **standard Sphere** as a static collider. Keep Hemisphere at zero, Base to Pivot off, Slice off, and use positive uniform sphere scale without modifiers. Arbitrary rock meshes, boxes, multiple colliders, existing production plant assets, wind, self-collision and animated dynamics are not implemented here.

Keep the grass scale at 100%; translation and rigid rotation are supported. Keep the grass within 100 m of the world origin, the sphere within 10 m of the grass, and its radius between 1 mm and 2 m. Do not change scene system units after creating the demo; create a new demo if you need different units. **Reset** intentionally restores the original unbent mesh, which may intersect the stone.

The ribbons are a geometry test, not a finished botanical model. Source normals are generated geometric normals, with UVs and a simple two-sided material. Use Bake Mesh to inspect or export the accepted result. Baked copies occupy the same position as the lab patch; hide or move one copy when rendering.

## Ownership and qualification

Native C++ owns source ribbons, immutable solver generations, cached meshes, persistence and Undo states. MAXScript supplies the bounded authoring commands and UI. Each Fit stages all blades and independently validates the delivered mesh before publication. Work is synchronous and limited to a small patch, with a 20,000-query budget; internal Jolt allocations and total process peak memory are not instrumented.

Exact source and binary hashes, test commands, host receipts and remaining limits are recorded with the delivery in `docs/QUALIFICATION.md`. Historical headless acceptance is kept separate from host qualification. See `docs/IMPLEMENTATION.md` for the ownership and failure contracts, and `core/PROVENANCE.json` for the A/B/C source origins.

The installer writes only the current user's versioned Vegetation Lab directory, its named plug-in registration, and its own startup script. It does not load replacement binaries into the running Max session. `Uninstall.ms` in the installed directory removes that registration and startup script, leaving scenes and package files available.
