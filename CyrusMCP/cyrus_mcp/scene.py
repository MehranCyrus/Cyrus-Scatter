"""Bounded onboarding metadata; role meaning is independent of edit authority."""
from .contracts import require

MAX_OBJECTS = 32
MAX_BRIEF = 2000
ROLES = ("receiver", "boundary", "source", "exclusion", "preserve", "context")

# Executed as a fixed internal helper, never interpolated with scene/user text.
# Bound text before pymxs marshals it; no geometry, modifier or child traversal.
HOST_METADATA = r'''(
    fn cyrusMCPSceneMetadata node = (
        local label=node.name as string,kind=(classOf node) as string,superKind=(superClassOf node) as string
        local parent=node.parent
        #(substring label 1 80,label.count>80,substring kind 1 80,substring superKind 1 80,
          node.isHidden,node.isFrozen,if parent==undefined then 0 else getHandleByAnim parent)
    )
)'''


def brief(value):
    require(type(value) is str and len(value) <= MAX_BRIEF,
            "Task brief must contain at most 2,000 characters", "BUDGET_EXCEEDED")
    require(all(ord(c) >= 32 or c in "\n\t" for c in value), "Task brief contains unsupported control characters")
    return value


def references(values, maximum=MAX_OBJECTS):
    from .contracts import identifier
    require(type(values) is list and 1 <= len(values) <= maximum,
            "Choose between one and the allowed number of scoped objects", "BUDGET_EXCEEDED")
    for value in values:
        identifier(value)
    require(len(set(values)) == len(values), "Duplicate object references")
    return values


def source_geometry(vertices, inverse_rows, metre):
    """Bounded copied input vertices; remove node TM and retain object offsets."""
    import math
    from .contracts import digest
    local=[[sum(v[k]*inverse_rows[k][axis] for k in range(3))+inverse_rows[3][axis]
            for axis in range(3)] for v in vertices]
    require(local and all(math.isfinite(x) and abs(x)*metre<=1e6 for v in local for x in v),
            "Invalid source-local coordinates", "GEOMETRY_CONSTRAINT")
    low=[min(p[i] for p in local)*metre for i in range(3)]
    high=[max(p[i] for p in local)*metre for i in range(3)]
    return {"available":True,"basis":"node local; node transform removed, object offsets retained",
            "local_aabb_m":{"minimum":low,"maximum":high,"size":[high[i]-low[i] for i in range(3)]},
            "height_m":high[2]-low[2],"radius_xy_from_pivot_m":max(math.hypot(*p[:2]) for p in local)*metre,
            "radius_xyz_from_pivot_m":max(math.sqrt(sum(x*x for x in p)) for p in local)*metre,
            "source_geometry_sha256":digest({"vertices_local":local,"metres_per_unit":metre}),
            "unchecked":["Materials/textures and renderer dependencies","Asset unit provenance","Source kind/proxy compatibility beyond this static mesh admission"]}
