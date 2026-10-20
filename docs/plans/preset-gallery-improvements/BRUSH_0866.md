# Surface painting restoration — 0.86.6

User authorization, 19 October 2026: restore sphere, box and curved-surface
painting without removing current vector brush features; qualify in Max 2027
and deliver both MZP and shareable EXE. No artist installation/restart, Git push
or older-host qualification is authorized.

## Release identity

The user supersedes the previous minor-version selection: the completed library,
Amount, procedural-map, unit-transfer and lifecycle work is now the **0.86.5
baseline**; this brush restoration is **0.86.6**. Original 0.87.0 packages and
receipts retain their actual labels/hashes as historical evidence. Do not invent
0.86.3/0.86.4 qualification. Independently versioned products are unchanged.
Current source began at ce062502ecda3af57b25e8821c9e5a7744d3501d plus the recorded
dirty/untracked reliability and unrelated work. Preserve all of it.

## Design and ownership (F01, F04–F11)

Keep the existing fast local-XY vector domain for terrain and its existing saved
coverage. Extend the same receiver-bound document with sparse per-face vector
regions in barycentric coordinates for general triangulated surfaces. Boolean
Paint/Erase edits canonical coverage, never persistent stroke history or a raster.
Full faces have compact markers. Surface identity remains geometry-bound;
arbitrary remeshing must not silently reinterpret stored face coordinates.

Native copied geometry owns topology, metric and geodesic preparation. Use the
MIT-licensed Kirsanov exact polyhedral-distance implementation with explicit work,
interval and mesh admission. Approximate only the vector contour of its distance
field, with a declared radius-relative tolerance; compare against independent
planar/unfolded-box and sphere-distance oracles. Feathering uses sampled canonical
boundary sources with bounded error and direct same-face segment distances.
Receiver transforms use all three basis vectors. Disconnected sheets have no
distance path. Existing terrain projection/feather widths remain unchanged.

Surface snapshots/adjacency are reused until relevant geometry/transform changes.
Coverage changes invalidate the field and border; idle/browsing do not. Pending
gestures and final successors publish atomically through the existing hold. Any
admission, geometry, conversion or field failure retains the previous complete
document/result. Undo retains before/after canonical coverage, not derived solver
state. Host SDK calls and publication stay on the host thread.

Bound mesh/face data, solver intervals/iterations, contour refinement, stroke
resampling, boundary sources and serialized payload before allocation/publication.
Record measured peak storage and latency with final qualification, including old
and successor overlap. Do not claim exact geodesic isolines or unlimited meshes.

## Required acceptance — completed within recorded scope

- Sphere/poles, box sides/edges, cylinder/curved/folded surfaces, disconnected and
  closely spaced sheets; transformed/nonuniform/mirrored metric; tiny/large radii.
- Additive painting, continuous gestures, Erase/holes, Fill/Clear, independent
  density/scale feather curves, border feedback, copies and independent areas.
- Existing terrain/spline conversion and complete library/Amount fixes retained;
  curved conversion/transfer explicitly validated, never silently flattened.
- Generated Start handler plus subsequent timer, real Painter callback route;
  Manual/Live, owner switching, relevant geometry failure and recovery, idle reuse.
- Undo/Redo, save/reopen and serialized malformed/capacity rejection.
- Native/Python/generated checks; matched SDK/native/script Max 2027 host cases;
  exact MZP/EXE payloads, labels, inventory, archive integrity, disposable recipient
  install/repair/uninstall and upgrade from the previous higher-numbered label.

Status: implemented and qualified within the [0.86.6 delivery report](DELIVERY_0866.md). That report and its receipts own completed evidence and remaining artist acceptance.
