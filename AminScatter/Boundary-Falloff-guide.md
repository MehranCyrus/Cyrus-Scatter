# Area — Boundary Edge Falloff (0.50)

Open a layer's **Area** panel and use **Pick Surface Analyzer** under Boundary Edge Falloff. Only the full boundary is used, including hole loops and separate elements. Street Side selection and the Analyzer's boundary export mask do not restrict this effect. Analyzer boundary data must already exist; use Analyze on the Analyzer when it is in Manual mode.

Three independent switches:

- **Delete edge band / Delete width**: remove points closer to the boundary than this distance.
- **Scale ramp / Scale width**: multiply instance scale by an editable curve over this width. Default is 0 at the edge to 1 at the end.
- **Density ramp / Density width**: retain a curve-controlled fraction of the original points. 0 removes all, 1 preserves full generated density. Stable random decisions avoid reshuffling surviving points when editing the density curve.

When deletion is enabled, both ramps start after the deleted strip. At and beyond each ramp width, its final curve value remains in effect. Width zero uses the final value immediately.

In 0.51, use **Edit Scale Graph** or **Edit Density Graph** to open the native Max curve editor. See Area-Falloff-Graph-guide.md for the per-line Area controls and Bezier graph workflow.

Distance is measured in world units to the nearest 3D boundary segment using a spatial tree. The effect runs after base point generation/within-layer relax and before source transforms, cross-layer cleanup and manual CS Edit. It never creates new points. Later manual moves, local offsets or final relaxation may move surviving points; this effect is not a permanent motion constraint.

Settings are stored per layer. Real-time mode observes Analyzer analysis revisions; Manual mode requires Update. Removing the picked Analyzer disables all three effects. Existing scenes start with the effects disabled.

Validation: six native suites passed, including 100,000 candidates, holes, separate elements, deterministic/monotonic density, deletion and reversed scale curves. See work/v50 test output for the Max integration run.

