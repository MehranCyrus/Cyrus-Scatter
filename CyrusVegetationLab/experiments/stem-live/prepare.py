"""Prepare actual tube centreline guides and rigid foliage attachments from the inspected lavender."""
from pathlib import Path
import argparse,collections,hashlib,json,itertools,time
import numpy as np
ROOT=Path(__file__).resolve().parents[3]
def core(p):return [float(p[0]),float(p[2]),float(-p[1])]
def resample(points,count):
    arc=np.r_[0,np.cumsum(np.linalg.norm(np.diff(points,axis=0),axis=1))]
    if arc[-1]<1e-5:raise ValueError('Collapsed centreline')
    return np.stack([np.interp(np.linspace(0,arc[-1],count),arc,points[:,k]) for k in range(3)],axis=1)
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--input',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);args=ap.parse_args();started=time.perf_counter()
    meta=json.loads(args.input.with_suffix('.json').read_text());components=meta['components']
    with args.input.with_suffix('.bin').open('rb') as stream:
        magic,nv,nf,nc=np.fromfile(stream,'<u4',4);assert magic==0x53544c32
        positions=np.fromfile(stream,'<f4',int(nv)*3).reshape(-1,3).astype(np.float64)
        faces=np.fromfile(stream,'<u4',int(nf)*3).reshape(-1,3);materials=np.fromfile(stream,'<u4',int(nf));labels=np.fromfile(stream,'<u4',int(nv))
    order=np.argsort(labels,kind='stable');counts=np.bincount(labels);offsets=np.r_[0,np.cumsum(counts)]
    raw=[];component_guide={};rings_by_part={};irregular=[]
    for comp in components:
        material=int(next(iter(comp['materials'])));cid=comp['id'];indices=order[offsets[cid]:offsets[cid+1]]
        if material not in (0,1):continue
        sides=(2*comp['vertices']-comp['faces'])/2
        if sides<3 or sides>16 or sides!=int(sides) or len(indices)%int(sides):irregular.append(cid);continue
        ring_indices=indices.reshape(-1,int(sides));rings=positions[ring_indices];centres=rings.mean(axis=1)
        # This asset's authored tube rings run base -> tip, including downward twigs.
        # Flipping by height would incorrectly root downward-growing branches at their tips.
        length=float(np.linalg.norm(np.diff(centres,axis=0),axis=1).sum())
        # Ring centres must be locally coherent actual tube sections, not arbitrary spatial slices.
        radii=np.linalg.norm(rings-rings.mean(axis=1)[:,None,:],axis=2)
        if length<.005 or np.max(radii)>.03:irregular.append(cid);continue
        n=9 if length>.3 else 7 if length>.15 else 5 if length>.08 else 3
        nodes=resample(centres,n);gid=len(raw);component_guide[cid]=gid;rings_by_part[cid]=ring_indices
        raw.append({'component':cid,'material':material,'length':length,'nodes_z':nodes,'ring_centres':centres,'ring0':ring_indices[0].tolist()})
    assert len(raw)>100,'No meaningful stem topology found'
    # Spatial hash of source-derived guide segments, deterministic exhaustive fallback.
    cell=.025;grid=collections.defaultdict(list);segments=[]
    for gi,g in enumerate(raw):
        for si,(a,b) in enumerate(zip(g['nodes_z'][:-1],g['nodes_z'][1:])):
            index=len(segments);segments.append((gi,si,a,b))
            for p in np.linspace(a,b,max(2,int(np.linalg.norm(b-a)/(.4*cell))+1)):
                key=tuple(np.floor(p/cell).astype(int));grid[key].append(index)
    starts=np.asarray([s[2] for s in segments]);directions=np.asarray([s[3]-s[2] for s in segments]);denom=np.einsum('ij,ij->i',directions,directions)
    rootz=np.asarray([g['nodes_z'][0,2] for g in raw])
    def nearest(point,exclude=-1,parent=False):
        key=np.floor(point/cell).astype(int);indices=set()
        for radius in range(1,5):
            for delta in itertools.product(range(-radius,radius+1),repeat=3):
                indices.update(grid.get(tuple(key+delta),()))
            ids=np.asarray(sorted(indices),dtype=np.int64)
            if len(ids):
                keep=np.asarray([segments[i][0]!=exclude and (not parent or segments[i][0]<exclude) for i in ids]);ids=ids[keep]
            if len(ids):
                u=np.clip(np.einsum('ij,ij->i',point-starts[ids],directions[ids])/denom[ids],0,1);delta=point-starts[ids]-directions[ids]*u[:,None];ds=np.einsum('ij,ij->i',delta,delta);best=int(np.argmin(ds))
                if float(ds[best])<((radius-.5)*cell)**2:return segments[ids[best]][0],segments[ids[best]][1],float(u[best]),float(ds[best]**.5)
        ids=np.asarray([i for i,s in enumerate(segments) if s[0]!=exclude and (not parent or s[0]<exclude)],dtype=np.int64)
        if not len(ids):return -1,0,0.,0.
        u=np.clip(np.einsum('ij,ij->i',point-starts[ids],directions[ids])/denom[ids],0,1);delta=point-starts[ids]-directions[ids]*u[:,None];ds=np.einsum('ij,ij->i',delta,delta);best=int(np.argmin(ds));return segments[ids[best]][0],segments[ids[best]][1],float(u[best]),float(ds[best]**.5)
    guides=[];root_distances=[]
    for gi,g in enumerate(raw):
        parent,span,u,distance=nearest(g['nodes_z'][0],gi,True);root_distances.append(distance)
        guides.append({'component':g['component'],'nodes':[core(p) for p in g['nodes_z']],'parent':parent,'parent_span':span,'parent_u':u,'parent_distance_m':distance,'length_m':g['length'],'root_ring_vertices':g['ring0'] if parent<0 else []})
    parts=[];attachment_distances=[]
    for comp in components:
        cid=comp['id'];indices=order[offsets[cid]:offsets[cid+1]];pts=positions[indices];mat=int(next(iter(comp['materials'])))
        if cid in component_guide:parts.append({'guide':component_guide[cid],'stem':True,'span':0,'u':0.,'material':mat});continue
        # The actual leaf/flower part is rigid; anchor at its lowest point, close to its botanical base.
        pivot=pts[np.argmin(pts[:,2])];gi,span,u,dist=nearest(pivot);attachment_distances.append(dist)
        parts.append({'guide':gi,'stem':False,'span':span,'u':u,'material':mat})
    guide_order=list(range(len(guides)))
    rank={g:i for i,g in enumerate(guide_order)}
    assert all(g['parent']<0 or rank[g['parent']]<rank[i] for i,g in enumerate(guides))
    # Actual tube LOD uses a few original cross-sections; whole leaf/flower parts are retained deterministically.
    preview_faces=[];preview_mats=[]
    rng=np.random.default_rng(2402)
    selected=set()
    for comp in components:
        cid=comp['id'];part=parts[cid]
        if part['stem']:
            rings=rings_by_part[cid];nr=min(len(rings),5 if raw[part['guide']]['length']>.15 else 3);chosen=np.unique(np.linspace(0,len(rings)-1,nr).astype(int));r=rings.shape[1]
            for a,b in zip(chosen[:-1],chosen[1:]):
                for j in range(r):
                    p,q=int(rings[a,j]),int(rings[a,(j+1)%r]);s,t=int(rings[b,j]),int(rings[b,(j+1)%r]);preview_faces.extend([[p,q,s],[q,t,s]]);preview_mats.extend([part['material']]*2)
        elif (part['material']==2 and rng.random()<.05) or (part['material']==3 and rng.random()<.06) or part['material']<2:selected.add(cid)
    selected_faces=np.flatnonzero(np.isin(labels[faces[:,0]],list(selected)))
    preview_faces.extend(faces[selected_faces].tolist());preview_mats.extend(materials[selected_faces].tolist())
    args.output.mkdir(parents=True,exist_ok=False)
    data={'schema':2,'asset':'A084 Lavender 05','vertices':int(nv),'triangles':int(nf),'parts':parts,'guides':guides,'guide_order':guide_order,'preview_triangles':preview_faces,'preview_materials':preview_mats,
          'source_geometry_sha256':hashlib.sha256(args.input.with_suffix('.bin').read_bytes()).hexdigest()}
    (args.output/'lavender.stems.json').write_text(json.dumps(data,separators=(',',':')))
    labels.astype('<u4').tofile(args.output/'lavender.parts.bin')
    summary={'guides':len(guides),'main_stems':sum(g['material']==0 for g in raw),'green_stems':sum(g['material']==1 for g in raw),'components':len(parts),'rigid_parts':sum(not p['stem'] for p in parts),'irregular_stem_components_rigid':len(irregular),'ground_roots':sum(g['parent']<0 for g in guides),'max_parent_distance_m':max(root_distances),'parent_distance_p95_m':float(np.percentile(root_distances,95)),'attachment_distance_p95_m':float(np.percentile(attachment_distances,95)),'max_attachment_distance_m':max(attachment_distances),'preview_triangles':len(preview_faces),'preview_vertices':len(np.unique(preview_faces)),'seconds':time.perf_counter()-started}
    (args.output/'preparation.json').write_text(json.dumps(summary,indent=2));print(json.dumps(summary,indent=2),flush=True)
if __name__=='__main__':main()
