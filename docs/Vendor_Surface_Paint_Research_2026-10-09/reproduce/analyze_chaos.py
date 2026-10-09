"""Compare exported placements, not opaque vendor IDs or cache hits.

MAXScript matrix text has limited precision. Exact text matches mean equal at
that export precision; they are not proof of bitwise equality in native code.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import re


def read(path):
    lines=path.read_text(encoding='utf-8-sig').splitlines()
    header=lines[0]
    meta={k:int(re.search(rf'\b{k} (\d+)',header)[1]) for k in ['instances','updateResult','updateMs','converted','convertMs','nodes']}
    rows=[]
    for line in lines[1:]:
        model,kind,matrix=line.split('\t')
        vectors=re.findall(r'\[([^\]]+)\]',matrix)
        assert len(vectors)==4, line
        x=float(vectors[-1].split(',')[0])
        receiver=min(range(1,5),key=lambda n:abs(x-{1:0,2:400,3:900,4:2000}[n]))
        rows.append({'receiver':receiver,'position':vectors[-1],'full':(model,kind,matrix)})
    assert len(rows)==meta['nodes']==meta['instances'], (path,meta,len(rows))
    meta['by_receiver']=dict(Counter(r['receiver'] for r in rows))
    return meta,rows


def main():
    p=argparse.ArgumentParser();p.add_argument('--run',type=Path,required=True);args=p.parse_args()
    host=args.run/'host';output={'precision':'MAXScript default matrix text, no native IDs','cases':{},'comparisons':[]}
    names=['fixed_valid_baseline','fixed_repeat','fixed_add','fixed_restore','fixed_reverse_rebuild_list','fixed_order_restore','fixed_remove_middle','density_three','density_repeat','density_add','density_restore','density_reverse_rebuild_list','density_order_restore','density_remove_middle','density_move_first','density_move_restore','density_after_selection_redraw']
    rows={}
    for name in names: output['cases'][name],rows[name]=read(host/(name+'.tsv'))
    for name in names:
        baseline='fixed_valid_baseline' if name.startswith('fixed') else 'density_three'
        unchanged={1,2,3}
        if 'remove_middle' in name:unchanged={1,3}
        if 'move_first' in name:unchanged={2,3}
        a=[r for r in rows[baseline] if r['receiver'] in unchanged];b=[r for r in rows[name] if r['receiver'] in unchanged]
        shared=lambda key:sum((Counter(r[key] for r in a)&Counter(r[key] for r in b)).values())
        output['comparisons'].append({'baseline':baseline,'case':name,'unchanged_receivers':sorted(unchanged),'baseline_on_unchanged':len(a),'after_on_unchanged':len(b),'same_position':shared('position'),'same_full_transform_model':shared('full')})
    (args.run/'chaos-results.json').write_text(json.dumps(output,indent=2))
    print(json.dumps(output,indent=2))


if __name__=='__main__':main()
