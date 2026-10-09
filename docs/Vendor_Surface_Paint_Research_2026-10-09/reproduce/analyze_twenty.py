"""Validate the split-callback 20-to-21 campaign before comparing transforms."""
import argparse,json,re
from collections import Counter
from pathlib import Path

def main():
    p=argparse.ArgumentParser();p.add_argument('--run',type=Path,required=True);a=p.parse_args();out=[]
    for mode in ['fixed','density']:
        cases=[]
        for action in ['baseline','add']:
            name='split_twenty_'+mode+'_'+action
            lines=(a.run/'host'/(name+'.tsv')).read_text().splitlines()
            parsed=[]
            for line in lines[1:]:
                row=line.split('\t');x=float(re.findall(r'\[([^\]]+)\]',row[2])[-1].split(',')[0]);parsed.append((tuple(row),x))
            count=int(re.search(r'instances (\d+)',lines[0])[1]);expected=10500 if mode=='density' and action=='add' else 10000
            assert count==len(parsed)==expected,(name,count,len(parsed),expected)
            assert all(2950<=x<=9050 for row,x in parsed),name
            old=Counter(row for row,x in parsed if x<8950)
            if action=='add':assert count>sum(old.values()),'No placements on added surface; stale result'
            cases.append((old,{'case':name,'count':count,'on_unchanged_receivers':sum(old.values()),'update_ms':int(re.search(r'updateMs (\d+)',lines[0])[1]),'convert_ms':int(re.search(r'convertMs (\d+)',lines[0])[1])}))
        out.append({'mode':mode,'cases':[c[1] for c in cases],'same_full_transform_model':sum((cases[0][0]&cases[1][0]).values())})
    (a.run/'chaos-twenty-results.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))

if __name__=='__main__':main()
