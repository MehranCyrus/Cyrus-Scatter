"""Validate artist-authored Chaos layers using exported model/transform multisets."""
import argparse
from collections import Counter
import json
from pathlib import Path
import re
from analyze_chaos import read


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--run',type=Path,required=True);args=parser.parse_args()
    names=['before_strokes','two_receivers','curved_stroke','curved_removed','curved_restored','upper_overlap','upper_erased']
    cases={};rows={};records={}
    for name in names:
        meta,data=read(args.run/'host'/f'paint_{name}.tsv')
        assert meta['instances']==400,(name,meta)
        for row in data:
            xyz=[float(v) for v in row['position'].split(',')]
            row['receiver']='flat' if xyz[0]<150 else 'curved'
            assert (-51<=xyz[0]<=51 and abs(xyz[2])<0.001) if row['receiver']=='flat' else (249<=xyz[0]<=351), (name,xyz)
        counts=Counter((r['receiver'],r['full'][1]) for r in data)
        meta['receiver_models']={f'{a}/{b}':n for (a,b),n in counts.items()}
        meta.pop('by_receiver')  # The shared reader's three-plane labels do not apply to this fixture.
        meta['unique_full_transforms']=len(Counter(r['full'] for r in data))
        meta['unique_positions']=len(Counter(r['position'] for r in data))
        sphere_z=[float(r['position'].split(',')[2]) for r in data if r['receiver']=='curved' and r['full'][1]=='Sphere']
        if sphere_z:meta['painted_sphere_z_cm']=[min(sphere_z),max(sphere_z)]
        cases[name]=meta;rows[name]=data
        records[name]=(args.run/'host'/f'paint_{name}_records.txt').read_text(encoding='utf-8-sig')
    assert cases['before_strokes']['receiver_models'].get('flat/Sphere',0)==0
    assert cases['before_strokes']['receiver_models'].get('curved/Sphere',0)==0
    assert cases['curved_stroke']['receiver_models'].get('curved/Sphere',0)>0
    assert cases['curved_removed']['receiver_models'].get('curved/Sphere',0)==0
    assert cases['curved_restored']['receiver_models'].get('curved/Sphere',0)==0
    assert cases['upper_overlap']['receiver_models'].get('flat/Sphere',0)==0
    assert cases['upper_erased']['receiver_models'].get('flat/Sphere',0)>0
    comparisons=[]
    for a,b in [('before_strokes','two_receivers'),('two_receivers','curved_stroke'),('two_receivers','curved_restored'),('curved_restored','upper_overlap'),('curved_restored','upper_erased')]:
        ca=lambda key:Counter(r[key] for r in rows[a]);cb=lambda key:Counter(r[key] for r in rows[b])
        comparisons.append({'before':a,'after':b,'same_position':sum((ca('position')&cb('position')).values()),'same_full_transform_model':sum((ca('full')&cb('full')).values())})
    output={'method':'MAXScript text multisets; no native IDs; click-only curved attempt in two_receivers did not author a curved stroke','cases':cases,'comparisons':comparisons,'public_records':records}
    (args.run/'chaos-paint-results.json').write_text(json.dumps(output,indent=2),encoding='utf-8')
    print(json.dumps({'cases':cases,'comparisons':comparisons},indent=2))


if __name__=='__main__':main()
