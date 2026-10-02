"""Analyze synchronous redraw steps and unmodified captured image pairs."""
from pathlib import Path
import argparse,csv,json,statistics
from PIL import Image
import numpy as np
from build import BASE

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--run',required=True);args=parser.parse_args()
    run=(BASE/args.run).resolve()
    if run.parent!=BASE.resolve(): raise SystemExit('Invalid private run')
    report={'metric':'synchronous camera update + completeRedraw + message processing (ms), not presented FPS','timings':{},'image_pairs':{}}
    for path in sorted(run.glob('*-frames.csv')):
        rows=list(csv.DictReader(path.open()))
        arms={}
        for arm in sorted({row['arm'] for row in rows}):
            values=sorted(float(r['step_ms']) for r in rows if r['arm']==arm)
            arms[arm]={'count':len(values),'median_ms':statistics.median(values),'p95_ms':float(np.percentile(values,95)),'max_ms':max(values)}
        report['timings'][path.stem]=arms
    for retained in sorted(run.glob('*-retained.png')):
        legacy=retained.with_name(retained.name.replace('-retained.png','-gw.png'))
        if not legacy.exists(): continue
        a=np.asarray(Image.open(retained).convert('RGB'),dtype=np.int16)
        b=np.asarray(Image.open(legacy).convert('RGB'),dtype=np.int16)
        if a.shape!=b.shape: raise RuntimeError('Image sizes differ')
        delta=np.abs(a-b)
        report['image_pairs'][retained.stem]={'pixels':int(a.shape[0]*a.shape[1]),'mean_channel_difference_255':float(delta.mean()),'pixels_changed_percent':float(np.any(delta>0,axis=2).mean()*100),'pixels_difference_above_8_percent':float(np.any(delta>8,axis=2).mean()*100)}
    (run/'analysis.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))

if __name__=='__main__': main()
