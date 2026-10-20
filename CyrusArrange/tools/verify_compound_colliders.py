"""Independent actual-mesh proof using the authored arch's analytic solid union.
Does not import native proxy, bands, topology certification or placement code.
"""
import argparse
import copy
import hashlib
import json
import math
from pathlib import Path
from verify_shelves_stairs import read_meshes, prove_box, bounds, require


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def prove_arch(mesh):
    vertices, faces = mesh['vertices'], mesh['faces']
    require(len(vertices) == 20 and len(faces) == 36, 'Arch topology differs from the authored closed solid')
    low, high = mesh['bounds']; center = ((low[0]+high[0])/2, (low[1]+high[1])/2, low[2])
    profile = [(-500, 0), (-350, 0), (-350, 800), (350, 800), (350, 0), (500, 0), (500, 1000), (-500, 1000), (-350, 1000), (350, 1000)]
    expected = [(x, y, z) for y in (-200, 200) for x, z in profile]
    require(all(math.dist(tuple(a-b for a, b in zip(v, center)), e) < .04 for v, e in zip(vertices, expected)), 'Arch geometry differs from the analytic profile')
    caps = [(0,1,2), (0,2,8), (0,8,7), (4,5,6), (4,6,3), (3,6,9), (2,3,9), (2,9,8)]
    triangles = []
    for a,b,c in caps:
        triangles += [(a,b,c), (c+10,b+10,a+10)]
    loop = [0,1,2,3,4,5,6,9,8,7]
    for a,b in zip(loop, loop[1:]+loop[:1]):
        triangles += [(a,a+10,b+10), (a,b+10,b)]
    require([tuple(x-1 for x in f[:3]) for f in faces] == triangles, 'Arch boundary triangulation differs from the proved solid')
    # Exact known solid: two 150x400x1000 legs plus a 700x400x200 beam.
    return center


def verify(meshes, case):
    sources, outputs = meshes['source'], meshes['output']
    require(len(outputs) == (1 if case == 'static' else 2), 'Wrong actual output count')
    prove_arch(sources[0])
    if len(sources) > 1:
        prove_box(sources[1])
    error = 0
    for out in outputs:
        p = out['pose']; src = sources[p['source']-1]
        require(out['faces'] == src['faces'], 'Actual output topology/material IDs/smoothing changed')
        require(len(out['vertices']) == len(src['vertices']), 'Actual output vertex count changed')
        require(p['scale'] == 1 and p['parent'] == 0, 'Original scale or root support changed')
        sl, sh = src['bounds']; anchor = ((sl[0]+sh[0])/2, (sl[1]+sh[1])/2, sl[2])
        c,s = math.cos(math.radians(p['yaw'])), math.sin(math.radians(p['yaw']))
        for v, actual in zip(src['vertices'], out['vertices']):
            x,y,z = (a-b for a,b in zip(v, anchor)); expected = (p['position'][0]+c*x-s*y, p['position'][1]+s*x+c*y, p['position'][2]+z)
            d = math.dist(expected, actual); require(d <= .04, 'Actual geometry differs from source transform'); error = max(error,d)
        require(abs(out['bounds'][0][2]) <= .03, 'Actual output lacks base support')
    arches = [o for o in outputs if o['pose']['source'] == 1]
    require(len(arches) == 1, 'Missing actual arch output')
    arch = arches[0]; lo,hi = arch['bounds']; center = ((lo[0]+hi[0])/2,(lo[1]+hi[1])/2,lo[2])
    require(abs(hi[2]-1000) < .03 and abs(hi[0]-lo[0]-1000)<.03 and abs(hi[1]-lo[1]-400)<.03, 'Actual arch has wrong dimensions or heading')
    if case == 'static':
        require(len(meshes['receiver']) == 2, 'Missing independent static obstacle')
        device = meshes['receiver'][1]; prove_box(device)
    else:
        device = next((o for o in outputs if o['pose']['source'] == 2), None)
        require(device is not None, 'Missing actual nested device')
        # The rigid output was proved from its exact box source and every actual
        # vertex above. Quarter-turn float transforms can differ by an ulp from
        # an exact axis-aligned eight-corner set; full bounds containment is the
        # stronger needed proof that this convex device stays in the empty gap.
    dl,dh = device['bounds']
    require(dl[0] >= center[0]-350-.03 and dh[0] <= center[0]+350+.03 and dl[1] >= center[1]-200-.03 and dh[1] <= center[1]+200+.03 and dh[2] <= 800+.03, 'Actual device penetrates a real leg/beam')
    require(all(min(hi[k],dh[k])-max(lo[k],dl[k]) > .03 for k in range(3)), 'Case failed to exercise overlapping complete source envelopes')
    if case != 'path':
        floor = meshes['receiver'][0]; prove_box(floor); fl,fh = floor['bounds']
        for o in outputs:
            ol,oh = o['bounds'];require(abs(ol[2]-fh[2]) <= .03 and all(ol[k]>=fl[k]-.03 and oh[k]<=fh[k]+.03 for k in (0,1)), 'Actual complete footprint lacks board support')
    else:
        require(abs(center[0]-5000)<.03 and abs(center[1]+2000)<.03, 'Actual path center is wrong')
        require(abs((dl[0]+dh[0])/2-center[0])<.03 and abs((dl[1]+dh[1])/2-center[1])<.03, 'Actual path base centers differ')
    return dict(status='passed', outputs=len(outputs), source_arch_vertices=20, source_arch_triangles=36, maximum_world_vertex_error_mm=error, complete_envelopes_overlap=True, analytic_solid='two 150x400x1000 legs and a 700x400x200 beam', scope='actual source/output topology, transform, original scale, analytic occupied solid and board/path contact; UV/material-root identity is host scope')


