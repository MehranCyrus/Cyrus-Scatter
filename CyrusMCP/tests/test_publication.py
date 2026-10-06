from copy import deepcopy
import pytest
from cyrus_mcp.contracts import Fault
from cyrus_mcp.publication import manifest,page
from cyrus_mcp.service import Service,Journal
from test_service import Host


def publication():
    return ["publication-a",7,160,.01,3,
            [["set-a","layer-a",1,1,2,3,6,8,17,[["source-tree",123,True,False,False]]],
             ["set-b","layer-a",1,2,1,2,4,4,19,[["source-point",0,False,True,True]]]],
            [[1,"set-a","set-b",True,.75,50,False]],"a"*64,"immutable input signature"]


def native_rows():
    tm=[[0,2,0],[-3,0,0],[.25,0,4],[100,200,300]]
    return [[1,deepcopy(tm),1,"c:2",False,10,True],
            [1,deepcopy(tm),1,"clone:7",True,25,True],
            [2,deepcopy(tm),1,"c:2",False,5,False]]


def test_source_set_identity_units_and_matrix_preserve_published_values():
    raw=publication();m=manifest(raw)
    raw[5][0][9][0][0]="changed-after-publication"
    p=page([m["publication_id"],3,3,native_rows()],m,0,500)
    assert m["sets"][0]["sources"][0]["source_entry_id"]=="source-tree"
    assert m["pair_rules"][0]["gap_m"]==.5
    assert p["rows"][0]["transform"]==[[0,-3,.25,1],[2,0,0,2],[0,0,4,3],[0,0,0,1]]
    assert p["rows"][1]["effective_radius_m"]==.25 and p["rows"][1]["protected"]
    assert p["rows"][0]["instance_id"]==p["rows"][2]["instance_id"]  # IDs include their set owner.
    assert not p["rows"][2]["included_in_exact_output"] and not p["training_eligible"]
    assert not p["has_more"] and p["next_offset"]==3


def test_page_crosses_set_boundary_and_empty_tail():
    m=manifest(publication())
    p=page(["publication-a",3,3,native_rows()[1:]],m,1,2)
    assert [r["set_id"] for r in p["rows"]]==["set-a","set-b"]
    assert page(["publication-a",3,3,[]],m,3,2)["rows"]==[]


@pytest.mark.parametrize("change",[
    lambda rows:rows[0].__setitem__(0,2),
    lambda rows:rows[0].__setitem__(2,2),
    lambda rows:rows[1].__setitem__(3,"c:2"),
    lambda rows:rows[0].__setitem__(5,-1),
    lambda rows:rows[2].__setitem__(6,True),
    lambda rows:rows[0][1][0].__setitem__(0,float("nan")),
])
def test_corrupt_native_publication_rejected(change):
    rows=native_rows();change(rows)
    with pytest.raises(Fault):page(["publication-a",3,3,rows],manifest(publication()),0,3)


def test_stale_identity_and_incomplete_page_rejected():
    m=manifest(publication())
    with pytest.raises(Fault,match="changed"):page(["new-publication",3,3,native_rows()],m,0,3)
    with pytest.raises(Fault,match="Incomplete"):page(["publication-a",3,2,native_rows()[:2]],m,0,3)
    raw=publication();raw[4]=4
    with pytest.raises(Fault,match="counts disagree"):manifest(raw)


def test_scope_and_expiry_budget_fail_closed_without_scene_evaluation(tmp_path):
    host=Host();service=Service(host,Journal(tmp_path/"journal.json"));service.observe(None)
    host.publication_manifest=lambda _:manifest(publication())
    host.publication_page=lambda _,pub,offset,limit:[pub,3,min(3,offset+limit),native_rows()[offset:offset+limit]]
    def cannot_evaluate():raise AssertionError("Publication inspection evaluated the scene")
    host.fingerprint=cannot_evaluate
    args=dict(scene_epoch=service.epoch,controller_id="observed_x",publication_id="publication-a",offset=0,limit=3)
    with pytest.raises(Fault,match="manifest first"):service.dispatch("scatter.read_publication_page",args)
    service.publication(service.epoch,"observed_x")
    assert len(service.dispatch("scatter.read_publication_page",args)["page"]["rows"])==3
    assert host.generated==0
    service.publications["observed_x"]=(manifest(publication()),0)
    with pytest.raises(Fault,match="manifest first"):service.dispatch("scatter.read_publication_page",args)
    service.publication(service.epoch,"observed_x")
    service.publication_pages=2048
    with pytest.raises(Fault,match="budget exhausted"):service.dispatch("scatter.read_publication_page",args)
    service.reset()
    assert service.publications=={} and service.publication_pages==0
