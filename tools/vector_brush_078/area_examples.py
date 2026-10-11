"""Append point-only inspection cases through pymxs in an owned Max host.

No reset, model meshes, plugin edits, or input injection. Reference tests use
Python polygon parity and Euclidean segment distances, independently of Cyrus.
"""
from pathlib import Path
import json, math, time, traceback
from pymxs import runtime as rt

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(rt.MCPFixtureDir)).resolve()
if OUT.parent != ROOT/'build/vector-brush-078': raise RuntimeError('Owned host required')
rt.fileIn(str(Path(__file__).with_name('area_examples_helpers.ms')))
M=float(rt.QA_Metre)
cases=[]; checks=[]
def arr(x): return rt.Array(*x)
def p3(x,y,z=0): return rt.Point3(x*M,y*M,z*M)
def check(value,label,**evidence):
    checks.append(dict(passed=bool(value),label=label,**evidence))
    write_results()
def write_results():
    data=dict(product='0.78.3',checks=checks,cases=[{k:v for k,v in c.items() if k in ('number','title','center','count','milliseconds','node_name')} for c in cases])
    (OUT/'area-examples-results.json').write_text(json.dumps(data,indent=2))
def point(v): return (float(v.x)/M,float(v.y)/M)
def rows(c):
    return [dict(id=str(row[2]),xy=point(row[0].row4),source=int(row[1]),scale=float(rt.length(row[0].row1))) for row in c['root'].groupSnapshotRows[0]]
def update(c):
    started=time.perf_counter();c['root'].refreshAll()
    c['milliseconds']=round((time.perf_counter()-started)*1000,2)
    error=str(c['leaf'].previewError)
    if error: raise RuntimeError(c['title']+': '+error)
    c['count']=len(c['root'].groupSnapshotRows[0]);write_results()
    return rows(c)
def new(title,sources=1):
    n=len(cases)+1;center=(6+(n-1)%4*3.4,-((n-1)//4)*3.6)
    obj=rt.QA_NewCase(title,p3(*center),number=n,sources=sources)
    c=dict(number=n,title=title,center=center,obj=obj,node=obj[0],leaf=obj[1],receiver=obj[2],bucket=obj[3],root=obj[0].baseObject,bands=[],areas=[],node_name=str(obj[0].name))
    cases.append(c);rt.QA_Pump(120)
    c['base']=update(c)
    check(len(c['base'])==2400,title+': full receiver candidate reference')
    return c
def line(c,name,vertices,loops=None,scale=(1,1,1),angle=0,offset=(0,0),pivot=(0,0)):
    node=rt.splineShape(name='CSQA_'+str(c['number'])+'_'+name)
    for loop in (loops or [vertices]):
        rt.addNewSpline(node);index=int(rt.numSplines(node))
        for x,y in loop: rt.addKnot(node,index,rt.Name('corner'),rt.Name('line'),p3(x,y))
        rt.close(node,index)
    rt.updateShape(node)
    node.scale=rt.Point3(*scale);node.rotation=rt.angleAxis(angle,rt.Point3(0,0,1))
    node.pos=p3(c['center'][0]+offset[0],c['center'][1]+offset[1])
    if pivot!=(0,0): node.objectOffsetPos=p3(*pivot)
    node.renderable=False;node.wirecolor=rt.color(255,205,70);c['bucket'].addNode(node)
    # Independent world knot reads include pivot/object offset, rotation and scale.
    paths=[]
    rt.QA_ReferenceNode=node
    for i in range(1,int(rt.numSplines(node))+1):
        paths.append([point(rt.execute(f'in coordsys world getKnotPoint QA_ReferenceNode {i} {k}')) for k in range(1,int(rt.numKnots(node,i))+1)])
    return node,paths
def rect(c,name,w=1.4,h=1.0,**kw): return line(c,name,[(-w/2,-h/2),(w/2,-h/2),(w/2,h/2),(-w/2,h/2)],**kw)
def inside(p,paths):
    result=False
    for loop in paths:
        for a,b in zip(loop,loop[1:]+loop[:1]):
            if (a[1]>p[1])!=(b[1]>p[1]) and p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]: result=not result
    return result
def distance(p,paths):
    best=float('inf')
    for loop in paths:
        for a,b in zip(loop,loop[1:]+loop[:1]):
            dx,dy=b[0]-a[0],b[1]-a[1];den=dx*dx+dy*dy
            t=max(0,min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/den)) if den else 0
            best=min(best,math.hypot(p[0]-a[0]-t*dx,p[1]-a[1]-t*dy))
    return best
