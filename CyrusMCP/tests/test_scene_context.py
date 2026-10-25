"""Production onboarding coordinator, read-only authority and native bounds paths."""
from copy import deepcopy
from types import SimpleNamespace
import math

import pytest

from cyrus_mcp.contracts import Fault, digest, require
from cyrus_mcp.scene import brief, references
from cyrus_mcp.service import Journal, Service
from test_service import Host, plan, validated, apply
from test_operation_integrity import production_method


class SceneHost(Host):
    def __init__(self):
        super().__init__()
        self.cards=[dict(object_id="object_a",status="available",label="same name",geometry="unmeasured"),
                    dict(object_id="object_b",status="available",label="same name",geometry="unmeasured")]
        self.measured=[]
        self.refs=[]
    def inspect_scene(self, selected):
        self.refs=list(selected)
        return self.scene_snapshot()
    def clear_scene_selection(self):self.refs.clear()
    def scene_snapshot(self):return dict(objects=deepcopy(self.cards),metres_per_system_unit=1,
                                         geometry_validity="unmeasured",omissions=["geometry","neighbors"])
    def measure_scene(self, ids):
        self.measured.append(ids)
        return {"measurements":[dict(object_id=oid,validity="snapshot_only") for oid in ids]}


@pytest.fixture
def scene(tmp_path):
    service=Service(SceneHost(),Journal(tmp_path/"scene.json"))
    service.inspect_scene(["native_a","native_b"],"A meadow; keep the entrance clear")
    return service


def context(scene):return scene.context(scene.scope["scope_id"])


def test_scene_context_is_read_only_without_invoking_design_fingerprint(scene, monkeypatch):
    monkeypatch.setattr(scene.host,"fingerprint",lambda:pytest.fail("Metadata reads must not export geometry"))
    value=context(scene)
    assert value["task"]["brief"].startswith("A meadow") and value["scope"]["kind"]=="scene_inspection"
    assert value["budget"]["candidates_remaining"]==0 and value["budget"]["captures_remaining"]==0
    assert not scene.contexts and "owned_create" not in value["capabilities"]
    with pytest.raises(Fault,match="inspection only"):
        scene.validate(plan(value["context_id"]))
    with pytest.raises(Fault,match="Inspection"):
        scene.validate_change({})
    with pytest.raises(Fault):scene.undo()
    with pytest.raises(Fault):scene.capture(scene.epoch,scene.revision,"viewport_1","object_a")
    assert scene.host.generated==0 and not scene.journal.records


def test_role_correction_supports_multiple_roles_and_keeps_duplicate_names_distinct(scene):
    scene.assign_scene_role("receiver",["object_a"])
    scene.assign_scene_role("preserve",["object_a","object_b"])
    scene.assign_scene_role("receiver",["object_a"],True)
    assert context(scene)["task"]["roles"]=={"object_a":["preserve"],"object_b":["preserve"]}
    scene.assign_scene_role("source",["object_a"])
    assert scene.task["roles"]["object_a"]==["preserve","source"]
    assert not scene.host.measured and scene.host.generated==0


def test_rename_delete_replacement_and_geometry_refresh_preserve_confirmed_intent(scene):
    scene.assign_scene_role("receiver",["object_a"])
    task=deepcopy(scene.task)
    scene.host.cards[0]["label"]="renamed"
    revision=scene.revision
    assert context(scene)["task"]==task and scene.revision>revision
    # Geometry does not become certified merely because metadata stayed equal.
    scene.host.revision+=1
    assert context(scene)["scope"]["snapshot"]["geometry_validity"]=="unmeasured"
    scene.host.cards[0]={"object_id":"object_a","status":"missing","geometry":"unmeasured"}
    scene.host.cards[1]["label"]="same name"
    assert context(scene)["task"]["roles"]=={"object_a":["receiver"]}
    with pytest.raises(Fault):scene.assign_scene_role("receiver",["object_a"])
    assert "object_b" not in scene.task["roles"] and scene.task["brief"]==task["brief"]


@pytest.mark.parametrize("method",["assign_scene_role","update_scene_brief","scene.inspect_scene","scene.highlight"])
def test_local_authority_actions_are_not_public_dispatch(scene,method):
    with pytest.raises(Fault) as error:scene.dispatch(method,{})
    assert error.value.code=="UNSUPPORTED_CAPABILITY"


@pytest.mark.parametrize("role,ids",[("edit",["object_a"]),("source",["outside"]),("preserve",["object_a","object_a"]),("context",[])])
def test_bad_corrections_are_atomic(scene,role,ids):
    before=deepcopy(scene.task)
    with pytest.raises(Fault):scene.assign_scene_role(role,ids)
    assert scene.task==before


