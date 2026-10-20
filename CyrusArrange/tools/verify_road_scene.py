"""Independent actual-mesh car/curved-road acceptance. No native geometry/proxy.

Uses explicit source triangles, disjoint actual receiving tops, independent dense
Bezier arc inversion and curved-lane area coverage of the COMPLETE source box.
"""
import argparse
import copy
import hashlib
import json
import math
from collections import Counter
from itertools import combinations, product
from pathlib import Path
from verify_base_support import area, clip, hull, turn
from verify_shelves_stairs import (actual_base_points, bounds, cross, dot, integer,
                                  mesh_gap_certificate, read_meshes, require, sub)


def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def settings(path):
    result = {'control': [], 'region': {}}
    for line in Path(path).read_text().splitlines():
        words = line.split(); key = words[0]
        if key == 'region':
            result[key][integer(words[1])] = integer(words[2])
        elif key == 'control':
            result[key].append(tuple(map(float, words[1:])))
        elif key == 'seed':
            result[key] = [integer(words[1])]
        else:
            require(key not in result, 'Repeated road setting')
            result[key] = [float(v.rstrip('Ll').lower().replace('d','e')) for v in words[1:]]
    require(len(result['control']) == 4 and len(result['region']) <= 256, 'Invalid curve/region metadata')
    return result


def prove_closed(mesh):
    vertices, faces = mesh['vertices'], mesh['faces']
    edges, volumes = Counter(), Counter()
    parent=list(range(len(vertices)))
    def root(i):
        while parent[i]!=i:
            parent[i]=parent[parent[i]];i=parent[i]
        return i
    for face in faces:
        for i in face[1:3]:parent[root(i-1)]=root(face[0]-1)
    origin = vertices[0]
    for face in faces:
        ids = tuple(i-1 for i in face[:3])
        a,b,c = (vertices[i] for i in ids)
        require(dot(cross(sub(b,a),sub(c,a)),cross(sub(b,a),sub(c,a))) > 1e-12, 'Degenerate complete-model face')
        for i,j in zip(ids,ids[1:]+ids[:1]): edges[(i,j)] += 1
        volumes[root(ids[0])] += dot(sub(a,origin),cross(sub(b,origin),sub(c,origin)))/6
    require(all(n == 1 and edges[(b,a)] == 1 for (a,b),n in edges.items()), 'Actual mesh is not consistently closed')
    require(all(v>1. for v in volumes.values()), 'Actual mesh has reversed or empty solid component volume')
    return sum(volumes.values())


def overlap(a,b):
    return all(min(max(p[k] for p in a),max(p[k] for p in b)) >= max(min(p[k] for p in a),min(p[k] for p in b)) for k in range(2))


def tops(meshes):
    result = []
    for m in meshes:
        prove_closed(m)
        for face in m['faces']:
            p = [m['vertices'][i-1] for i in face[:3]]
            if all(abs(v[2]) <= .01 for v in p) and cross(sub(p[1],p[0]),sub(p[2],p[0]))[2] > 0:
                result.append([v[:2] for v in p])
    require(len(result) == 640, 'Road does not contain the complete authored five-band receiving top')
    work = 0
    for a,b in combinations(result,2):
        work += 1
        if overlap(a,b):
            work += 28
            require(area(clip(a,b)) < .001, 'Receiving triangles overlap and could hide a support hole')
    require(work <= 2000000, 'Static road proof work admission exceeded')
    return result


def coverage(poly, triangles, why):
    covered, work = 0., 0
    for t in triangles:
        work += 1
        if overlap(poly,t):
            work += len(poly)*9+1
            covered += area(clip(poly,t))
    require(work <= 2000000, 'Per-output polygon proof admission exceeded')
    total = area(poly)
    require(total > 1e-6 and abs(covered-total) <= max(.05,total*1e-8), why)
    return covered/total