def band(c,guide,side=2,width=.2,slot=1):
    index=rt.QA_AddBand(c['obj'],guide[0],side,width*M,slot)
    cumulative=width+sum(b['width'] for b in c['bands'] if b['node']==str(guide[0].name) and b['side']==side)
    c['bands'].append(dict(node=str(guide[0].name),paths=guide[1],side=side,width=width,cumulative=cumulative,slot=slot,index=index))
def area(c,guide,mode):
    rt.QA_AddArea(c['obj'],guide[0],mode)
    guide[0].wirecolor=rt.color(90,220,140) if mode==1 else rt.color(255,90,90)
    c['areas'].append(dict(node=guide[0],paths=guide[1],mode=mode))
def expected(c,base):
    result={}
    for row in base:
        p=row['xy'];includes=[a for a in c['areas'] if a['mode']==1]
        if includes and not any(inside(p,a['paths']) for a in includes): continue
        if any(inside(p,a['paths']) for a in c['areas'] if a['mode']==2): continue
        slot=None
        if c['bands']:
            for b in c['bands']:
                if inside(p,b['paths'])==(b['side']==2) and distance(p,b['paths'])<=b['cumulative']+1e-6:
                    slot=b['slot'];break
            if slot is None: continue
        result[row['id']]=(row,slot)
    return result
def verify(c):
    actual=update(c);want=expected(c,c['base']);got={r['id']:r for r in actual}
    check(set(got)==set(want),c['title']+': exact geometric membership',accepted=len(got),expected=len(want),unexpected=len(set(got)-set(want)),missing=len(set(want)-set(got)))
    check(all(math.dist(r['xy'],want[k][0]['xy'])<1e-5 and (want[k][1] is None or r['source']==want[k][1]) for k,r in got.items() if k in want),c['title']+': positions and band source assignment')
    check(int(c['leaf'].cachedPointCount)==len(actual),c['title']+': one visible marker per point')
    return actual

