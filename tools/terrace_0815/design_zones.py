"""Derive editable planting beds from measured scene meshes; preserve the architecture."""
from pathlib import Path
import json,math
import numpy as np
from shapely.geometry import Polygon,LineString,Point,box
from shapely.ops import unary_union,triangulate
from scipy.interpolate import LinearNDInterpolator
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/mcp-qualification/foundation-terrace0815-candidate2027-03'
data=json.loads((OUT/'scene-layout-data.json').read_text())
pos=np.array([-8947.1914,-4304.0986]);forward=np.array([.824095,.566385]);right=np.array([.566406,-.824127])
def camera_point(depth,lateral):return pos+forward*depth+right*lateral
wedge=Polygon([camera_point(400,-600),camera_point(21000,-11100),camera_point(21000,11100),camera_point(400,600)])
pathknots=next(g['curves'][0]['knots'] for g in data['guides'] if g['name']=='spl-path')
path=LineString([p[:2] for p in pathknots]);patharea=path.buffer(85,join_style=1)
building=box(-540,-490,2230,1850)
zones=[];polys=[];zfields=[]
def parts(p):return [p] if p.geom_type=='Polygon' else [g for g in p.geoms if g.geom_type=='Polygon']
def mesh(poly,zfunc,name,kind,original):
    vertices=[];faces=[];area=0
    for part in parts(poly):
        if part.area<20:continue
        for triangle in triangulate(part):
            if not part.covers(triangle):continue
            points=list(triangle.exterior.coords)[:3]
            if (points[1][0]-points[0][0])*(points[2][1]-points[0][1])-(points[1][1]-points[0][1])*(points[2][0]-points[0][0])<0:points.reverse()
            start=len(vertices)+1
            for x,y in points:vertices.append([x,y,float(zfunc(x,y))])
            faces.append([start,start+1,start+2]);area+=triangle.area
    if faces:zones.append(dict(name=name,kind=kind,original=original,area_m2=area/10000,vertices=vertices,faces=faces))
for i,item in enumerate(data['receivers']):
    v=np.array(item['vertices']);f=np.array(item['faces'],int)-1
    poly=unary_union([Polygon(t[:,:2]) for t in v[f] if Polygon(t[:,:2]).area>.01]).buffer(0)
    if i==0:
        interp=LinearNDInterpolator(v[:,:2],v[:,2],fill_value=float(v[:,2].mean()));zfunc=lambda x,y,ip=interp:float(ip(x,y))
    else:
        z=float(v[:,2].mean());zfunc=lambda x,y,z=z:z
    polys.append(poly);zfields.append(zfunc)
    visible=poly.intersection(wedge).difference(building)
    if i==0:visible=visible.difference(patharea)
    mesh(visible,zfunc,'PLANTING | %02d grass footprint'%(i+1),'grass',item['name'])
    if i==10:continue
    bed=poly.buffer(-65 if i else -100).intersection(wedge).difference(building)
    if i==0:bed=bed.difference(patharea.buffer(35))
    # Broad coherent sweeps broken into irregular-length blocks along each real terrace.
    for j,x in enumerate(range(-14500,17000,1800)):
        piece=bed.intersection(box(x,-10000,x+1550,15000))
        kind=['white','pink','yellow'][(i+j//2)%3]
        mesh(piece,zfunc,'PLANTING | %02d %s drift %02d'%(i+1,kind,j),kind,item['name'])
    if i in (1,3,5,7,9):
        shrub=poly.buffer(-100).intersection(wedge).difference(building.buffer(150))
        mesh(shrub,zfunc,'PLANTING | %02d shrub structure'%(i+1),'shrubs',item['name'])
# Palm and tree receivers are deliberately small, editable placement patches.
def patch(kind,index,depth,lateral,radius):
    p=camera_point(depth,lateral)
    for poly,zfunc in zip(polys,zfields):
        zone=poly.intersection(Point(*p).buffer(radius,resolution=8))
        if not zone.is_empty:mesh(zone,zfunc,'PLANTING | %s accent %02d'%(kind,index),kind,'measured terrace')
for i,(depth,lateral) in enumerate([(1800,-650),(2200,700),(3400,-850),(4400,200),(5700,-900),(6500,1800),(7900,-1200),(9000,2300),(10000,-2700),(11000,3300)]):patch('palms',i,depth,lateral,180)
for i,(depth,lateral) in enumerate([(1750,-850),(2150,1000),(5300,-2050),(6700,2300),(8600,-3200)]):patch('trees',i,depth,lateral,25)
for i,(depth,lateral) in enumerate([(12500,-4800),(14000,-4500),(14500,-3200),(16000,-1800),(17000,0),(17500,2000),(17200,4500),(15700,6500),(14200,6500),(12700,6500)]):patch('background',i,depth,lateral,350)
steps=[]
for d in np.arange(80,min(path.length,4100),72):
    p=path.interpolate(d);before=path.interpolate(max(0,d-5));after=path.interpolate(d+5)
    if not polys[0].covers(p):continue
    steps.append([p.x,p.y,zfields[0](p.x,p.y)+7,math.degrees(math.atan2(after.y-before.y,after.x-before.x))-90])
result=dict(zones=zones,steps=steps,path_outline=[list(p)+[-950] for p in patharea.exterior.coords[:-1]])
(OUT/'planting-zones.json').write_text(json.dumps(result)+'\n')
print(json.dumps({k:{'meshes':sum(z['kind']==k for z in zones),'area_m2':round(sum(z['area_m2'] for z in zones if z['kind']==k),1)} for k in sorted(set(z['kind'] for z in zones))},indent=2))