def test_measurements_are_explicit_scoped_and_do_not_modify_roles(scene):
    scene.assign_scene_role("source",["object_a"])
    task=deepcopy(scene.task)
    result=scene.dispatch("scene.measure_objects",{"scope_id":scene.scope["scope_id"],"object_ids":["object_a"]})
    assert result["ok"] and scene.host.measured==[["object_a"]] and scene.task==task
    with pytest.raises(Fault):scene.measure_scene("old_scope",["object_a"])
    with pytest.raises(Fault):scene.measure_scene(scene.scope["scope_id"],["outside"])
    assert len(scene.host.measured)==1
    scene.update_scene_brief("Use flowers too")
    assert scene.task["task_revision"]==task["task_revision"]+1
    scene.reset()
    assert scene.task is None and scene.scope is None


def test_old_design_validation_cannot_cross_scene_onboarding(scene):
    scene.enroll(None,[],[])
    value=validated(scene);scene.approve(value["validation_id"])
    scene.inspect_scene(["selected"])
    with pytest.raises(Fault):apply(scene,value)
    assert scene.host.generated==0 and not scene.approved


def test_native_reference_lifetime_is_one_task_and_reset_releases_it(scene):
    assert scene.host.refs==["native_a","native_b"]
    scene.inspect_scene(["replacement_scope"])
    assert scene.host.refs==["replacement_scope"]
    scene.reset()
    assert scene.host.refs==[] and scene.task is None
    scene.inspect_scene(["next"])
    scene.enroll(None,[],[])
    assert scene.host.refs==[]


@pytest.mark.parametrize("value",[None,0,"x"*2001,"bad\x00text"])
def test_brief_rejects_invalid_input(value):
    with pytest.raises(Fault):brief(value)


@pytest.mark.parametrize("value",[[],["one"]*2,["x"]*33,[None],"object_a"])
def test_reference_admission_rejects_invalid_input(value):
    with pytest.raises(Fault):references(value)


@pytest.mark.parametrize("case",["success","unsupported","over_budget","evaluated_budget"])
def test_native_measurement_admission_precedes_geometry_and_has_physical_units(case):
    entered=[]
    node=SimpleNamespace(transform="identity")
    runtime=SimpleNamespace(isValidNode=lambda n:n is node,units=SimpleNamespace(decodeValue=lambda _:100),
                            inverse=lambda _:[[1,0,0],[0,1,0],[0,0,1],[0,0,0]],
                            getPolygonCount=lambda _:(10001,10) if case=="over_budget" else (1,3))
    method=production_method("measure_scene",{"__name__":"cyrus_mcp.max_host","rt":runtime,"require":require,"math":math,"digest":digest,"Fault":Fault,"point":list})
    def admit(_):
        if case=="unsupported":raise Fault("UNSUPPORTED_CAPABILITY","Unsupported asset")
    def mesh(_):
        entered.append(True)
        return ([[0,0,0]]*12001,[(0,0,0)]) if case=="evaluated_budget" else ([[0,0,0],[100,0,0],[0,200,50]],[(0,1,2)])
    def receiver(*_):raise Fault("UNSUPPORTED_CAPABILITY","Nonhorizontal receiver")
    host=SimpleNamespace(assert_main=lambda:None,busy=lambda:False,scene_nodes={"object_a":node},assert_mesh_input=admit,mesh=mesh,site_polygon=receiver)
    if case=="success":
        value=method(host,["object_a"])["measurements"][0]
        assert value["world_aabb_m"]=={"minimum":[0,0,0],"maximum":[1,2,.5],"size":[1,2,.5]}
        assert value["triangles"]==1 and value["validity"].startswith("snapshot_only")
        assert value["source_geometry"]["height_m"]==.5 and not value["receiver_geometry"]["eligible"]
    else:
        with pytest.raises(Fault):method(host,["object_a"])
    assert bool(entered)==(case in ("success","evaluated_budget"))


def test_temporary_mesh_is_released_when_evaluated_admission_fails():
    mesh=SimpleNamespace(numfaces=10001,numverts=3)
    released=[]
    runtime=SimpleNamespace(getPolygonCount=lambda _:(1,3),snapshotAsMesh=lambda _:mesh,delete=lambda m:released.append(m))
    method=production_method("mesh",{"rt":runtime,"require":require})
    host=SimpleNamespace(assert_mesh_input=lambda _:None)
    with pytest.raises(Fault):method(host,"node")
    assert released==[mesh]
