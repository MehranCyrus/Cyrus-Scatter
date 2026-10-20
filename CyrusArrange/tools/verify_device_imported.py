"""Independent actual-mesh device/cabinet/imported-receiver acceptance.

Support subtracts actual receiving triangles from an uncovered base polygon;
overlapping or duplicate imported faces cannot double-count coverage. Complete
closed appliance parts use conservative source-derived envelopes for clearance.
No native footprint, collision proxy or placement success flag is used.
"""
import argparse,copy,hashlib,json,math
from collections import Counter
from itertools import combinations,product
from pathlib import Path
from verify_base_support import area,clip,hull,turn
from verify_road_scene import placed,prove_closed
from verify_shelves_stairs import actual_base_points,bounds,cross,dot,integer,mesh_gap_certificate,read_meshes,require,sub

def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()

class Budget:
    def __init__(self):self.used=0
    def charge(self,n=1):
        self.used+=n;require(self.used<=2000000,'Independent per-output proof work admission exceeded')

def settings(path):
    out={}
    for line in Path(path).read_text().splitlines():
        words=line.split();require(len(words)>=2 and words[0]not in out,'Malformed device settings')
        key=words[0]
        if key in ('fit','random'):out[key]=words[1]=='true'
        elif key in ('receivers','obstacles','requested','seed'):out[key]=integer(words[1])
        else:out[key]=[float(v.lower().replace('d','e'))for v in words[1:]]
    require(out['receivers']+out['obstacles']<=256,'Device receiver admission')
    return out

def parts(mesh,weld=False):
    vertices=mesh['vertices'];parent=list(range(len(vertices)))
    def root(i):
        while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
        return i
    mapped={}
    for i,p in enumerate(vertices):
        key=p if weld else i
        if key in mapped:parent[i]=root(mapped[key])
        else:mapped[key]=i
    for f in mesh['faces']:
        for i in f[1:3]:parent[root(i-1)]=root(f[0]-1)
    groups={}
    for f in mesh['faces']:groups.setdefault(root(f[0]-1),[]).append(f)
    require(len(groups)<=256,'Actual receiver component admission exceeded')
    result=[]
    for faces in groups.values():
        used=sorted({i-1 for f in faces for i in f[:3]});remap={i:n+1 for n,i in enumerate(used)}
        v=[vertices[i]for i in used];f=[tuple(remap[i-1]for i in face[:3])+face[3:]for face in faces]
        edges=Counter((v[a-1],v[b-1])for face in f for a,b in zip(face[:3],face[1:3]+face[:1]))
        closed=all(n==1 and edges[(b,a)]==1 for(a,b),n in edges.items())
        result.append(dict(vertices=v,faces=f,bounds=bounds(v),closed=closed))
    return result

def split2(poly,a,b):
    inside=[];outside=[]
    for p,q in zip(poly,poly[1:]+poly[:1]):
        dp,dq=turn(a,b,p),turn(a,b,q)
        (inside if dp>=0 else outside).append(p)
        if(dp>=0)!=(dq>=0):
            r=dp/(dp-dq);x=tuple(p[k]+r*(q[k]-p[k])for k in range(2));inside.append(x);outside.append(x)
    return inside,outside

def surface_parts(mesh):
    faces=[]
    for f in mesh['faces']:
        a,b,c=(mesh['vertices'][i-1]for i in f[:3]);normal=cross(sub(b,a),sub(c,a))
        if dot(normal,normal)>=1e-18:faces.append(f)
    snapshot=dict(mesh);snapshot['faces']=faces
    return parts(snapshot,True),len(mesh['faces'])-len(faces)

