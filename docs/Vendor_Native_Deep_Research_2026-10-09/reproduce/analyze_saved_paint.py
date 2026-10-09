"""Validate public paint records and independently resolve their flat-scene anchors."""
import argparse
import json
import re
from pathlib import Path

def main():
    p=argparse.ArgumentParser();p.add_argument('--run',type=Path,required=True);a=p.parse_args()
    root=Path(__file__).resolve().parents[3];run=a.run.resolve();assert run.is_relative_to(root/'build')
    points=[];records=[];triangles={};receivers={}
    for line in (run/'host/saved-paint-decoded.tsv').read_text(encoding='utf-8-sig').splitlines():
        f=line.split('\t')
        if f[0]=='point':points.append(dict(index=int(f[1]),u=float(f[2]),v=float(f[3]),face=int(f[4])))
        elif f[0]=='record':records.append(dict(index=int(f[1]),count=int(f[2]),receiver=int(f[3]),layer=int(f[4]),operation=int(f[5]),radius=float(f[6])))
        elif f[0]=='receiver':receivers[int(f[1])-1]=dict(name=f[2],faces=int(f[3]),transform=f[4])
        elif f[0]=='triangle':
            vertices=[[float(x) for x in re.findall(r'-?\d+(?:\.\d+)?(?:e[+-]?\d+)?',v,re.I)] for v in f[3:6]]
            assert all(len(v)==3 for v in vertices)
            triangles[(int(f[1])-1,int(f[2]))]=vertices
    assert sum(r['count'] for r in records)==len(points)
    resolved=[];cursor=0
    for record in records:
        assert record['receiver'] in receivers and record['count']>0
        for point in points[cursor:cursor+record['count']]:
            assert 0<=point['face']<receivers[record['receiver']]['faces']
            assert point['u']>=0 and point['v']>=0 and point['u']+point['v']<=1.000001
            va,vb,vc=triangles[(record['receiver'],point['face'])]
            xyz=[va[i]+point['u']*(vb[i]-va[i])+point['v']*(vc[i]-va[i]) for i in range(3)]
            resolved.append(dict(**point,record=record['index'],receiver=record['receiver'],position_scene_units=xyz))
        cursor+=record['count']
    result=dict(points=len(points),records=records,receiver_faces={k:v['faces'] for k,v in receivers.items()},
                unique_anchors=len({(p['face'],p['u'],p['v']) for p in points}),resolved=resolved,
                coordinate_limit='Flat receiver has identity transform. Public MAXScript text precision only; no curved or nonidentity anchor reconstruction test.')
    (run/'saved-paint-analysis.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,indent=2))

if __name__=='__main__':main()
