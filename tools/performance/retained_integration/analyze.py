"""Summarize paired camera steps; do not label redraw time as presented FPS."""
import argparse
import csv
import json
import statistics
from pathlib import Path

def percentile(values, fraction):
    ordered = sorted(values)
    index = (len(ordered)-1)*fraction
    low = int(index)
    return ordered[low]+(ordered[min(low+1,len(ordered)-1)]-ordered[low])*(index-low)

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('directory',type=Path)
    args=parser.parse_args()
    output={}
    for path in sorted(args.directory.glob('*-frames.csv')):
        with path.open(encoding='utf-8-sig',newline='') as f:
            rows=list(csv.DictReader(f))
        arms={}
        for arm in ['off','gw','retained']:
            values=[float(row['step_ms']) for row in rows if row['arm']==arm]
            if values:
                arms[arm]={'steps':len(values),'median_ms':statistics.median(values),'p95_ms':percentile(values,.95),'p99_ms':percentile(values,.99)}
        output[path.stem]=arms
    (args.directory/'timing-summary.json').write_text(json.dumps(output,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(output,indent=2))

if __name__=='__main__':
    main()
