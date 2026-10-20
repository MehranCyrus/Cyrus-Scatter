from pathlib import Path
root=Path(__file__).resolve().parents[2]
for name in ('AminScatter/tools/ui/templates/unified-core.ms','AminScatter/tools/ui/control-tooltips.json'):
 p=root/name;s=p.read_text(encoding='utf-8')
 s=s.replace("Export this area's closed contours and holes as an independent editable spline on the receiver's local XY plane (local Z=0). Keeps the Paint Area; selects the snapshot. Stop the brush first.","Export an independent editable border spline. Terrain uses local XY; curved receivers keep their 3D surface border. An unchanged surface snapshot restores exact coverage. Keeps the Paint Area. Stop the brush first.")
 s=s.replace("Pick one closed spline shape to apply to this Paint Area using Replace or Add. One Undo; Manual waits for Update. Stop the brush first.","Apply closed spline coverage using Replace or Add. Curved borders must lie on the receiver within Curve tolerance; edited closed-surface borders select the smaller enclosed region. One Undo; Manual waits for Update. Stop the brush first.")
 s=s.replace('Vector painting supports local XY terrain and planes; closed or overlapping receivers are rejected.','Vector painting supports terrain, spheres, boxes and manifold curved meshes. Curved strokes follow the surface without painting through to the opposite side. Degenerate or nonmanifold geometry requires repair.')
 p.write_text(s,encoding='utf-8')