class Curve:
    def __init__(self, controls):
        self.controls = controls
        self.count = 4096
        self.points = [self.point(i/self.count) for i in range(self.count+1)]
        self.prefix = [0.]
        for a,b in zip(self.points,self.points[1:]): self.prefix.append(self.prefix[-1]+math.dist(a,b))
        self.length = self.prefix[-1]

    def point(self,t):
        p=self.controls;u=1-t
        return tuple(p[0][k]*u**3+3*p[1][k]*u*u*t+3*p[2][k]*u*t*t+p[3][k]*t**3 for k in range(3))

    def frame(self,t):
        p=self.controls;u=1-t
        d=tuple(3*(p[1][k]-p[0][k])*u*u+6*(p[2][k]-p[1][k])*u*t+3*(p[3][k]-p[2][k])*t*t for k in range(3))
        n=math.sqrt(dot(d,d));d=tuple(x/n for x in d)
        return self.point(t),d,(-d[1],d[0],0)

    def closest(self, point):
        best = None
        for i,(a,b) in enumerate(zip(self.points,self.points[1:])):
            delta=sub(b,a);u=max(0.,min(1.,dot(sub(point,a),delta)/dot(delta,delta)))
            p=tuple(a[k]+u*delta[k] for k in range(3));distance=dot(sub(point,p),sub(point,p))
            if best is None or distance < best[0]: best=(distance,i,u,p)
        _,i,u,p=best;_,d,left=self.frame((i+u)/self.count)
        return self.prefix[i]+u*(self.prefix[i+1]-self.prefix[i]),dot(sub(point,p),left),d,left

    def lane(self, offset, width):
        rings=[]
        for i in range(513):
            p,d,left=self.frame(i/512)
            rings.append([tuple(p[k]+left[k]*(offset+side*width/2) for k in range(2)) for side in (-1,1)])
        result=[]
        for a,b in zip(rings,rings[1:]): result += [[a[0],b[1],a[1]],[a[0],b[0],b[1]]]
        return result


def placed(source, pose, points):
    c,s=math.cos(math.radians(pose['yaw'])),math.sin(math.radians(pose['yaw']))
    result=[]
    for p in points:
        x,y,z=(v*pose['scale'] for v in sub(p,source['anchor']))
        result.append(tuple(a+b for a,b in zip(pose['position'],(c*x-s*y,s*x+c*y,z))))
    return result


def full_box(source, output):
    low,high=source['bounds'];vertices=placed(source,output['pose'],list(product(*zip(low,high))))
    # product ordering is x-major; use the actual convex box face normals for SAT.
    f=[(1,2,4),(1,4,3),(5,7,8),(5,8,6),(1,5,6),(1,6,2),(3,4,8),(3,8,7),(1,3,7),(1,7,5),(2,6,8),(2,8,4)]
    return dict(vertices=vertices,faces=[x+(1,0) for x in f],bounds=bounds(vertices))


def prove_gaps(boxes, required):
    minimum=math.inf
    for a,b in combinations(boxes,2):
        al,ah=a['bounds'];bl,bh=b['bounds']
        separation=math.sqrt(sum(max(0,bl[k]-ah[k],al[k]-bh[k])**2 for k in range(3)))
        if separation < required-.04: separation=mesh_gap_certificate(a,b,required)
        minimum=min(minimum,separation)
    return minimum