def physical_support_facing(receiving_parts):
    """Infer physical facing from actual closed parts, never native prepared data."""
    budget=Budget();budget.charge(len(receiving_parts));signs=[1]*len(receiving_parts);closed=[i for i,p in enumerate(receiving_parts)if p['closed']];ambiguous=0
    def contains(a,b):return all(a[0][k]<=b[0][k]+.002 and a[1][k]>=b[1][k]-.002 for k in range(3))
    def potential(a,b):return contains(a,b)or contains(b,a)or all(min(a[1][k],b[1][k])-max(a[0][k],b[0][k])>.002 for k in range(3))
    for i in closed:
        p=receiving_parts[i];budget.charge(1+12*len(p['faces']));origin=p['bounds'][0];terms=[dot(sub(p['vertices'][f[0]-1],origin),cross(sub(p['vertices'][f[1]-1],origin),sub(p['vertices'][f[2]-1],origin)))for f in p['faces']]
        volume=math.fsum(terms);box_volume=math.prod(b-a for a,b in zip(*p['bounds']));error=128*math.ulp(1.)*(math.fsum(abs(x)for x in terms)+6*box_volume)
        if abs(volume)<=error:ambiguous+=1
        elif volume<0:
            budget.charge(len(closed))
            if any(j!=i and potential(p['bounds'],receiving_parts[j]['bounds'])for j in closed):ambiguous+=1
            else:signs[i]=-1
    return signs,signs.count(-1),ambiguous,budget.used

def support(base,triangles,budget):
    remaining=[base];initial=area(base)
    for triangle in triangles:
        budget.charge();tri=triangle if turn(*triangle)>0 else triangle[::-1];new=[]
        for poly in remaining:
            budget.charge(len(poly)+3)
            if any(max(p[k]for p in poly)<min(p[k]for p in tri)or max(p[k]for p in tri)<min(p[k]for p in poly)for k in range(2)):
                new.append(poly);continue
            inside=poly
            for a,b in zip(tri,tri[1:]+tri[:1]):
                budget.charge(12*len(inside)+1);inside,outside=split2(inside,a,b)
                if area(outside)>1e-8:new.append(outside)
                if not inside:break
        remaining=new;require(len(remaining)<=2048,'Uncovered support polygon admission exceeded')
        if not remaining:break
    left=sum(area(p)for p in remaining)
    require(initial>1e-6 and left<=max(.005,initial*1e-7),'Actual base lacks complete receiving triangle support')
    return 1-left/initial

def clip3(poly,axis,value,less):
    out=[]
    for p,q in zip(poly,poly[1:]+poly[:1]):
        dp=(value-p[axis])if less else(p[axis]-value);dq=(value-q[axis])if less else(q[axis]-value)
        if dp>=0:out.append(p)
        if(dp>=0)!=(dq>=0):
            u=dp/(dp-dq);out.append(tuple(p[k]+u*(q[k]-p[k])for k in range(3)))
    return out

def inside_closed(point,mesh,budget):
    low,high=mesh['bounds']
    if not all(low[k]<point[k]<high[k]for k in range(3)):return False
    direction=(.293,.551,.782);hits=[]
    for f in mesh['faces']:
        budget.charge(20)
        a,b,c=(mesh['vertices'][i-1]for i in f[:3]);e1,e2=sub(b,a),sub(c,a);h=cross(direction,e2);det=dot(e1,h)
        if abs(det)<1e-12:continue
        s=sub(point,a);u=dot(s,h)/det
        if u<0 or u>1:continue
        q=cross(s,e1);v=dot(direction,q)/det
        if v<0 or u+v>1:continue
        t=dot(e2,q)/det
        if t>1e-7:hits.append(t)
    unique=[]
    for t in sorted(hits):
        if not unique or abs(t-unique[-1])>1e-6:unique.append(t)
    return len(unique)%2==1

