from copy import deepcopy
import json
import math
from pathlib import Path
import random
import pytest


def test_oversized_integer_is_a_contract_error():
    from cyrus_mcp.contracts import number, Fault
    with pytest.raises(Fault):
        number(10**1000,0,2000,True)
from cyrus_mcp.contracts import Fault, decode, validate_shape
from cyrus_mcp.geometry import convex, contains, inset, overlaps, area, max_to_column_matrix


def plan(context="context_x"):
    return {"schema_version":"1.0","context_id":context,"name":"Test layout","layers":[{"name":"Trees","region_id":"region_x","count":100,"seed":42,"sources":[{"source_id":"source_x","weight":1}],"scale":[.8,1.2],"yaw_degrees":[0,360],"underfill":"allow"}]}


@pytest.mark.parametrize("raw",['{"x":1,"x":2}','{"x":NaN}','{"x":Infinity}','{"x":1e999}', '['*19+'0'+']'*19, '{"x":'])
def test_hostile_json(raw):
    with pytest.raises(Fault):decode(raw)


@pytest.mark.parametrize("field,value",[("count",True),("count",-1),("count",2001),("seed",1.5),("seed",2**31),("scale",[2,1]),("scale",[float('nan'),1]),("yaw_degrees",[0,361]),("underfill","silently_refill"),("name","x\nexecute")])
def test_invalid_layer(field,value):
    p=plan();p["layers"][0][field]=value
    with pytest.raises((Fault,ValueError)):validate_shape(p)


def test_unknown_code_and_aggregate_budget():
    for key in ("script","execute","path","url","approve"):
        p=plan();p[key]="arbitrary"
        with pytest.raises(Fault):validate_shape(p)
    p=plan();p["layers"]*=3
    for i,layer in enumerate(p["layers"]):
        p["layers"][i]=dict(layer,name=str(i),count=1000)
    with pytest.raises(Fault):validate_shape(p)


def test_schema_accepts_valid_and_matches_unknown_field_policy():
    import jsonschema
    schema=json.loads((Path(__file__).parents[1]/"cyrus_mcp/plan.schema.json").read_text())
    jsonschema.validate(plan(),schema)
    assert validate_shape(plan())==100
    with pytest.raises(jsonschema.ValidationError):jsonschema.validate({**plan(),"execute":"x"},schema)


@pytest.mark.parametrize("polygon",[[[0,0],[2,2],[0,2],[2,0]],[[0,0],[2,0],[1,1],[2,2],[0,2]],[[0,0],[0,0],[1,1]]])
def test_reject_ambiguous_regions(polygon):
    with pytest.raises(Fault):convex(polygon)


def test_rotated_convex_inset_preserves_entire_disk():
    rng=random.Random(981)
    for _ in range(100):
        angle=rng.random()*math.tau
        def rotate(p):return [p[0]*math.cos(angle)-p[1]*math.sin(angle),p[0]*math.sin(angle)+p[1]*math.cos(angle)]
        poly=convex([rotate(p) for p in [[-8,-5],[8,-5],[8,5],[-8,5]]])
        margin=.01+rng.random()*3
        smaller=inset(poly,margin)
        for p in smaller:
            assert contains(poly,p,margin)
            for t in range(72):
                q=[p[0]+margin*math.cos(t*math.tau/72),p[1]+margin*math.sin(t*math.tau/72)]
                assert contains(poly,q)
        assert area(smaller)<area(poly)


def test_infeasible_and_protected_regions():
    a=[[0,0],[1,0],[1,1],[0,1]]
    with pytest.raises(Fault):inset(a,1)
    assert overlaps(a,[[.5,.5],[2,.5],[2,2],[.5,2]])
    assert not overlaps(a,[[1,0],[2,0],[2,1],[1,1]])


def test_matrix_translation_and_rotation_units():
    matrix=max_to_column_matrix([[0,1,0],[-1,0,0],[0,0,1],[100,200,300]],.01)
    assert matrix==[[0,-1,0,1],[1,0,0,2],[0,0,1,3],[0,0,0,1]]
