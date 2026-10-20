"""Independent actual-mesh base/support/path proof; no native footprint or proxy.

Area coverage is proved by clipping a triangle-derived base hull against disjoint
actual receiving top triangles. The exported source anchor defines pose reference
only. This is geometry/support validation, not center-of-mass or gravity analysis.
"""
import argparse
import copy
import hashlib
import json
import math
from itertools import combinations
from pathlib import Path
from verify_shelves_stairs import (actual_base_points, bounds, cross, dot,
                                  mesh_gap_certificate, read_meshes, require, sub)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def turn(a, b, c):
    return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])


def area(poly):
    return abs(sum(turn(poly[0], poly[i], poly[i+1]) for i in range(1, len(poly)-1)))/2 if len(poly) >= 3 else 0


def hull(points):
    points = sorted(set((p[0], p[1]) for p in points))
    require(len(points) >= 3, 'Actual base has no projected support area')
    def chain(values):
        result = []
        for p in values:
            while len(result) >= 2 and turn(result[-2], result[-1], p) <= 0:
                result.pop()
            result.append(p)
        return result
    return chain(points)[:-1]+chain(points[::-1])[:-1]


def clip(poly, triangle):
    """Convex intersection, all arithmetic relative to actual edge origins."""
    if turn(*triangle) < 0:
        triangle = triangle[::-1]
    for a, b in zip(triangle, triangle[1:]+triangle[:1]):
        result = []
        for p, q in zip(poly, poly[1:]+poly[:1]):
            dp, dq = turn(a, b, p), turn(a, b, q)
            inside, other = dp >= 0, dq >= 0
            if inside:
                result.append(p)
            if inside != other:
                ratio = dp/(dp-dq)
                result.append(tuple(p[k]+ratio*(q[k]-p[k]) for k in range(2)))
        poly = result
        if not poly:
            break
    return poly


def top_triangles(receiver):
    result, z = [], receiver['bounds'][1][2]
    for face in receiver['faces']:
        p = [receiver['vertices'][i-1] for i in face[:3]]
        if all(abs(v[2]-z) <= .001 for v in p) and cross(sub(p[1], p[0]), sub(p[2], p[0]))[2] > 1e-8:
            result.append([(v[0], v[1]) for v in p])
    require(0 < len(result) <= 256, 'Receiver has no admitted actual upward top triangles')
    # Coverage sums must not double-count overlapping faces to hide a hole.
    for a, b in combinations(result, 2):
        require(area(clip(a, b)) < 1e-5, 'Actual receiving top triangles overlap')
    return result


def body_components(mesh):
    parents = list(range(len(mesh['vertices'])))
    def root(i):
        while parents[i] != i:
            parents[i] = parents[parents[i]]
            i = parents[i]
        return i
    for f in mesh['faces']:
        for i in f[1:3]:
            parents[root(i-1)] = root(f[0]-1)
    ids = {}
    for f in mesh['faces']:
        ids.setdefault(root(f[0]-1), set()).update(i-1 for i in f[:3])
    require(len(ids) <= 16, 'Component proof admission exceeded')
    result = []
    for key, indices in ids.items():
        indices = sorted(indices)
        remap = {old: new+1 for new, old in enumerate(indices)}
        vertices = [mesh['vertices'][i] for i in indices]
        faces = [tuple(remap[i-1] for i in f[:3])+tuple(f[3:]) for f in mesh['faces'] if root(f[0]-1) == key]
        result.append(dict(vertices=vertices, faces=faces, bounds=bounds(vertices)))
    return result


def gap(a, b):
    al, ah = a['bounds']; bl, bh = b['bounds']
    return math.sqrt(sum(max(0, bl[k]-ah[k], al[k]-bh[k])**2 for k in range(3)))


