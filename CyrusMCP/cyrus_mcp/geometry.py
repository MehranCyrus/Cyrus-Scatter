"""Convex XY masks, in metres. Reject ambiguity instead of repairing authored data."""
import math
from .contracts import require


def cross(a, b, c):
    return (b[0]-a[0])*(c[1]-a[1]) - (b[1]-a[1])*(c[0]-a[0])


def area(poly):
    return sum(a[0]*b[1]-a[1]*b[0] for a, b in zip(poly, poly[1:]+poly[:1])) / 2


def hull(points):
    """Convex hull for comparing a triangulated site's boundary and total area.

    This avoids treating float32 roundoff on a subdivided rotated straight edge
    as authored concavity. The host separately verifies one manifold boundary
    and equality of the covered triangle area; a hull alone is not eligibility.
    """
    points=sorted(set(tuple(p) for p in points))
    halves=[]
    for sequence in (points,list(reversed(points))):
        part=[]
        for p in sequence:
            while len(part)>=2 and cross(part[-2],part[-1],p)<=0:
                part.pop()
            part.append(p)
        halves.append(part[:-1])
    return [list(p) for p in halves[0]+halves[1]]


def convex(poly):
    require(3 <= len(poly) <= 64, "A region needs 3–64 straight corners", "GEOMETRY_CONSTRAINT")
    require(all(len(p) == 2 and all(math.isfinite(x) and abs(x) <= 1e6 for x in p) for p in poly), "Invalid region coordinates", "GEOMETRY_CONSTRAINT")
    if area(poly) < 0:
        poly = list(reversed(poly))
    require(area(poly) > 1e-8, "Region has no area", "GEOMETRY_CONSTRAINT")
    # Every vertex must lie inside every edge: also rejects self intersections.
    for a, b in zip(poly, poly[1:]+poly[:1]):
        require(math.dist(a, b) > 1e-7 and all(cross(a,b,p) >= -1e-8 for p in poly), "Region must be simple and convex", "GEOMETRY_CONSTRAINT")
    return poly


def contains(poly, point, margin=0.0, tolerance=1e-6):
    return all(cross(a,b,point) / math.dist(a,b) >= margin-tolerance for a,b in zip(poly,poly[1:]+poly[:1]))


def inset(poly, margin):
    result = list(poly)
    for a, b in zip(poly, poly[1:]+poly[:1]):
        length = math.dist(a,b)
        def distance(p):
            return cross(a,b,p)/length-margin
        output = []
        for p, q in zip(result, result[1:]+result[:1]):
            dp,dq = distance(p),distance(q)
            if dp >= 0:
                output.append(p)
            if (dp >= 0) != (dq >= 0):
                t=dp/(dp-dq)
                output.append([p[0]+t*(q[0]-p[0]), p[1]+t*(q[1]-p[1])])
        result = output
        if len(result) < 3:
            break
    require(len(result) >= 3 and area(result) > 1e-8, "Source footprint does not fit the region", "GEOMETRY_CONSTRAINT")
    return result


def overlaps(a, b):
    for poly in (a,b):
        for p,q in zip(poly,poly[1:]+poly[:1]):
            axis = [q[1]-p[1], p[0]-q[0]]
            aa=[sum(x*y for x,y in zip(v,axis)) for v in a]
            bb=[sum(x*y for x,y in zip(v,axis)) for v in b]
            if max(aa) <= min(bb)+1e-8 or max(bb) <= min(aa)+1e-8:
                return False
    return True


def max_to_column_matrix(rows, metres_per_unit):
    """Max row-vector Matrix3 -> column-vector, right handed Z up 4x4."""
    return [[rows[j][i] for j in range(3)] + [rows[3][i]*metres_per_unit] for i in range(3)] + [[0,0,0,1]]
