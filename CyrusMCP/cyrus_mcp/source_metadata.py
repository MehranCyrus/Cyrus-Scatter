"""Small scalar result of native baked-source inspection; never bulk geometry."""
import re
from .contracts import number,require

MAX_FACES=2000000
MAX_VERTICES=1000000
SCHEMA="cyrus.source-measurement/1.0"


def bounds(low,high):
    require(type(low) is list and type(high) is list and len(low)==len(high)==3,"Invalid native source bounds")
    for a,b in zip(low,high):number(a,-1e6,1e6);number(b,-1e6,1e6);require(a<=b,"Reversed native source bounds")
    return {"minimum":low,"maximum":high,"size":[b-a for a,b in zip(low,high)]}


def decode(raw):
    require(type(raw) is list and len(raw)==11 and raw[10]==SCHEMA,"Unsupported native source measurement")
    number(raw[0],1,MAX_FACES,True);number(raw[1],1,MAX_VERTICES,True)
    local=bounds(raw[2],raw[3]);world=bounds(raw[4],raw[5])
    number(raw[6],0,2e6);number(raw[7],raw[6],2e6)
    for sha in raw[8:10]:require(type(sha) is str and re.fullmatch("[a-f0-9]{64}",sha),"Invalid native geometry fingerprint")
    return {"triangles":raw[0],"vertices":raw[1],"world_aabb_m":world,"geometry_world_sha256":raw[9],
            "geometry_fingerprint_schema":SCHEMA,
            "source_geometry":{"available":True,"basis":"node local; node transform removed, object offsets retained",
                "local_aabb_m":local,"height_m":local["size"][2],"radius_xy_from_pivot_m":raw[6],"radius_xyz_from_pivot_m":raw[7],
                "source_geometry_sha256":raw[8],"geometry_fingerprint_schema":SCHEMA,
                "unchecked":["Materials/textures and renderer dependencies","Asset unit provenance","Proxy/other geometry types outside this baked-mesh admission"]}}