def verify(meshes, name):
    count = 3 if name == 'random-three' else 1
    require(len(meshes['source']) == 1 and len(meshes['output']) == count, 'Wrong actual source/output quantity')
    source = meshes['source'][0]
    require(source.get('anchor') is not None, 'Explicit source pose anchor required')
    outputs = meshes['output']
    require(len({m['pose']['stable_id'] for m in outputs}) == count, 'Repeated output identity')
    path = name.startswith('path-')
    require(len(meshes['receiver']) == (0 if path else 1), 'Wrong receiving geometry count')
    tops = top_triangles(meshes['receiver'][0]) if not path else []
    maximum_error, minimum_coverage = 0., 1.
    overhangs = 0
    for output in outputs:
        pose = output['pose']
        require(pose['source'] == 1 and pose['parent'] == 0, 'Unexpected source/stack identity')
        lo, hi = ((.8, 1.1) if count == 3 else (.5, .751) if name.endswith('-fit') else (1., 1.))
        require(lo <= pose['scale'] <= hi, 'Final scale differs from permitted physical range')
        require([f[:3] for f in output['faces']] == [f[:3] for f in source['faces']], 'Actual complete source topology changed')
        require(len(source['vertices']) == len(output['vertices']), 'Actual source vertex count changed')
        cosine, sine = math.cos(math.radians(pose['yaw'])), math.sin(math.radians(pose['yaw']))
        for a, b in zip(source['vertices'], output['vertices']):
            x, y, z = (v*pose['scale'] for v in sub(a, source['anchor']))
            wanted = tuple(p+q for p, q in zip(pose['position'], (cosine*x-sine*y, sine*x+cosine*y, z)))
            error = math.dist(wanted, b)
            require(error <= .04, 'Actual output transform differs from reported pose and complete source')
            maximum_error = max(maximum_error, error)
        base = hull(actual_base_points(output, .5*pose['scale']))
        require(area(base) > 1e-6, 'Actual support base is degenerate')
        low, high = output['bounds']
        require(abs(low[2]-pose['position'][2]) <= .03, 'Actual support minimum differs from pose height')
        if path:
            center = tuple((min(v[k] for v in base)+max(v[k] for v in base))/2 for k in range(2))
            require(math.dist(center, (3000, 3000)) <= .03 and abs(low[2]) <= .03, 'Actual base center misses the spline center')
            width = 300 if name == 'path-fit' else 1000
            require(low[1] >= 3000-width/2-.04 and high[1] <= 3000+width/2+.04, 'Complete actual body leaves its permitted lane')
            require(abs((low[0]+high[0])/2-center[0]-100*pose['scale']) <= .03, 'Asymmetric upper body was incorrectly centered instead of the base')
        else:
            receiver = meshes['receiver'][0]
            require(abs(low[2]-receiver['bounds'][1][2]) <= .03, 'Actual support is lifted or penetrates the receiver')
            covered = sum(area(clip(base, t)) for t in tops)
            require(abs(covered-area(base)) <= max(.001, area(base)*1e-8), 'Actual triangle-derived base lacks complete receiving support')
            minimum_coverage = min(minimum_coverage, covered/area(base))
            # Every complete body vertex is on/above this fixture's maximum:
            # no receiver triangle or solid can penetrate the output above it.
            require(all(v[2] >= receiver['bounds'][1][2]-.03 for v in output['vertices']), 'Complete actual body penetrates the receiver')
            rl, rh = receiver['bounds']
            overhangs += any(low[k] < rl[k]-.03 or high[k] > rh[k]+.03 for k in range(2))
    if name in ('round-original', 'round-fit', 'prepared-plant'):
        require(overhangs == 1, 'Fixture did not exercise a genuine complete-body overhang')
    if count == 3:
        require(max(m['pose']['scale'] for m in outputs)-min(m['pose']['scale'] for m in outputs) > .001, 'Random scales did not vary')
        for a, b in combinations(outputs, 2):
            if gap(a, b) >= 9.96:
                continue
            for x in body_components(a):
                for y in body_components(b):
                    if gap(x, y) < 9.96:
                        mesh_gap_certificate(x, y, 10.)
    return dict(status='passed', outputs=count, actual_vertices_per_source=len(source['vertices']), maximum_world_vertex_error_mm=maximum_error,
                minimum_actual_support_coverage=minimum_coverage if not path else None, full_body_overhangs=overhangs,
                scope='actual referenced base clipping and disjoint receiver-triangle coverage; complete source transform/topology, full-body lane bounds and independent component gap proof; no native footprint/proxy')


def negatives(original):
    result = []
    for name, expected in (('lift', 'support'), ('outside', 'support'), ('scale', 'transform'), ('missing_top', 'support'), ('unused_low_vertex', 'referenced contact')):
        bad = copy.deepcopy(original)
        output, source = bad['output'][0], bad['source'][0]
        if name in ('lift', 'outside'):
            delta = (0, 0, 5) if name == 'lift' else (5000, 0, 0)
            output['vertices'] = [tuple(x+y for x, y in zip(v, delta)) for v in output['vertices']]
            output['pose']['position'] = tuple(x+y for x, y in zip(output['pose']['position'], delta))
        elif name == 'scale':
            # Corrupt actual size while retaining a permitted reported scale.
            output['vertices'] = [tuple(a+.5*(v-a) for v, a in zip(p, output['pose']['position'])) for p in output['vertices']]
        elif name == 'missing_top':
            receiver = bad['receiver'][0]
            for i, face in enumerate(receiver['faces']):
                p = [receiver['vertices'][j-1] for j in face[:3]]
                if cross(sub(p[1], p[0]), sub(p[2], p[0]))[2] > 0 and all(abs(v[2]-20) < .001 for v in p):
                    receiver['faces'].pop(i)
                    break
        else:
            source['anchor'] = tuple(v-(5 if k == 2 else 0) for k, v in enumerate(source['anchor']))
            source['vertices'].append(source['anchor'])
            output['pose']['position'] = tuple(v-(5*output['pose']['scale'] if k == 2 else 0) for k, v in enumerate(output['pose']['position']))
            output['vertices'].append(output['pose']['position'])
        for mesh in (source, output):
            mesh['bounds'] = bounds(mesh['vertices'])
        try:
            verify(bad, 'round-original')
        except ValueError as error:
            require(expected in str(error), 'Invalid control rejected for wrong reason: '+str(error))
            result.append(dict(case=name, status='correctly-rejected', reason=str(error)))
        else:
            raise ValueError('Independent verifier accepted invalid geometry: '+name)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    run = args.run.resolve(); rp = run/'receipt.json'; receipt = json.loads(rp.read_text())
    require(receipt['status'] == 'passed' and receipt['exit_code'] == 0 and receipt['test_script'] == 'tests/max/arrange_base_support_tests.ms', 'Successful exact-pair Max base fixture required')
    for key in ('loaded_path_matches', 'loaded_storage_path_matches', 'binaries_unchanged', 'private_ini_matches', 'artist_profiles_unchanged'):
        require(receipt[key] is True, 'Failed host guard: '+key)
    for filename in ('verify_base_support.py', 'verify_shelves_stairs.py'):
        require(receipt['sources']['tools/'+filename] == sha(Path(__file__).parent/filename), 'Verifier differs from exact frozen source pair')
    cases = {name: read_meshes(run/(name+'-meshes.txt')) for name in ('round-original', 'round-fit', 'random-three', 'path-base', 'path-fit', 'prepared-plant')}
    result = dict(status='passed', host_receipt_sha256=sha(rp), cases={k:verify(v, k) for k, v in cases.items()},
                  negative_controls=negatives(cases['round-original']), exports={k:sha(run/(k+'-meshes.txt')) for k in cases})
    (run/'independent-base-support.json').write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
