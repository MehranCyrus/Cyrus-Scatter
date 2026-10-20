"""Independent actual-mesh proof for the shelves/stairs fixture.

No plugin modules, placement code, model bounds or sampler data are imported.
Receiver box geometry is proved from exported vertices/triangles before bounds
are used as an exact solid oracle. UV/material-root preservation is host scope.
"""
import argparse
import copy
from collections import Counter
from itertools import combinations, product
import json
import hashlib
import math
from pathlib import Path


def integer(value):
    return int(value.rstrip("LlPp"))


def require(value, message):
    if not value:
        raise ValueError(message)


def sub(a, b):
    return tuple(x-y for x, y in zip(a, b))


def dot(a, b):
    return sum(x*y for x, y in zip(a, b))


def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])


def bounds(vertices):
    return tuple(tuple(fn(v[i] for v in vertices) for i in range(3)) for fn in (min, max))


def mesh_gap_certificate(a, b, required):
    """A separating projection of ALL actual vertices proves a solid gap.

    This uses actual mesh face normals, not the native compound representation.
    It is conservative for concave meshes too: failure to find a separating
    axis rejects proof; it never declares overlapping convex hulls collision-free.
    """
    seen = set()
    tested = 0

    def test(axis):
        nonlocal tested
        length = math.sqrt(dot(axis, axis))
        if length < 1e-12:
            return None
        axis = tuple(v/length for v in axis)
        if next((v for v in axis if abs(v) > 1e-12), 1) < 0:
            axis = tuple(-v for v in axis)
        key = tuple(round(v, 8) for v in axis)
        if key in seen:
            return None
        seen.add(key); tested += len(a['vertices'])+len(b['vertices'])
        require(tested <= 50000000, 'Independent mesh separation proof exceeded its work cap')
        pa = [dot(v, axis) for v in a['vertices']]
        pb = [dot(v, axis) for v in b['vertices']]
        gap = max(min(pb)-max(pa), min(pa)-max(pb))
        return gap if gap >= required-.04 else None

    al,ah = a['bounds']; bl,bh = b['bounds']
    for axis in ((1,0,0),(0,1,0),(0,0,1),tuple(bl[i]+bh[i]-al[i]-ah[i] for i in range(3))):
        found = test(axis)
        if found is not None:
            return found
    for mesh in (a,b):
        v = mesh['vertices']
        for f in mesh['faces']:
            found = test(cross(sub(v[f[1]-1],v[f[0]-1]),sub(v[f[2]-1],v[f[0]-1])))
            if found is not None:
                return found
    raise ValueError('Actual output geometry overlaps or lacks a proved requested separation')


def read_meshes(path):
    meshes = {key: [] for key in ("receiver", "source", "output")}
    with path.open(encoding="utf-8-sig") as f:
        def row():
            line = f.readline()
            require(bool(line), "Truncated mesh export")
            return line.split()
        while True:
            line = f.readline()
            if not line:
                break
            header = line.split()
            require(len(header) == 5 and header[0] == "mesh", "Malformed mesh header")
            _, kind, index, nv, nf = header
            index, nv, nf = map(integer, (index, nv, nf))
            require(kind in meshes and index == len(meshes[kind])+1, "Unordered/unknown mesh identity")
            require(3 <= nv <= 250000 and 1 <= nf <= 250000, "Mesh exceeds admission")
            vertices, faces = [], []
            for _ in range(nv):
                r = row()
                require(len(r) == 4 and r[0] == "v", "Malformed vertex")
                v = tuple(map(float, r[1:]))
                require(all(math.isfinite(x) for x in v), "Nonfinite mesh vertex")
                vertices.append(v)
            for _ in range(nf):
                r = row()
                require(len(r) == 6 and r[0] == "f", "Malformed face")
                face = tuple(map(integer, r[1:]))
                require(all(1 <= x <= nv for x in face[:3]), "Invalid vertex reference")
                faces.append(face)
            pose = None
            if kind == "output":
                r = row()
                require(len(r) == 9 and r[0] == "pose", "Malformed output pose")
                pose = dict(source=integer(r[1]), stable_id=integer(r[2]), position=tuple(map(float, r[3:6])), yaw=float(r[6]), scale=float(r[7]), parent=integer(r[8]))
                require(all(math.isfinite(x) for x in (*pose["position"], pose["yaw"], pose["scale"])), "Nonfinite output pose")
            trailer, anchor = row(), None
            if kind == "source" and trailer[0] == "anchor":
                require(len(trailer) == 4, "Malformed source transform anchor")
                anchor = tuple(map(float, trailer[1:]))
                low, high = bounds(vertices)
                require(all(math.isfinite(x) and low[k]-.03 <= x <= high[k]+.03 for k, x in enumerate(anchor)), "Invalid source transform anchor")
                require(abs(anchor[2]-low[2]) <= .03, "Source transform anchor is not at its complete minimum")
                trailer = row()
            require(trailer == ["end"], "Missing mesh terminator")
            meshes[kind].append(dict(vertices=vertices, faces=faces, bounds=bounds(vertices), pose=pose, anchor=anchor))
            require(sum(map(len, meshes.values())) <= 256, "Node count exceeds fixture admission")
    return meshes


