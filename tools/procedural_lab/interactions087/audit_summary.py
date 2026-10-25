"""Summarize an independent complete-mesh audit without printing every actor."""
import argparse,json
from pathlib import Path

p=argparse.ArgumentParser()
p.add_argument('input',type=Path)
p.add_argument('output',type=Path)
a=p.parse_args()
data=json.loads(a.input.read_text(encoding='utf-8-sig'))
audit=data['full_mesh_audit'];rows=audit['results']
assert rows and audit['triangles']==sum(x['triangles'] for x in rows)
result={
    'scope':audit['scope'],
    'actors':len(rows),'triangles':audit['triangles'],
    'penetrating_vertex_obstacle_pairs':sum(x['penetrating_vertex_obstacle_pairs'] for x in rows),
    'touching_triangle_obstacle_pairs':sum(x['touching_triangle_obstacle_pairs'] for x in rows),
    'root_anchor_error_m':max(x['root_anchor_error_m'] for x in rows),
    'maximum_stem_edge_change':max(x['maximum_stem_edge_change'] for x in rows),
    'maximum_rigid_part_edge_change':max(x['maximum_rigid_part_edge_change'] for x in rows),
    'audit_seconds':sum(x['audit_ms'] for x in rows)/1000,
    'worst_stem_actor':max(rows,key=lambda x:x['maximum_stem_edge_change']),
    'trial_limits':{'root_anchor_error_m':1e-7,'maximum_stem_edge_change':.25,'maximum_rigid_part_edge_change':1e-6},
    'limitation':'The 25% stem-edge ceiling is a coarse artist-trial quality gate, not a biomechanical or natural-bending guarantee. No claim for untested poses, self-collision or renderer float rounding.'}
result['status']='pass' if (result['penetrating_vertex_obstacle_pairs']==result['touching_triangle_obstacle_pairs']==0 and
    all(result[k]<=v for k,v in result['trial_limits'].items())) else 'failed'
a.output.write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
raise SystemExit(0 if result['status']=='pass' else 1)
