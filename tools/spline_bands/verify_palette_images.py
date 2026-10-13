"""Check actual retained/fallback image geometry and Band colors; no image edits."""
import argparse
import hashlib
import json
from pathlib import Path
import uuid
from PIL import Image


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('capture',type=Path)
    args=parser.parse_args();capture=json.loads(args.capture.read_text(encoding='utf-8'))
    root=Path(__file__).resolve().parents[2];folder=args.capture.resolve().parent
    if folder.parent!=root/'build/mcp-qualification' or not folder.name.startswith('foundation-spline-'):
        raise ValueError('An owned spline capture is required')
    report={'capture':str(args.capture.resolve()),'capture_sha256':hashlib.sha256(args.capture.read_bytes()).hexdigest(),
            'checks':[],'counts':{},'passed':False}
    output=folder/('palette-image-verification-'+uuid.uuid4().hex+'.json')
    def save():output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    def check(ok,label):
        report['checks'].append({'passed':bool(ok),'label':label});save()
        if not ok:raise AssertionError(label)
    data={};raw={};sizes={}
    for entry in capture['images']:
        path=Path(entry['path']).resolve()
        if path.parent!=folder or hashlib.sha256(path.read_bytes()).hexdigest()!=entry['sha256']:
            raise ValueError('Capture path/identity mismatch')
        with Image.open(path) as image:
            width,height=image.size;pixels=list(image.convert('RGB').getdata())
        raw[entry['label']]=pixels;sizes[entry['label']]=(width,height)
        masks={c:set() for c in ('red','green','blue','gray')}
        for index,(r,g,b) in enumerate(pixels):
            x,y=index%width,index//width
            if not (.1*width<x<.9*width and .15*height<y<.85*height):continue
            for name,value,a,c in (('red',r,g,b),('green',g,r,b),('blue',b,r,g)):
                # Exclude mixed edge pixels where the colored viewport grid is
                # antialiased into an instance edge. Test unambiguous color pixels.
                if value>80 and a==0 and c==0:masks[name].add(index)
            if min(r,g,b)>80 and max(r,g,b)-min(r,g,b)<4:masks['gray'].add(index)
        data[entry['label']]=masks;report['counts'][entry['label']]={c:len(v) for c,v in masks.items()}
    for suffix,threshold in (('',1000),):
        if suffix and 'retained-red-blue-unbanded'+suffix not in data:continue
        first=data['retained-red-blue-unbanded'+suffix];second=data['retained-green-blue-unbanded'+suffix];fallback=data['fallback-green-blue-unbanded'+suffix]
        mode='Points' if suffix else 'Mesh'
        check(all(len(first[c])>threshold for c in ('red','blue','gray')),mode+': retained display visibly shows red, blue and Unbanded')
        check(len(second['green'])>threshold and len(second['red'])<20,mode+': actual recolor changes red to green')
        check(first['red']==second['green'],mode+': recolor preserves every detected solid-color pixel of the changed instance')
        check(first['blue']==second['blue'] and first['gray']==second['gray'],mode+': recolor preserves unchanged Band and Unbanded pixels')
        for color in ('green','blue','gray'):
            union=second[color]|fallback[color];overlap=len(second[color]&fallback[color])/len(union) if union else 0
            check(overlap>.90,f'{mode}/{color}: retained and CPU fallback silhouettes agree above 90% IoU ({overlap:.6f})')
    if 'retained-red-blue-unbanded-points' in raw:
        # Nitrous uses antialiased one-pixel points; GraphicsWindow fallback has
        # a larger marker footprint. Isolate scene pixels from an actual empty
        # capture and compare every grid point's centroid, not unequal coverage.
        background=raw['empty-background'];width,height=sizes['empty-background']
        def point_masks(label):
            if sizes[label]!=(width,height):raise ValueError('Viewport dimensions changed')
            masks={c:set() for c in ('red','green','blue','gray')}
            for index,(pixel,base) in enumerate(zip(raw[label],background)):
                x,y=index%width,index//width
                if not (.1*width<x<.9*width and .15*height<y<.85*height):continue
                if max(abs(a-b) for a,b in zip(pixel,base))<12:continue
                r,g,b=pixel
                for name,value,a,c in (('red',r,g,b),('green',g,r,b),('blue',b,r,g)):
                    if value>max(a,c)+20:masks[name].add((x,y))
                if max(pixel)-min(pixel)<6 and sum(pixel)>sum(base)+24:masks['gray'].add((x,y))
            return masks
        def centers(mask):
            remaining=set(mask);result=[]
            while remaining:
                start=remaining.pop();pending=[start];group=[start]
                while pending:
                    x,y=pending.pop()
                    for dx,dy in ((-1,-1),(0,-1),(1,-1),(-1,0),(1,0),(-1,1),(0,1),(1,1)):
                        p=(x+dx,y+dy)
                        if p in remaining:remaining.remove(p);pending.append(p);group.append(p)
                result.append((sum(p[0] for p in group)/len(group),sum(p[1] for p in group)/len(group)))
            return result
        first=point_masks('retained-red-blue-unbanded-points')
        second=point_masks('retained-green-blue-unbanded-points')
        fallback=point_masks('fallback-green-blue-unbanded-points')
        report['point_components']={}
        check(first['red']==second['green'],'Points: recolor preserves colored point pixels')
        check(first['blue']==second['blue'] and first['gray']==second['gray'],'Points: unchanged Band and Unbanded preserve their pixels')
        check(not second['red'] and not first['green'],'Points: no obsolete or unexpected identification color')
        for color in ('green','blue','gray'):
            a=centers(second[color]);b=centers(fallback[color])
            report['point_components'][color]={'retained':len(a),'fallback':len(b)}
            check(len(a)==441 and len(b)==441,f'Points/{color}: both displays contain all 441 separate points')
            def distance(x,y):return (x[0]-y[0])**2+(x[1]-y[1])**2
            displacement=max([min(distance(x,y) for y in b) for x in a]+[min(distance(x,y) for y in a) for x in b])**.5
            report['point_components'][color]['max_centroid_distance_pixels']=displacement
            check(displacement<=1.5,f'Points/{color}: every center matches within 1.5 pixels ({displacement:.6f})')
    report['passed']=True;save();print(output)


if __name__=='__main__':main()