def actual_base_points(mesh, band_mm):
    """Independent triangle clipping; never reads native footprint metadata."""
    low = mesh['bounds'][0][2]
    plane, points, contact = low+band_mm, [], False
    for face in mesh['faces']:
        triangle = [mesh['vertices'][i-1] for i in face[:3]]
        normal = cross(sub(triangle[1], triangle[0]), sub(triangle[2], triangle[0]))
        if dot(normal, normal) <= 1e-18:
            continue
        contact |= min(v[2] for v in triangle) <= low+.03
        for p, q in zip(triangle, triangle[1:]+triangle[:1]):
            inside, other = p[2] <= plane, q[2] <= plane
            if inside:
                points.append(p)
            if inside != other:
                ratio = (plane-p[2])/(q[2]-p[2])
                points.append(tuple(p[k]+ratio*(q[k]-p[k]) for k in range(3)))
    require(contact and points, 'Actual support has no referenced contact at the complete mesh minimum')
    return points


def prove_box(mesh):
    v, faces, (low, high) = mesh["vertices"], mesh["faces"], mesh["bounds"]
    require(len(v) == 8 and len(faces) == 12, "Receiver is not an eight-corner/twelve-triangle box")
    expected = set(product(*zip(low, high)))
    require(set(v) == expected and all(high[i] > low[i] for i in range(3)), "Receiver corners do not prove a rectangular solid")
    edges, planes, plane_areas = Counter(), Counter(), Counter()
    for face in faces:
        ids = tuple(x-1 for x in face[:3])
        a, b, c = (v[x] for x in ids)
        n = cross(sub(b, a), sub(c, a))
        require(dot(n, n) > 0, "Degenerate receiver triangle")
        plane = [(axis, side) for axis in range(3) for side, target in enumerate((low[axis], high[axis])) if all(abs(p[axis]-target) < 1e-8 for p in (a, b, c))]
        require(len(plane) == 1, "Receiver triangle is not on one exact exterior plane")
        axis, side = plane[0]
        require(n[axis]*(1 if side else -1) > 0 and all(abs(n[k]) < 1e-8 for k in range(3) if k != axis), "Receiver winding is not outward")
        planes[plane[0]] += 1
        plane_areas[plane[0]] += abs(n[axis])/2
        for x, y in zip(ids, ids[1:]+ids[:1]):
            edges[x, y] += 1
    require(all(edges[y, x] == count == 1 for (x, y), count in edges.items()), "Receiver mesh is not a closed consistently oriented surface")
    for axis in range(3):
        area = math.prod(high[i]-low[i] for i in range(3) if i != axis)
        for side in range(2):
            require(planes[axis, side] == 2 and math.isclose(plane_areas[axis, side], area, rel_tol=1e-10), "Receiver exterior plane is incomplete")