rt.execute('global QA_PreviousHeld=CyrusInteractionHeld\nfn CyrusInteractionHeld = false')
try:
    c=new('Inside 200 mm');g=rect(c,'Guide');band(c,g);verify(c)
    c=new('Outside 200 mm');g=rect(c,'Guide');band(c,g,1);verify(c)
    c=new('Spline scale 40 pct - width 200 mm');g=rect(c,'Scaled',scale=(.4,.4,.4));band(c,g,1);verify(c)
    c=new('Nonuniform rotated - width 200 mm');g=rect(c,'Scaled_Rotated',scale=(1.4,.5,1),angle=32);band(c,g,1);verify(c)
    c=new('Object offset - width 200 mm');g=rect(c,'PivotOffset',pivot=(.25,-.2),angle=-22);band(c,g,1);verify(c)
    c=new('Two inside bands - 200 plus 200 mm',2);g=rect(c,'Guide',w=2,h=1.7);band(c,g,2,.2,1);band(c,g,2,.2,2);verify(c)
    c=new('Include only');g=rect(c,'Include',w=1.6,h=1.3);area(c,g,1);verify(c)
    c=new('Exclude only');g=rect(c,'Exclude',w=1.6,h=1.3);area(c,g,2);verify(c)
    c=new('Include union - overlapping shapes');a=rect(c,'Include_A',offset=(-.4,0));b=rect(c,'Include_B',offset=(.4,.2));area(c,a,1);area(c,b,1);verify(c)
    c=new('Exclude wins within Include');a=rect(c,'Include',w=2,h=1.8);b=rect(c,'Exclude',w=.55,h=2.2,angle=20);area(c,a,1);area(c,b,2);verify(c)
    c=new('Scaled rotated Include');g=rect(c,'Include',scale=(1.4,.5,1),angle=32,pivot=(.15,0));area(c,g,1);verify(c)
    c=new('Concave Include plus Exclude');a=line(c,'L_Include',[(-1,-1),(1,-1),(1,-.35),(-.2,-.35),(-.2,1),(-1,1)]);b=rect(c,'Exclude',w=.5,h=.5,offset=(-.55,.15));area(c,a,1);area(c,b,2);verify(c)
    c=new('One spline with a hole');outer=[(-1,-1),(1,-1),(1,1),(-1,1)];inner=[(-.4,-.4),(.4,-.4),(.4,.4),(-.4,.4)];g=line(c,'Donut',outer,loops=[outer,inner]);area(c,g,1);verify(c)
    c=new('Spline band clipped by Exclude',2);g=rect(c,'Band',w=1.6,h=1.5);band(c,g,2,.2,1);band(c,g,1,.2,2);cut=rect(c,'Exclude',w=.45,h=2.6,angle=35);area(c,cut,2);verify(c)
    # Independent falloff widths and source-radius scaling remain visible as rings.
    c=new('Delete 100 mm then scale 300 mm');g=rect(c,'Include',w=2,h=2);area(c,g,1)
    baseline=verify(c);leaf=c['leaf'];leaf.setFallConfig(g[0],arr([True,.1*M,True,.3*M,arr([.2,1]),False,.3*M,arr([0,1])]))
    leaf.setSourceRadius(rt.execute('#{1}'),.04*M);leaf.setSourceRadius(rt.execute('#{1}'),True,kind=2);leaf.setSourceRadius(rt.execute('#{1}'),True,kind=3)
    actual=update(c);want={r['id']:r for r in baseline if distance(r['xy'],g[1])>=.1}
    check({r['id'] for r in actual}==set(want),'Delete strip: exact 100 mm support distance')
    check(all(abs(r['scale']-(.2+.8*min(1,max(0,(distance(r['xy'],g[1])-.1)/.3))))<2e-4 for r in actual),'Scale ramp starts after deletion and follows curve')
    radii=list(c['root'].procPublishedRadii[0]);check(all(abs(float(v)/M-.04*r['scale'])<1e-5 for v,r in zip(radii,actual)),'Follow Scale multiplies point radius by final ramp scale')
    c=new('Density edge fade 400 mm');g=rect(c,'Include',w=2,h=2);area(c,g,1);baseline=verify(c)
    c['leaf'].setFallConfig(g[0],arr([False,0,False,.4*M,arr([0,1]),True,.4*M,arr([0,0,1,1])]))
    actual=update(c);check(0<len(actual)<len(baseline),'Density curve thins point population')
    check(all(distance(r['xy'],g[1])>=.4/3-1e-5 for r in actual),'Density curve zero endpoint removes its full edge interval')
    keep={r['id'] for r in actual};check(all(r['id'] in keep for r in baseline if distance(r['xy'],g[1])>=.8/3+1e-5),'Density curve full endpoint retains interior candidates')
    check(keep=={r['id'] for r in update(c)},'Density thinning is deterministic on unchanged Update')
    c=new('Band scales 0.5 to 1.5 - radius 40 mm');g=rect(c,'Guide',w=2,h=2);band(c,g,2,.5);i=c['bands'][0]['index']-1
    c['leaf'].strokeMin[i]=.5;c['leaf'].strokeMax[i]=1.5
    c['leaf'].setSourceRadius(rt.execute('#{1}'),.04*M);c['leaf'].setSourceRadius(rt.execute('#{1}'),True,kind=2);c['leaf'].setSourceRadius(rt.execute('#{1}'),True,kind=3)
    actual=verify(c);check(all(.4999<=r['scale']<=1.5001 for r in actual) and min(r['scale'] for r in actual)<.6 and max(r['scale'] for r in actual)>1.4,'Band min/max scales cover configured range')
    radii=list(c['root'].procPublishedRadii[0]);check(all(abs(float(v)/M-.04*r['scale'])<1e-5 for v,r in zip(radii,actual)),'Band scaling and Follow Scale produce correct point radii')
    c=new('Spacing - radius 80 mm plus gap 20 mm');g=rect(c,'Include',w=2.4,h=2.4);area(c,g,1)
    c['leaf'].setSourceRadius(rt.execute('#{1}'),.08*M);c['leaf'].setSourceRadius(rt.execute('#{1}'),True,kind=3)
    c['leaf'].procLayerSelfEnabled=True;c['leaf'].procLayerSelfMultiplier=1;c['leaf'].procLayerSelfGap=.02*M
    actual=update(c);minimum=min(math.dist(a['xy'],b['xy']) for i,a in enumerate(actual) for b in actual[i+1:])
    check(len(actual)>10 and minimum>=.18-1e-5,'Point spacing equals radius A plus radius B plus gap',minimum_m=minimum,expected_m=.18)
    rt.CyrusPointSync();rt.redrawViews()
    rt.saveMaxFile(str(OUT/'Include_Exclude_Point_Examples.max'),quiet=True)
    write_results()
except Exception:
    (OUT/'area-examples-error.txt').write_text(traceback.format_exc())
    raise
finally:
    rt.execute('CyrusInteractionHeld=QA_PreviousHeld')
