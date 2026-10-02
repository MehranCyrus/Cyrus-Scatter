# Cyrus Scatter 0.43 — Viewport display

**Current 0.64 update:** Mesh now uses retained source geometry and GPU instancing, with its existing face/instance selection and shading. Point Cloud retains its 0.63 improvements. Both modes keep their original drawing paths as fallback; camera-dependent detail remains future work. See the [candidate guide](../docs/Retained_Mesh_Preview_2026-10-02/README.md). The mode/geometry descriptions below are retained from 0.43; its validation is historical.

Open **Viewport and Render → Display mode**:

- **Point Cloud** keeps the existing point preview and its point limits.
- **Proxy** reveals a second dropdown, **Proxy shape: Box / Sphere / Pyramid**. Shapes fit each source's pivot-local bounds and inherit the final instance position, rotation and scale. Sphere is fitted to the bounding extents, so it becomes ellipsoidal for elongated models.
- **Mesh** draws the source's actual evaluated viewport mesh, with the selected solid/source-group preview color. It is a geometry preview, not a preview of Corona materials or textures. A source which is itself a render proxy supplies its viewport representation.

**Show preview** enables/disables display. **Instances/layer** and **Faces/layer** limit only the Proxy/Mesh viewport workload, defaulting to 2,000 instances and 2,000,000 triangles per layer. If the full source mesh exceeds the face budget, that instance is omitted; increase the budget to show it. The displayed-count status reflects the limit. Render placements and PFlow are unaffected.

Point placeholders remain point markers until replaced with a source object. No scene instances are created for these display modes. Geometry is cached per source and reused with the final placement transforms; it is not rebuilt every idle redraw. Mesh drawing is more expensive than the low-resolution proxy shapes or point display.

Restart 3ds Max after installation to load bin43. Existing scenes default to Point Cloud. Display mode, proxy shape and viewport limits are saved with the controller.

Validation in an isolated 3ds Max 2026 session: screenshots checked for Point Cloud, Box, Sphere, Pyramid and the full 1,024-face source teapot mesh. All 12 placements remained identical across modes; renderer signature stayed unchanged. Instance and triangle limits, idle cache reuse, UI sub-option visibility, save/load and Point placeholders passed. Five native core test suites also passed.

