"""Maintain current navigation; preserve original dated qualification records."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def update(name,changes):
 p=ROOT/name;s=p.read_text(encoding='utf-8')
 for old,new in changes:
  assert old in s,(name,old[:80]);s=s.replace(old,new)
 p.write_text(s,encoding='utf-8')
update('README.md',[
 ('**Current delivery: Scatter 0.87.0 / schema 58 / CyrusUnified1, qualified within scope for Max 2027.** The [library and Amount report](docs/plans/preset-gallery-improvements/DELIVERY_0870.md) owns the exact MZP, supported behavior and evidence.','**Current delivery: Scatter 0.86.6 / schema 58 / CyrusUnified1, qualified within scope for Max 2027.** The [surface brush delivery](docs/plans/preset-gallery-improvements/DELIVERY_0866.md) owns the exact MZP/EXE and evidence. It restores painting on spheres, boxes and manifold curved receivers. The preceding library/Amount feature baseline is 0.86.5 by user correction; its original [0.87.0 receipts](docs/plans/preset-gallery-improvements/DELIVERY_0870.md) retain their actual labels and hashes.'),
 ('[qualified Max 2027 MZP and artist tests](docs/plans/preset-gallery-improvements/DELIVERY_0870.md)','[qualified Max 2027 MZP/EXE and artist tests](docs/plans/preset-gallery-improvements/DELIVERY_0866.md)'),
 ('Painting supports single-valued local-XY terrain and rejects vertical, folded or overlapping projections.','Painting keeps the terrain vector path and adds surface-attached vector regions for spheres, boxes and manifold curved receivers. Curved strokes follow surface distance; disconnected sheets stay independent.')])
update('AminScatter/README.md',[('**0.87.0**','**0.86.6**'),('plans/preset-gallery-improvements/DELIVERY_0870.md','plans/preset-gallery-improvements/DELIVERY_0866.md'),('qualifies library portability, receiver-aware maps and lifecycle fixes','qualifies surface painting and retains the corrected 0.86.5 library/Amount baseline')])
update('docs/ENGINEERING_FOUNDATION.md',[('General scattering supports curved receivers; vector painting requires single-valued receiver-local XY terrain. Reject unsupported projection while preserving authored borders.','General scattering and vector painting support manifold curved receivers. Preserve existing local-XY terrain coverage; curved coverage is attached to indexed receiver faces. Surface-distance strokes and feathering must not leak through closed objects or disconnected sheets. Reject degenerate/nonmanifold geometry or changed geometry identity while preserving authored borders and the previous complete result. The 0.86.6 extension supersedes the earlier terrain-only restriction; its delivery report owns scoped acceptance.')])
update('docs/ARTIST_GUIDE.md',[
 ('# Cyrus Scatter 0.87.0','# Cyrus Scatter 0.86.6'),
 ('One import allows up to 8,192 input knots\nand 8,192 sampled vertices;', 'One edited-curve import allows up to 8,192 input knots\nand 8,192 sampled vertices; unchanged guarded surface snapshots use the native\ncontour budget. For edited curves,'),
 ('Paint supports single-valued local-XY terrain; closed, folded or stacked projections reject before import.','Terrain Paint presets transfer between single-valued local-XY footprints. Surface-attached Paint presets require matching mesh topology; arbitrary remeshing is not an automatic transfer.'),
 ("Export uses the receiver's local XY plane at local Z=0, including its scene\ntransform. On terrain this is a planar border guide. Import projects the chosen\nshape along receiver-local Z and clips it to the receiver.","On terrain, export uses the receiver's local XY plane at local Z=0, including\nits scene transform; import projects along receiver-local Z and clips to the\nreceiver. Curved surfaces export their 3D border. An unchanged exported snapshot\nrestores exact coverage, including holes and large regions. Edited closed curves\nmust lie on the surface within Curve tolerance and select the smaller enclosed\nregion on a closed component. A completely filled closed object has no border to export."),
 ('Use separate areas for separate terrain surfaces while retaining the same layer models and population. Vector painting supports terrain and planes that are single-valued in receiver-local XY. Closed spheres, vertical faces, folds and stacked projected sheets are rejected. They remain usable as ordinary scatter receivers without vector painting.','Use separate areas for separate surfaces while retaining the same layer models and population. Vector painting supports terrain, spheres, boxes, vertical sides and manifold curved meshes. Curved strokes follow the surface, cross connected edges and do not paint through to the opposite side or a disconnected sheet. Degenerate faces and nonmanifold connections require repair. Curved receivers admit up to 100,000 triangles and 200,000 vertices, with additional bounded stroke and contour work.'),
 ('Distances are in the transformed projection plane, not distance along a slope.','Terrain distances remain in the transformed projection plane. Curved-surface distances follow the mesh with the complete receiver transform, including nonuniform scale.'),
 ('the vector brush has the projection limits above.','the surface brush is a separate system and supports the curved receivers described above.'),
 ('See [limits and actual qualification](Vector_Brush_0.78_2026-10-10/README.md)','See [current limits and actual qualification](plans/preset-gallery-improvements/DELIVERY_0866.md)')])
update('docs/ARCHITECTURE.md',[
 ('Applies to Cyrus Scatter 0.87.0','Applies to Cyrus Scatter 0.86.6'),
 ('[current qualification](plans/preset-gallery-improvements/RELIABILITY_0870.md)','[current qualification](plans/preset-gallery-improvements/DELIVERY_0866.md)'),
 ('In 0.87.0 complete presets','In the 0.86.5 reliability baseline (original receipts labeled 0.87.0), complete terrain presets'),
 ('The 0.87.0 extension adds','The 0.86.5 reliability baseline (originally labeled 0.87.0) adds')])
with (ROOT/'docs/ARCHITECTURE.md').open('a',encoding='utf-8') as f:f.write('''

## Surface Paint — 0.86.6

`brush_atlas.cpp` owns copied topology, full transformed metric and geodesic work.
The existing terrain codec remains unchanged. An additive payload discriminator
stores sparse per-face barycentric vector contours/full-face markers; geometry
identity prevents silent remeshing. Paint/Erase uses bounded native polygon
Booleans; no persistent stroke history or raster replaces the vector model.
Feather sources derive from canonical borders with internal face edges removed.
Derived atlases/fields are reused across idle redraws and invalidated on relevant
geometry/transform/coverage changes. Native reservations retain OS commit headroom;
failed successors retain preceding coverage and publication. Curved spline
snapshots carry exact coverage guarded by knot/frame/receiver identity; edited
curves reconstruct coverage on the surface. Complete curved preset transfer uses
matching indexed topology and physical-unit conversion. See the delivery report
for measured scope, approximation limits and explicit unsupported geometry.
''')
update('docs/plans/preset-gallery-improvements/ARTIST_WORKFLOW.md',[
 ('# Cyrus Library — 0.87.0 workflow','# Cyrus Library — 0.86.6 workflow'),
 ('The [0.87.0 delivery report](DELIVERY_0870.md) owns the exact Max 2027 package, qualification and limits.','The [0.86.6 delivery report](DELIVERY_0866.md) owns the current Max 2027 MZP/EXE and scoped qualification. The earlier reliability changes form the corrected 0.86.5 baseline; [original 0.87.0 evidence](DELIVERY_0870.md) retains its actual labels.'),
 ('Paint requires a single-valued local-XY receiver; closed, folded or stacked projections fail with a useful explanation.','Terrain Paint transfer requires a single-valued local-XY receiver. Surface-attached Paint transfers between matching indexed mesh topologies; new Paint Areas can be drawn on spheres, boxes and manifold curved receivers.'),
 ('The new 0.87.0 delivery targets Max 2027.','The 0.86.6 delivery targets Max 2027 and includes a shareable Windows EXE as well as the MZP.')])
for name in ('docs/Max_2027_Installation.md','docs/README.md','docs/plans/preset-gallery-improvements/README.md'):
 p=ROOT/name;s=p.read_text(encoding='utf-8').replace('0.87.0','0.86.6').replace('DELIVERY_0870.md','DELIVERY_0866.md')
 s=s.replace('matched Max 2027 MZP with','matched Max 2027 MZP and shareable Windows EXE with').replace('Exact MZP and evidence','Exact MZP/EXE and evidence')
 if name=='docs/Max_2027_Installation.md':
  s=s.replace('2. In Max 2027, use','2. Run [CyrusScatter-0.86.6-Setup.exe](../dist/CyrusScatter-0.86.6-20261019/CyrusScatter-0.86.6-Setup.exe), choose Max 2027, then Install / Repair. Alternatively, in Max 2027, use')
  s=s.replace('ordinary scattering on curved receivers is separate from the projected vector brush.','Analyzer remains separate from the surface brush, which now supports manifold curved receivers.')
  s=s.replace('**Use schema-58 setups for 0.86.2.**','**Use schema-58 setups for 0.86.6.**').replace('Vector painting supports\nsingle-valued local-XY terrain/planes; spheres, vertical/folded/stacked receivers\nare not supported for this brush.','Vector painting retains the local-XY terrain path and restores spheres, boxes,\nvertical sides and manifold curved receivers. Geometry changes remain guarded;\ncurved coverage requires indexed face correspondence.')
 p.write_text(s,encoding='utf-8')
p=ROOT/'docs/plans/improvement-program/PROGRESS.md';s=p.read_text(encoding='utf-8')
s=s.replace('**Current delivery: 0.87.0 library/Amount scoped qualification is complete; see the [delivery report](../preset-gallery-improvements/DELIVERY_0870.md). Unrelated roadmap work remains outside this delivery.**','**Current delivery: 0.86.6 surface painting and installer qualification; see the [delivery report](../preset-gallery-improvements/DELIVERY_0866.md). The earlier library/Amount feature baseline is 0.86.5 by user correction. Unrelated roadmap work remains outside this delivery.**')
pos=s.index('## Delivered 0.87.0');s=s[:pos]+'''## Delivered 0.86.6 surface brush

Restores spheres, boxes and manifold curved receivers while preserving vector
features, Manual/Live, history and persistence. The [scoped report](../preset-gallery-improvements/DELIVERY_0866.md)
owns exact native/host/installer evidence and the Max 2027 MZP plus EXE. All prior
library/Amount changes remain included. Earlier 0.87.0 receipts retain their
actual labels; their corrected feature baseline is 0.86.5. No artist installation,
Git publication, older-host qualification or website deployment was performed.

'''+s[pos:];p.write_text(s,encoding='utf-8')
p=ROOT/'docs/Release_Versioning.md';s=p.read_text(encoding='utf-8').replace('0.86.6 Max 2027 candidate; [current acceptance](plans/preset-gallery-improvements/RELIABILITY_0870.md)','0.86.6 Max 2027; [current acceptance](plans/preset-gallery-improvements/DELIVERY_0866.md)').replace('| Receiver-aware maps, reusable Paint, portable example distributions and lifecycle fixes |','| Surface painting restoration, retaining the corrected 0.86.5 library/Amount baseline |');p.write_text(s,encoding='utf-8')
p=ROOT/'docs/Current_System_2026-10-05/CAPABILITY_MATRIX.md';s=p.read_text(encoding='utf-8').replace('Vector Paint Areas require single-valued local-XY terrain/planes; geometry changes are guarded','Vector Paint Areas support terrain and manifold curved receivers; indexed geometry changes are guarded').replace('Canonical Boolean Paint/Erase on projected terrain; cached borders; inward/outward feather and separate density/scale curves','Canonical Boolean Paint/Erase on terrain or surface-attached face regions; cached 3D borders; surface-distance feather and separate density/scale curves').replace('Physical input, heavy assets, sustained memory/latency and wider surface representations','Physical mouse/tablet input, heavier assets and sustained stress beyond the scoped 0.86.6 tests').replace('Folded/stacked Paint receivers reject;','Terrain preset transfer requires a single-valued XY footprint; curved preset transfer requires matching indexed topology;');p.write_text(s,encoding='utf-8')
p=ROOT/'docs/BACKLOG.md';s=p.read_text(encoding='utf-8');s=s.replace('## Next engineering work','''## Surface brush restoration — 0.86.6

The terrain-only restriction introduced in 0.78 is superseded by the
[0.86.6 delivery](plans/preset-gallery-improvements/DELIVERY_0866.md): spheres,
boxes and manifold curved receivers retain vector Paint/Erase, fade curves,
history and persistence. Native assertions, actual Max Painter callbacks and
generated UI handlers qualify the listed scope. Physical tablet/mouse and
production-scene stress remain separate. The prior reliability feature baseline
is corrected to 0.86.5; original 0.87.0 evidence below retains its actual label.

## Next engineering work''',1);p.write_text(s,encoding='utf-8')