def clearance(source,source_parts,output,receiver_parts,budget):
    pose=output['pose'];c,s=math.cos(math.radians(pose['yaw'])),math.sin(math.radians(pose['yaw']))
    local=[]
    for mesh in receiver_parts:
        points=[]
        for p in mesh['vertices']:
            budget.charge();x,y,z=sub(p,pose['position']);points.append(tuple(a+b/pose['scale']for a,b in zip(source['anchor'],(c*x+s*y,-s*x+c*y,z))))
        local.append(dict(vertices=points,faces=mesh['faces'],bounds=bounds(points),closed=mesh['closed']))
    tolerance=.04/pose['scale']
    for part in source_parts:
        low,high=part['bounds'];low=tuple(x+tolerance for x in low);high=tuple(x-tolerance for x in high)
        require(all(b>a for a,b in zip(low,high)),'Appliance part too thin for declared proof precision')
        center=tuple((a+b)/2 for a,b in zip(low,high))
        for mesh in local:
            budget.charge()
            ml,mh=mesh['bounds']
            if any(mh[k]<low[k]or ml[k]>high[k]for k in range(3)):continue
            if mesh['closed']:require(not inside_closed(center,mesh,budget),'Complete appliance part is enclosed inside receiver/obstacle solid')
            for f in mesh['faces']:
                budget.charge(4);poly=[mesh['vertices'][i-1]for i in f[:3]]
                if any(max(p[k]for p in poly)<low[k]or min(p[k]for p in poly)>high[k]for k in range(3)):continue
                for k in range(3):
                    budget.charge(8*len(poly)+1);poly=clip3(poly,k,low[k],False)
                    budget.charge(8*len(poly)+1);poly=clip3(poly,k,high[k],True)
                    if not poly:break
                require(not poly,'Actual receiving/obstacle triangle penetrates a complete appliance component envelope')

def check(meshes,config,name):
    require(len(meshes['source'])==1 and len(meshes['receiver'])==config['receivers']+config['obstacles'],'Actual receiver/source counts changed')
    source=meshes['source'][0];prove_closed(source);source_parts=parts(source)
    require(len(source_parts)==24 and len(source['vertices'])>700 and len(source['faces'])>1400,'Complete appliance component/topology admission changed')
    require(math.dist(sub(source['bounds'][1],source['bounds'][0]),(460,500,560))<.04,'Literal physical appliance dimensions changed')
    require(source['anchor']is not None,'Source anchor absent')
    receiver_parts=[];receiving_parts=[];ignored=0
    for i,m in enumerate(meshes['receiver']):
        valid,skipped=surface_parts(m);receiver_parts.extend(valid);ignored+=skipped
        if i<config['receivers']:receiving_parts.extend(valid)
    facing,reversed_shells,ambiguous_shells,facing_work=physical_support_facing(receiving_parts)
    output=meshes['output'];require(len(output)==config['requested'],'Requested complete appliance copies not published')
    require(len({o['pose']['stable_id']for o in output})==len(output),'Duplicate appliance identity')
    maximum=0.;coverage=1.;peak=0;heights=[];front_overhang=0.
    for out in output:
        p=out['pose'];budget=Budget();require(p['source']==1 and p['parent']==0,'Unexpected source/stack identity')
        require(out['faces']==source['faces']and len(out['vertices'])==len(source['vertices']),'Complete topology/material/smoothing changed')
        for wanted,actual in zip(placed(source,p,source['vertices']),out['vertices']):
            budget.charge();error=math.dist(wanted,actual);require(error<=.04,'Actual complete mesh differs from reported source transform/scale');maximum=max(maximum,error)
        scale=p['scale']
        if name.endswith('original'):require(abs(scale-1)<1e-9,'Preferred original appliance size was changed')
        else:require(config['scale'][0]-1e-9<=scale<=(config['scale'][1]if config['random']else min(1.,config['scale'][1]))+1e-9,'Final scale left permitted uniform range')
        low,high=out['bounds'];require(abs(low[2]-p['position'][2])<.03,'Actual foot minimum differs from native placement height');heights.append(low[2])
        triangles=[]
        for mesh,sign in zip(receiving_parts,facing):
            for f in mesh['faces']:
                budget.charge();t=[mesh['vertices'][i-1]for i in f[:3]];n=cross(sub(t[1],t[0]),sub(t[2],t[0]))
                if all(abs(v[2]-low[2])<=.03 for v in t)and sign*n[2]>0 and sign*n[2]>.99999*math.sqrt(dot(n,n)):
                    if sign<0:t=[t[0],t[2],t[1]]
                    triangles.append([v[:2]for v in t])
        base=hull(actual_base_points(out,.5*scale));coverage=min(coverage,support(base,triangles,budget))
        if name.startswith('cabinet'):
            require(abs(low[2]-80)<.03,'Cabinet device lacks literal floor contact')
            rooms=[(-1970,-1370,750)]if name=='cabinet-original'else[(-2600,-2000,480),(-1340,-510,480)]
            require(all(p[1]>=-300-.04 for p in base),'Actual appliance feet overhang the cabinet support front')
            require(any(low[0]>=a-.04 and high[0]<=b+.04 and high[1]<=300+.04 and high[2]<=roof+.04 for a,b,roof in rooms),'Complete device crosses literal cabinet walls or roof')
            front_overhang=max(front_overhang,max(0.,-300-low[1]))
        if name=='imported-two-level-fit':
            occupied=meshes['receiver'][config['receivers']:]
            require(occupied and high[2]<=min(m['bounds'][0][2]for m in occupied)+.04,'Lower-shelf device enters actual occupied upper space')
        clearance(source,source_parts,out,receiver_parts,budget);peak=max(peak,budget.used)
    gap=math.inf
    for a,b in combinations(output,2):
        al,ah=a['bounds'];bl,bh=b['bounds'];distance=math.sqrt(sum(max(0,bl[k]-ah[k],al[k]-bh[k])**2 for k in range(3)))
        if distance<config['gap'][0]-.04:distance=mesh_gap_certificate(a,b,config['gap'][0])
        gap=min(gap,distance)
    return dict(status='passed',complete_devices=len(output),complete_source_vertices=len(source['vertices']),complete_source_faces=len(source['faces']),closed_appliance_parts=len(source_parts),closed_receiver_parts=sum(p['closed']for p in receiver_parts),open_receiver_surface_parts=sum(not p['closed']for p in receiver_parts),ignored_zero_area_receiving_faces=ignored,closed_receiving_shells_evaluated_outward=reversed_shells,ambiguous_closed_receiving_shells=ambiguous_shells,receiving_facing_proof_work=facing_work,maximum_vertex_error_mm=maximum,minimum_actual_base_coverage=coverage,maximum_open_front_body_overhang_mm=front_overhang,minimum_proved_output_gap_mm=gap if math.isfinite(gap)else None,actual_support_heights_mm=heights,maximum_proof_work=peak,scope='actual source/output topology and transforms; uncovered-polygon subtraction support proof; complete conservative component envelopes clear of actual nonzero receiver/obstacle triangles and closed-solid containment; literal cabinet walls/roof with fully supported feet at the open front; final-scale separation')