def negatives(meshes):
    result=[]
    for name, reason in [('leg','leg/beam'),('lift','base support'),('missing_face','Arch topology'),('visual_scale','source transform')]:
        bad=copy.deepcopy(meshes);device=next(o for o in bad['output'] if o['pose']['source']==2)
        if name=='missing_face':
            bad['source'][0]['faces'].pop()
        else:
            if name=='leg': delta=(-425-device['pose']['position'][0],0,0)
            elif name=='lift': delta=(0,0,10)
            else: delta=None
            if delta:
                device['vertices']=[tuple(a+b for a,b in zip(v,delta)) for v in device['vertices']]
                device['pose']['position']=tuple(a+b for a,b in zip(device['pose']['position'],delta))
            else:
                p=device['pose']['position'];device['vertices']=[tuple(a+(b-a)*.5 for a,b in zip(p,v)) for v in device['vertices']]
            device['bounds']=bounds(device['vertices'])
        try: verify(bad,'nested')
        except ValueError as e:
            require(reason in str(e),'Negative control failed for the wrong reason: '+str(e));result.append(dict(case=name,status='correctly-rejected',reason=str(e)))
        else: raise ValueError('Invalid compound scene accepted: '+name)
    return result


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('run',type=Path);a=p.parse_args();run=a.run.resolve();rp=run/'receipt.json';r=json.loads(rp.read_text())
    require(r['status']=='passed' and r['exit_code']==0 and r['test_script']=='tests/max/arrange_compound_collision_tests.ms','Successful exact-pair compound Max receipt required')
    for k in ('loaded_path_matches','loaded_storage_path_matches','binaries_unchanged','private_ini_matches','artist_profiles_unchanged'):require(r[k] is True,'Failed host guard: '+k)
    for filename in ('verify_compound_colliders.py','verify_shelves_stairs.py'):require(r['sources']['tools/'+filename]==sha(Path(__file__).parent/filename),'Verifier differs from frozen source pair')
    cases={name:read_meshes(run/(name+'-meshes.txt')) for name in ('nested','static','path')}
    report=dict(status='passed',host_receipt_sha256=sha(rp),cases={k:verify(v,k) for k,v in cases.items()},negative_controls=negatives(cases['nested']),exports={k+'-meshes.txt':sha(run/(k+'-meshes.txt')) for k in cases})
    (run/'independent-compound-colliders.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))


if __name__=='__main__':main()
