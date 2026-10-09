"""Analyze only corrected zero-based Forest captures; reject invalid model IDs."""
import argparse
from collections import Counter
import json
from pathlib import Path
import re


def main():
    p=argparse.ArgumentParser();p.add_argument('--run',type=Path,required=True);args=p.parse_args()
    names=['forest_paint_valid_baseline','forest_paint_add_far','forest_paint_remove_far','forest_paint_no_receiver','forest_paint_restore_receiver','forest_two_regions','forest_two_regions_removed_receiver_two','forest_two_regions_restored','forest_overlap_include','forest_overlap_exclude_upper','forest_overlap_include_restored','forest_after_interface_redraw']
    out={'precision':'MAXScript matrix text; zero-based tree indices; model+transform multisets','cases':{}}
    base=None
    for name in names:
        path=args.run/'host'/('valid_'+name+'.txt')
        if not path.exists():continue
        lines=path.read_text(encoding='utf-8-sig').splitlines();count=int(re.search(r'count (\d+)',lines[0])[1]);rows=[]
        for line in lines:
            if not line.startswith('tree '):continue
            _,index,model,matrix=line.split(' ',3)
            assert int(model)>0, (path,index,model)
            rows.append((model,matrix))
        assert len(rows)==count,(path,count,len(rows))
        c=Counter(rows)
        if base is None:base=c
        out['cases'][name]={'count':count,'update_ms':int(re.search(r'updateMs (\d+)',lines[0])[1]),'original_full_transforms_retained':sum((base&c).values()),'unique_model_transforms':len(c),'duplicate_extra':count-len(c)}
    (args.run/'forest-results-corrected.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))


if __name__=='__main__':main()
