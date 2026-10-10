"""Check recorded native rectangles without screenshots or pointer automation."""
import argparse,json
from pathlib import Path

def validate(path):
    records=json.loads(path.read_text());clipped=[];overlaps=[];rectangles=0;controls=set()
    for case in records:
        for page in case['pages']:
            labels=[c for c in page['controls'] if c['type']=='LabelControl' and c['rects']]
            if not labels:raise ValueError('No native origin anchor: '+page['page'])
            anchor=labels[0];origin=[anchor['rects'][0][axis]-anchor['pos'][i] for i,axis in enumerate(('x','y'))]
            boxes=[]
            for control in page['controls']:
                controls.add((page['page'],control['name']))
                for box in control['rects']:
                    # Native MAXScript controls retain empty caption HWNDs.
                    if box['class']=='Static' and not box['text']:continue
                    if box['w']<=0 or box['h']<=0:continue
                    rectangles+=1;x=box['x']-origin[0];y=box['y']-origin[1]
                    if x<0 or y<0 or x+box['w']>page['width'] or y+box['h']>page['height']:
                        clipped.append([case['context'],page['page'],control['name'],[x,y,box['w'],box['h']]])
                    boxes.append((control['name'],box))
            for i,(a_name,a) in enumerate(boxes):
                for b_name,b in boxes[i+1:]:
                    if a_name==b_name:continue
                    width=min(a['x']+a['w'],b['x']+b['w'])-max(a['x'],b['x'])
                    height=min(a['y']+a['h'],b['y']+b['h'])-max(a['y'],b['y'])
                    if width>1 and height>1:overlaps.append([case['context'],page['page'],a_name,b_name,width,height])
    result={'contexts':len(records),'rectangles_checked':rectangles,'unique_control_names':len(controls),
            'clipped':clipped,'overlaps':overlaps,'passed':len(records)==36 and not clipped and not overlaps,
            'scope':'Native bounds at current display scaling; not font glyph, DPI, visual or pointer qualification'}
    path.with_name('layout-result.json').write_text(json.dumps(result,indent=2)+'\n')
    return result

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('path',type=Path);args=p.parse_args()
    result=validate(args.path);print(json.dumps(result,indent=2));raise SystemExit(0 if result['passed'] else 1)