def negatives(meshes,config,name,front_shift_mm=150):
    result=[]
    for kind,expected in [('lift','support'),('scale','transform'),('missing_support','support'),('unsupported_front','support'),('collision','envelope')]:
        bad=copy.deepcopy(meshes);out=bad['output'][0];p=out['pose']
        if kind=='missing_support':
            floor=bad['receiver'][0];kept=[]
            for f in floor['faces']:
                t=[floor['vertices'][i-1]for i in f[:3]];n=cross(sub(t[1],t[0]),sub(t[2],t[0]))
                if not(n[2]>0 and all(abs(v[2]-out['bounds'][0][2])<.03 for v in t)):kept.append(f)
            floor['faces']=kept
        elif kind=='scale':out['vertices']=[tuple(a+.5*(x-a)for a,x in zip(p['position'],v))for v in out['vertices']]
        else:
            delta=(0,0,20)if kind=='lift'else(0,-front_shift_mm,0)if kind=='unsupported_front'else(0,0,0)
            if kind=='collision':
                # Add a literal tiny box wholly crossing the actual housing, so
                # a valid floor contact cannot hide an overhead/body collision.
                center=placed(bad['source'][0],p,[(10000,10100,200)])[0];lo=tuple(x-5 for x in center);hi=tuple(x+5 for x in center)
                v=list(product(*zip(lo,hi)));f=[(1,2,4),(1,4,3),(5,7,8),(5,8,6),(1,5,6),(1,6,2),(3,4,8),(3,8,7),(1,3,7),(1,7,5),(2,6,8),(2,8,4)]
                blocker=dict(vertices=v,faces=[face+(1,0)for face in f],bounds=bounds(v),pose=None,anchor=None)
                bad['receiver'].append(blocker)
            else:
                out['vertices']=[tuple(a+b for a,b in zip(v,delta))for v in out['vertices']];p['position']=tuple(a+b for a,b in zip(p['position'],delta))
        out['bounds']=bounds(out['vertices']);cfg=copy.deepcopy(config)
        if kind=='collision':cfg['obstacles']+=1
        try:check(bad,cfg,name)
        except ValueError as e:
            require(expected in str(e).lower()or(kind=='collision'and'enclosed'in str(e).lower()),'Invalid device control rejected for wrong reason: '+str(e));result.append(dict(case=kind,status='correctly-rejected',reason=str(e)))
        else:raise ValueError('Invalid device control accepted: '+kind)
    return result