def verify_meshes(meshes, expected_count, edge, gap):
    for receiver in meshes["receiver"]:
        prove_box(receiver)
    sources, outputs = meshes["source"], meshes["output"]
    require(len(outputs) == expected_count, "Requested output quantity was not published")
    require(len({o["pose"]["stable_id"] for o in outputs}) == len(outputs), "Duplicate stable output identity")
    max_error, min_gap = 0.0, math.inf
    support_counts, source_counts = Counter(), Counter()
    for output in outputs:
        pose = output["pose"]
        require(1 <= pose["source"] <= len(sources), "Output source identity does not exist")
        source = sources[pose["source"]-1]
        require(pose["parent"] == 0 and 0.8 <= pose["scale"] <= 1.1, "Unexpected stack or final scale")
        require(output["faces"] == source["faces"], "Actual face topology/material IDs/smoothing differ from source")
        require(len(output["vertices"]) == len(source["vertices"]), "Source vertex count changed")
        sl, sh = source["bounds"]
        # The exported anchor defines the pose reference only. Actual support and
        # solid/gap proof below are computed independently from output triangles.
        anchor = source.get('anchor') or ((sl[0]+sh[0])/2, (sl[1]+sh[1])/2, sl[2])
        cosine, sine = math.cos(math.radians(pose["yaw"])), math.sin(math.radians(pose["yaw"]))
        for a, b in zip(source["vertices"], output["vertices"]):
            x, y, z = (t*pose["scale"] for t in sub(a, anchor))
            wanted = tuple(p+q for p, q in zip(pose["position"], (cosine*x-sine*y, sine*x+cosine*y, z)))
            error = math.dist(wanted, b)
            require(error <= 0.04, "Actual output vertices do not match the reported final transform")
            max_error = max(max_error, error)
        low, high = output["bounds"]
        base_low, base_high = bounds(actual_base_points(output, .5*pose['scale']))
        supporting = []
        for i, receiver in enumerate(meshes["receiver"], 1):
            rl, rh = receiver["bounds"]
            if abs(low[2]-rh[2]) <= 0.03 and all(base_low[k] >= rl[k]+edge-0.04 and base_high[k] <= rh[k]-edge+0.04 for k in range(2)):
                supporting.append(i)
            intersection = [min(high[k], rh[k])-max(low[k], rl[k]) for k in range(3)]
            require(not all(x > 0.03 for x in intersection), "Full actual output envelope penetrates receiver solid")
        require(bool(supporting), "Actual triangle-derived base lacks one proved solid support surface with edge clearance")
        require(abs(low[2]-pose["position"][2]) <= 0.03, "Actual base contact differs from reported anchor")
        support_counts[supporting[0]] += 1
        source_counts[pose["source"]] += 1
    refined_pairs = 0
    minimum_proved_gap = math.inf
    for a, b in combinations(outputs, 2):
        al, ah = a["bounds"]; bl, bh = b["bounds"]
        overlap = all(min(ah[k], bh[k])-max(al[k], bl[k]) > 0.03 for k in range(3))
        distance = math.sqrt(sum(max(0, bl[k]-ah[k], al[k]-bh[k])**2 for k in range(3)))
        if overlap or distance < gap-.04:
            certificate = mesh_gap_certificate(a,b,gap)
            refined_pairs += 1
        else:
            certificate = distance
        minimum_proved_gap = min(minimum_proved_gap,certificate)
        min_gap = min(min_gap, distance)
    require(len(support_counts) == (4 if expected_count == 100 else 6), "Balanced output did not exercise every broad usable support level")
    if expected_count == 100:
        require(support_counts[1] > 0 and support_counts[2] > 0, "Lower actual internal shelves were not used")
    else:
        require(len(source_counts) == 3, "Arbitrary stair prop types were not all used")
        require(source_counts[1] >= 8 and source_counts[3] >= 4, "Required book/bin counts were not preserved before small fill")
    return dict(status="passed", outputs=len(outputs), proved_solid_receivers=len(meshes["receiver"]), actual_support_counts=dict(support_counts), actual_source_counts=dict(source_counts), maximum_world_vertex_error_mm=max_error, minimum_pair_envelope_gap_mm=min_gap, minimum_proved_mesh_gap_mm=minimum_proved_gap, mesh_refined_pairs=refined_pairs, edge_margin_mm=edge, required_gap_mm=gap, scope="independent actual vertices/topology/triangle-derived 0.5mm base/receiver solids; complete envelopes or all-vertex separation prove body gaps; exported anchor defines pose reference only; authored UV/material-root checks are in Max")


def verify(path, expected_count, edge, gap):
    return verify_meshes(read_meshes(path), expected_count, edge, gap)


def negative_controls(meshes):
    results = []
    for case, expected in (("lift", "support"), ("outside", "support"), ("overlap", "overlap"), ("broken_receiver", "box")):
        bad = copy.deepcopy(meshes)
        if case == "broken_receiver":
            bad["receiver"][0]["faces"].pop()
        elif case == "overlap":
            first, second = bad["output"][:2]
            stable_id = second["pose"]["stable_id"]
            second.update(copy.deepcopy(first))
            second["pose"]["stable_id"] = stable_id
        else:
            output = bad["output"][0]
            delta = (0, 0, 5) if case == "lift" else (2000, 0, 0)
            output["vertices"] = [tuple(x+y for x, y in zip(v, delta)) for v in output["vertices"]]
            output["pose"]["position"] = tuple(x+y for x, y in zip(output["pose"]["position"], delta))
            output["bounds"] = bounds(output["vertices"])
        try:
            verify_meshes(bad, 100, 5, 2)
        except ValueError as e:
            require(expected in str(e), "Negative control rejected for the wrong reason: "+str(e))
            results.append(dict(case=case, status="correctly-rejected", reason=str(e)))
        else:
            raise ValueError("Independent verifier accepted invalid geometry: "+case)
    return results


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run", type=Path)
    args = parser.parse_args()
    run = args.run.resolve()
    receipt_path = run/"receipt.json"
    receipt = json.loads(receipt_path.read_text())
    require(receipt["status"] == "passed" and receipt["exit_code"] == 0 and receipt["report"].startswith("SUCCESS"), "A successful exact-pair Max host receipt is required")
    for key in ("loaded_path_matches", "loaded_storage_path_matches", "binaries_unchanged", "private_ini_matches", "artist_profiles_unchanged"):
        require(receipt[key] is True, "Failed host guard: "+key)
    require(receipt["test_script"] == "tests/max/arrange_shelves_stairs_tests.ms", "Wrong host fixture")
    require(receipt["sources"]["tools/verify_shelves_stairs.py"] == sha(Path(__file__)), "Verifier differs from frozen source pair")
    report = {name: verify(run/(name+"-meshes.txt"), count, edge, gap) for name, count, edge, gap in (("shelves100", 100, 5, 2), ("stairs48", 48, 8, 10))}
    result = dict(status="passed", host_receipt_sha256=sha(receipt_path), cases=report, negative_controls=negative_controls(read_meshes(run/"shelves100-meshes.txt")), exports={n:sha(run/n) for n in ("shelves100-meshes.txt", "stairs48-meshes.txt")})
    (run/"independent-shelves-stairs.json").write_text(json.dumps(result, indent=2)+"\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