def verify(meshes, config, lane_ids, curve, top):
    require(len(meshes['source']) == 1 and len(meshes['receiver']) == 5, 'Incomplete source/receiving road')
    source=meshes['source'][0];prove_closed(source)
    require(len(source['vertices']) > 1000 and len(source['faces']) > 2000, 'Source is not the complete modeled sedan')
    require(source.get('anchor') is not None, 'Source pose reference absent')
    dimensions=tuple(b-a for a,b in zip(*source['bounds']))
    require(math.dist(dimensions,(4520,1900,1500)) < .08, 'Complete physical source dimensions changed')
    sb=hull(actual_base_points(source,.5));base_center=tuple((min(p[k] for p in sb)+max(p[k] for p in sb))/2 for k in range(2))
    require(math.dist(base_center,source['anchor'][:2]) < .04 and abs(base_center[0]-(source['bounds'][0][0]+source['bounds'][1][0])/2-100)<.04,'Actual axle/contact center was replaced by body center')
    usable=curve.length-sum(config['insets'])
    counts=[int(v) for v in config['counts']] if int(config['amount'][0]) == 2 else [int(usable//v) for v in config['spacing']]
    outputs=meshes['output'];require(len(outputs)==sum(counts),'Requested complete-car quantity not published')
    require(len({o['pose']['stable_id'] for o in outputs})==len(outputs),'Duplicate car identity')
    lanes=[curve.lane(config['offsets'][i],config['widths'][i]) for i in range(2)]
    actual=[[],[]];maximum_error=0.;minimum_support=1.;boxes=[]
    for index,output in enumerate(outputs,1):
        pose=output['pose'];require(pose['source']==1 and pose['parent']==0,'Unexpected source or stack')
        region=config['region'][index];require(region in lane_ids,'Unknown native lane assignment');lane=lane_ids.index(region)
        require(output['faces']==source['faces'] and len(output['vertices'])==len(source['vertices']),'Complete topology/material IDs/smoothing changed')
        for wanted,got in zip(placed(source,pose,source['vertices']),output['vertices']):
            error=math.dist(wanted,got);require(error<=.04,'Actual complete mesh transform differs from source/reported scale');maximum_error=max(maximum_error,error)
        scale=pose['scale']
        if config['widths'][lane] == 1600: require(.6-1e-6<=scale<=.85,'Narrow-lane fit left its permitted uniform range')
        elif config['jitter'][0]>0: require(.8-1e-6<=scale<=1.1+1e-6,'Random final scale left allowed bounds')
        else: require(abs(scale-1)<1e-9,'Original-size case was unexpectedly scaled')
        base=hull(actual_base_points(output,.5*scale));bc=tuple((min(v[k] for v in base)+max(v[k] for v in base))/2 for k in range(2));point=(*bc,output['bounds'][0][2])
        require(math.dist(point,pose['position'])<.04,'Actual wheel base center differs from path placement')
        require(abs(point[2])<.03,'Actual tyre support is lifted or penetrates the road')
        s,lateral,d,left=curve.closest(point);actual[lane].append(s)
        require(abs(lateral-config['offsets'][lane])<=config['jitter'][0]+2.,'Car leaves its assigned lane offset/spread')
        angle=math.degrees(math.atan2(d[1],d[0]))+(180 if lane==1 else 0)
        require(abs((pose['yaw']-angle+180)%360-180)<.08,'Complete car faces the wrong travel direction')
        box=full_box(source,output);boxes.append(box)
        coverage(hull(box['vertices']),lanes[lane],'Full complete-body envelope leaves the permitted curved lane')
        minimum_support=min(minimum_support,coverage(base,top,'Actual tyre contacts lack complete receiving support'))
    for lane in range(2):
        require(len(actual[lane])==counts[lane],'Wrong per-direction complete-car count')
        wanted=[(i+.5)*usable/counts[lane] if int(config['amount'][0])==2 else (i+.5)*config['spacing'][lane] for i in range(counts[lane])]
        if lane==1:wanted=[usable-s for s in wanted]
        wanted=sorted(s+config['insets'][0] for s in wanted)
        require(all(abs(a-b)<=config['jitter'][1]+2. for a,b in zip(sorted(actual[lane]),wanted)),'Along-path slot positions/spread changed')
    gap=prove_gaps(boxes,config['gap'][0])
    return dict(status='passed',complete_cars=len(outputs),per_lane=counts,source_vertices=len(source['vertices']),source_faces=len(source['faces']),maximum_vertex_error_mm=maximum_error,minimum_actual_support_coverage=minimum_support,minimum_proved_complete_box_gap_mm=gap,scope='independent actual full meshes/contact triangles, actual receiving triangle coverage, complete source-box coverage inside independently evaluated curved lanes, heading/arc/offset/scale and gap proof')


def negatives(meshes,config,lane_ids,curve,top):
    results=[]
    for case,expected in [('lift','support'),('wrong_lane','offset'),('wrong_scale','transform'),('wrong_direction','direction'),('overlap','separat')]:
        bad=copy.deepcopy(meshes);out=bad['output'][0];pose=out['pose']
        if case=='overlap':
            boxes=[full_box(bad['source'][0],o) for o in bad['output'][:2]];boxes[1]=copy.deepcopy(boxes[0])
        elif case=='wrong_scale':
            out['vertices']=[tuple(a+.5*(v-a) for a,v in zip(pose['position'],p)) for p in out['vertices']]
        elif case=='wrong_direction':
            out['vertices']=[(2*pose['position'][0]-p[0],2*pose['position'][1]-p[1],p[2]) for p in out['vertices']];pose['yaw']+=180
        else:
            delta=(0,0,20) if case=='lift' else tuple(-3500*v for v in curve.closest(pose['position'])[3])
            out['vertices']=[tuple(a+b for a,b in zip(p,delta)) for p in out['vertices']];pose['position']=tuple(a+b for a,b in zip(pose['position'],delta))
        out['bounds']=bounds(out['vertices'])
        try:
            prove_gaps(boxes,config['gap'][0]) if case=='overlap' else verify(bad,config,lane_ids,curve,top)
        except ValueError as error:
            require(expected in str(error).lower(),'Invalid control rejected for wrong reason: '+str(error));results.append(dict(case=case,status='correctly-rejected',reason=str(error)))
        else:raise ValueError('Invalid real-road control accepted: '+case)
    return results


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('run',type=Path);a=p.parse_args();run=a.run.resolve();rp=run/'receipt.json';r=json.loads(rp.read_text())
    require(r['status']=='passed' and r['exit_code']==0 and r['test_script']=='tests/max/arrange_road_scene_tests.ms','Successful exact-pair road host required')
    for key in ('loaded_path_matches','loaded_storage_path_matches','binaries_unchanged','private_ini_matches','artist_profiles_unchanged'):require(r[key] is True,'Failed host guard: '+key)
    for name in ('verify_road_scene.py','verify_base_support.py','verify_shelves_stairs.py'):require(r['sources']['tools/'+name]==sha(Path(__file__).parent/name),'Verifier differs from frozen source pair')
    names=('original','variation','fit','spacing','centimetres','inches');meshes={n:read_meshes(run/(n+'-meshes.txt')) for n in names};configs={n:settings(run/(n+'-settings.txt')) for n in names}
    expected=((0,0,0),(14000,0,0),(16000,20000,0),(30000,20000,0))
    for c in configs.values():require(all(math.dist(a,b)<.04 for a,b in zip(c['control'],expected)),'Actual source Bezier changed physical units')
    curve=Curve(configs['original']['control']);region=configs['original']['region'];lane_ids=[region[1],region[4]]
    require(lane_ids[0]!=lane_ids[1] and all(region[i]==lane_ids[0] for i in (1,2,3)) and all(region[i]==lane_ids[1] for i in (4,5,6)),'Original path lane identities/order invalid')
    results={n:verify(meshes[n],configs[n],lane_ids,curve,tops(meshes[n]['receiver'])) for n in names}
    result=dict(status='passed',host_receipt_sha256=sha(rp),independent_curve_length_mm=curve.length,cases=results,negative_controls=negatives(meshes['original'],configs['original'],lane_ids,curve,tops(meshes['original']['receiver'])),exports={n:sha(run/(n+'-meshes.txt')) for n in names})
    (run/'independent-road-scene.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))


if __name__=='__main__':main()
