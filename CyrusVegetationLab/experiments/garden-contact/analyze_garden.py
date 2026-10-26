"""Offline broad-phase design probe over actual Max-exported Scatter records.

This tests conservative AABB selection, not collision solving or Max frame rate.
"""
from pathlib import Path
import argparse, collections, hashlib, itertools, json, math, statistics, time

def transform(p, tm):
    return tuple(sum(p[j]*tm[j][k] for j in range(3))+tm[3][k] for k in range(3))

def overlaps(a,b):
    return all(a[0][k]<=b[1][k] and a[1][k]>=b[0][k] for k in range(3))

def corners(lo,hi):
    return itertools.product(*[(lo[k],hi[k]) for k in range(3)])

def cell_keys(box, size=40.0):
    return itertools.product(*[range(math.floor(box[0][k]/size),math.floor(box[1][k]/size)+1) for k in range(3)])

def inside(p, polygon):
    # The baseline masks are convex XY hulls of transformed rock vertices.
    sign=[]
    for a,b in zip(polygon,polygon[1:]+polygon[:1]):
        sign.append((b[0]-a[0])*(p[1]-a[1])-(b[1]-a[1])*(p[0]-a[0]))
    return min(sign)>=-1e-5 or max(sign)<=1e-5

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('run',type=Path); args=ap.parse_args(); run=args.run
    layers=json.loads((run/'placements.json').read_text())
    old=json.loads((run/'placements-before-masks.json').read_text())
    source_metrics=json.loads((run/'source-metrics.json').read_text())
    footprints=json.loads((run/'footprints.json').read_text())
    by_layer=collections.defaultdict(list)
    for s in source_metrics: by_layer[s['layer']].append(s)
    records=[]; expanded_triangles=0
    for li,layer in enumerate(layers):
        for r in layer['rows']:
            src=by_layer[li][r['source']-1]
            vertices=list(transform(p,r['tm']) for p in corners(src['min_cm'],src['max_cm']))
            box=(tuple(min(p[k] for p in vertices) for k in range(3)),tuple(max(p[k] for p in vertices) for k in range(3)))
            records.append({'key':(li,r['id']),'box':box,'root':r['tm'][3],'source':src['name'],'layer':li})
            expanded_triangles+=src['triangles']
    plants=[r for r in records if 2<=r['layer']<=5]
    stones=[r for r in records if r['layer']<2]
    start=time.perf_counter(); grid=collections.defaultdict(set)
    for i,r in enumerate(plants):
        for key in cell_keys(r['box']): grid[key].add(i)
    build_ms=(time.perf_counter()-start)*1000
    def query(box):
        possible=set()
        for key in cell_keys(box): possible.update(grid.get(key,()))
        return {i for i in possible if overlaps(plants[i]['box'],box)},len(possible)
    movement=[]; durations=[]; previous=set()
    hero=stones[0]['box']
    for step in range(41):
        shift=-100+step*5
        box=tuple(tuple(v+(shift if k==0 else 0) for k,v in enumerate(side)) for side in hero)
        exact={i for i,p in enumerate(plants) if overlaps(p['box'],box)}
        start=time.perf_counter()
        for repeat in range(25): selected,bucket=query(box)
        durations.append((time.perf_counter()-start)*1000/25)
        assert selected==exact, 'Broad-phase missed an AABB overlap'
        movement.append({'hero_shift_cm':shift,'potentially_affected':len(selected),'grid_candidates':bucket,
                         'old_or_new_affected':len(selected|previous),'leaving_restoration_set':len(previous-selected)})
        previous=selected
    all_current=set()
    for stone in stones: all_current.update(query(stone['box'])[0])
    roots_before=sum(any(inside(r['tm'][3],f['polygon_cm']) for f in footprints) for l in old[2:6] for r in l['rows'])
    roots_after=sum(any(inside(r['root'],f['polygon_cm']) for f in footprints) for r in plants)
    assert roots_after==0, 'Existing Area masks left roots in the fixture footprints'
    result={'scope':'Python offline geometric broad phase over exported real Max placement records; no contact solver, no frame-rate claim.',
            'record_count':len(records),'potential_reactor_count':len(plants),'stone_instances':len(stones),
            'unique_scene_sources':len(source_metrics),'expanded_triangle_equivalent':expanded_triangles,
            'record_payload_96_bytes':len(records)*96,'grid_cell_size_m':0.4,
            'grid_cells':len(grid),'grid_memberships':sum(len(x) for x in grid.values()),
            'grid_build_ms_python':build_ms,'query_median_ms_python':statistics.median(durations),
            'query_max_ms_python':max(durations),'motion_samples':len(movement),'bruteforce_comparisons_equal':True,
            'current_all_rocks_potentially_affected':len(all_current),
            'current_all_rocks_potentially_affected_percent':100*len(all_current)/len(plants),
            'roots_inside_static_xy_hulls_before':roots_before,'roots_inside_static_xy_hulls_after':roots_after,
            'motion':movement,'input_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [run/'placements.json',run/'source-metrics.json',run/'footprints.json']}}
    (run/'spatial-probe.json').write_text(json.dumps(result,indent=2))
    print(json.dumps({k:v for k,v in result.items() if k not in ['motion','input_sha256']},indent=2))

if __name__=='__main__': main()