def inward_support_controls(meshes,config):
    """Reject missing glass and physical underside support using authored geometry."""
    result=[]
    for kind in ('missing_closed_glass','authored_underside'):
        bad=copy.deepcopy(meshes)
        if kind=='missing_closed_glass':
            mesh=bad['receiver'][0];valid,_=surface_parts(mesh);glass=[p for p in valid if p['closed']]
            require(len(glass)==1,'Expected one actual closed imported glass component')
            points=set(glass[0]['vertices']);mesh['faces']=[f for f in mesh['faces']if not all(mesh['vertices'][i-1]in points for i in f[:3])]
        else:
            out=bad['output'][0];delta=-19.231705
            out['vertices']=[(x,y,z+delta)for x,y,z in out['vertices']];p=out['pose'];p['position']=(p['position'][0],p['position'][1],p['position'][2]+delta);out['bounds']=bounds(out['vertices'])
        try:check(bad,config,'imported-rim-original')
        except ValueError as e:require('support'in str(e).lower(),'Facing control rejected for wrong reason: '+str(e));result.append(dict(case=kind,status='correctly-rejected',reason=str(e)))
        else:raise ValueError('Invalid physical receiving-side control accepted: '+kind)
    return result

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('run',type=Path);a=p.parse_args();run=a.run.resolve();rp=run/'receipt.json';r=json.loads(rp.read_text())
    require(r['status']=='passed'and r['exit_code']==0 and r['test_script']=='tests/max/arrange_device_imported_tests.ms','Successful exact-pair device/imported host required')
    for k in ('loaded_path_matches','loaded_storage_path_matches','binaries_unchanged','private_ini_matches','artist_profiles_unchanged'):require(r[k]is True,'Failed device host guard: '+k)
    for n in ('verify_device_imported.py','verify_road_scene.py','verify_base_support.py','verify_shelves_stairs.py'):require(r['sources']['tools/'+n]==sha(Path(__file__).parent/n),'Verifier differs from frozen pair')
    names=('cabinet-original','cabinet-fit','cabinet-random','imported-two-level-original','imported-two-level-fit','imported-rim-original')
    data={n:read_meshes(run/(n+'-meshes.txt'))for n in names};configs={n:settings(run/(n+'-settings.txt'))for n in names}
    cases={n:check(data[n],configs[n],n)for n in names}
    require(cases['imported-rim-original']['closed_receiving_shells_evaluated_outward']==1,'Actual supplied inward glass was not independently recognized')
    controls=negatives(data['cabinet-fit'],configs['cabinet-fit'],'cabinet-fit')+inward_support_controls(data['imported-rim-original'],configs['imported-rim-original'])
    result=dict(status='passed',host_receipt_sha256=sha(rp),cases=cases,negative_controls=controls,exports={n:sha(run/(n+'-meshes.txt'))for n in names})
    (run/'independent-device-imported.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))

if __name__=='__main__':main()
