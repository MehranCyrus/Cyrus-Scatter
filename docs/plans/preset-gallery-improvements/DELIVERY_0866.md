# Cyrus Scatter 0.86.6 — surface painting restored

Delivered for user testing on **19 October 2026**, **Max 2027 only**. The complete
library/Amount reliability feature set is retained under the user-corrected
**0.86.5 baseline**; this brush fix is **0.86.6**. Original 0.87.0 receipts and
artifacts retain their actual labels/hashes. No 0.86.3/0.86.4 qualification is invented.
Scene schema 58, recipe 7 and independent product versions remain unchanged.

## Install and share

- [Windows EXE](../../../dist/CyrusScatter-0.86.6-20261019/CyrusScatter-0.86.6-Setup.exe): choose Max 2027, then **Install / Repair**.
- [Max 2027 MZP](../../../dist/CyrusScatter-0.86.6-20261019/CyrusScatter-0.86.6-Max2027.mzp): **Scripting > Run Script**.

Save work and restart Max after a successful installation. Both contain the exact
qualified script/native pair, library and patterns. The EXE is unsigned and normal
Cyrus activation still applies. No artist installation/restart, older-host testing,
Git publication or live website deployment was performed.

## Result and implementation

Spheres, boxes, vertical sides and manifold curved surfaces accept Paint again.
The existing terrain vector path is preserved; general surfaces use native
per-face barycentric vector regions and surface-distance strokes. Paint does not
project through the sphere or disconnected sheets. Full XYZ transforms, including
nonuniform scale and mirrors, participate in physical distances. Degenerate and
nonmanifold geometry rejects with context and retains preceding results.

Paint/Erase, Fill/Clear, holes, density/scale fade curves, vector feedback,
independent copies, Manual/Live, Undo/Redo and scene persistence remain supported.
Curved borders export as 3D splines. Unchanged guarded snapshots restore exact
coverage; edited surface curves reconstruct their smaller enclosed region.
The host tests found and resolved both a small-brush refinement-depth limit and
the inappropriate generic knot limit on exact exported snapshots.

All prior library/Amount fixes remain: complete unit conversion and terrain Paint
transfer, receiver-aware procedural maps, channel/pattern switching and Clear,
valid empty-source publication, and minimized Library restoration.

## Evidence

- **46 native tests**, including **82 surface Paint assertions** and retained terrain/conversion tests.
- **175 Python tests** and generated UI validation covering **321 controls**.
- **21 brush host phases** through generated UI handlers and actual Max Painter SDK callbacks: sphere stroke/erase, opposite-side isolation, box/cylinder sides, cancellation, fade curves, exact spline snapshots, copies, unit transfer, transforms, topology failure/recovery, Manual/Live, idle reuse and scene reopen.
- **18 recorded final-pair host cases/suites**, including all eight presets in millimetres, transformed feet, centimetre incompatible-destination recovery and a metre heightfield; plus lifecycle, Amount, receiver-map, elevation and damaged-package/capacity suites.
- **34 exact-EXE recipient checks**, including legacy path limits, Unicode paths, repair, modified-file preservation, five injected rollback points, upgrade from original 0.87.0, unregister and personal-data preservation.
- **64 actual EXE UI/layout/handler checks**, including scaled layout, successful installation and visible full repair errors in owned profiles.
- The exact MZP installer core loads in Max 2027 and installs/repairs the payload and dependency notices in a separate owned recipient directory.
- Archive integrity, every payload hash, Max/version guards, embedded package identity and Windows file/assembly version **0.86.6.0** verified. Private Painter probe is excluded.

The final owned sphere test took **708.506 ms for 13 Painter samples** including
feedback preparation. Its process private bytes rose from **4,788,584,448** before
the fixture to **5,021,683,712** after the full sequence, with a recorded peak
working set of **3,121,164,288** bytes. These are process observations including
Max/UI/history, not isolated native allocations or presented viewport FPS.

## Limits and acceptance

Curved receivers admit at most 100,000 triangles/200,000 vertices. Solver intervals,
propagation, contour refinement, curve input and payload size have separate work
limits; retained/staged reservation is bounded and preserves OS commit headroom.
Contour refinement targets 0.5% of brush radius; feather boundary sources use
2% of fade width spacing. These are bounded approximations, not exact isolines.
Arbitrary remeshing cannot preserve face correspondence. Terrain preset transfer
still requires a usable local-XY footprint; curved preset transfer requires matching
indexed topology. Edited curves have an 8,192-knot/sample cap; exact unchanged
snapshots use the native contour cap. A fully filled closed object has no border.

Tests drive real Painter callbacks and UI handlers but do not certify physical
mouse/tablet input, every production renderer, all scene sizes or older Max hosts.
Artist acceptance: test a copy of a working scene with sphere/box/curved painting,
erase and fade curves; save/reopen; then exercise the Library and Amount workflows.

## Exact identities

- MZP SHA-256: `9170f5b91826007b15423e23181774b6e275321420502676131ea6abc686f208`
- EXE SHA-256: `24a70c1c85600cbc694c6966e37288885a871f9b56995781801e7e78044e9ac8`
- Script SHA-256: `ace7b0504133c6cb0fedaca00854cad2a2093f811100796d2167572e9198ef60`
- Native receipt SHA-256: `b0baa5cd5862dbf3d6bddfa32a95424170532de304ac48111f5f0d964f174e81`
- [Host qualification](QUALIFICATION_0866.json); package, EXE and native receipts accompany the installers.
- Source changes and reproducible fixtures: `tools/surface_brush_0866/`; [design/ownership record](BRUSH_0866.md).

Website status: current sources imported, static/content checks passed for 321
controls and five guides, and the local production build passed. Nothing is published.
