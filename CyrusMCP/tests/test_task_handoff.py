"""Task intent/ref identity survives an explicit separate local design grant."""
from copy import deepcopy
from types import SimpleNamespace

import pytest

from cyrus_mcp.contracts import Fault, require
from cyrus_mcp.scene import source_geometry
from test_scene_context import SceneHost, scene, context
from test_service import validated, apply
from test_operation_integrity import production_method


def install_host(scene, monkeypatch):
    def connect(bindings):
        value=SceneHost.enroll(scene.host,None,[],[])
        value["site"]["label"]="Task site"
        value["site"]["task_object_id"]=bindings["receiver"][0]
        value["sources"][0]["task_object_id"]=bindings["source"][0]
        value["regions"][0]["origin"]="verified_receiver_polygon"
        value.update(task_bindings=deepcopy(bindings),_fingerprint=scene.host.fingerprint())
        return value
    monkeypatch.setattr(scene.host,"connect_task_inputs",connect,raising=False)
    scene.assign_scene_role("receiver",["object_a"])
    scene.assign_scene_role("source",["object_b"])
    return scene


def grant(scene):
    review=scene.prepare_task_design()
    return scene.connect_task_design(review["review_id"],review["digest"])


def test_explicit_handoff_keeps_intent_refs_and_requires_new_exact_approval(scene,monkeypatch):
    install_host(scene,monkeypatch)
    before=deepcopy(scene.task);old_scope=scene.scope["scope_id"]
    review=scene.prepare_task_design()
    assert scene.scope["kind"]=="scene_inspection" and not scene.owned
    scope=scene.connect_task_design(review["review_id"],review["digest"])
    assert scope["kind"]=="design" and scope["scope_id"]!=old_scope and not scope["allow_capture"]
    assert scene.task["task_id"]==before["task_id"] and scene.task["brief"]==before["brief"] and scene.task["roles"]==before["roles"]
    assert scene.host.refs==["native_a","native_b"] and scene.host.generated==0
    value=context(scene)
    assert value["task"]["stage"]=="design" and value["settings_contract_resource"]=="cyrus://capabilities"
    assert value["scope"]["sources"][0]["task_object_id"]=="object_b"
    assert "task_snapshot" not in value["scope"]
    proposal=validated(scene)
    with pytest.raises(Fault,match="Approve"):apply(scene,proposal)
    scene.approve(proposal["validation_id"]);apply(scene,proposal);scene.step()
    undo=scene.last_undo;revision=scene.revision
    pending=validated_refinement(scene)
    scene.approve(pending["validation_id"])
    scene.update_scene_brief("More flowers, same task")
    assert scene.last_undo==undo and scene.revision==revision
    assert not scene.approved and not scene.validations and not scene.contexts
    assert scene.owned and scene.task["brief"]=="More flowers, same task"


def validated_refinement(scene):
    from test_contracts import plan
    value=plan(context(scene)["context_id"])
    value.update(controller_id="controller_1",generation_id="generation_1")
    return scene.validate(value)


@pytest.mark.parametrize("change",["brief","roles","rename","delete","expiry","wrong_digest"])
def test_changed_review_never_promotes_scope(scene,monkeypatch,change):
    install_host(scene,monkeypatch)
    review=scene.prepare_task_design()
    if change=="brief":scene.update_scene_brief("Changed intent")
    elif change=="roles":scene.assign_scene_role("preserve",["object_a"])
    elif change=="rename":scene.host.cards[0]["label"]="renamed"
    elif change=="delete":scene.host.cards[1]["status"]="missing"
    elif change=="expiry":scene.task_design_review["deadline"]=0
    with pytest.raises(Fault):scene.connect_task_design(review["review_id"],"wrong" if change=="wrong_digest" else review["digest"])
    assert scene.scope["kind"]=="scene_inspection" and scene.host.generated==0


def test_failed_native_admission_preserves_task_and_review_is_one_use(scene,monkeypatch):
    install_host(scene,monkeypatch)
    before=deepcopy(scene.task);scope=deepcopy(scene.scope)
    review=scene.prepare_task_design()
    def failed(_):raise Fault("UNSUPPORTED_CAPABILITY","Receiver cannot be authored")
    monkeypatch.setattr(scene.host,"connect_task_inputs",failed)
    with pytest.raises(Fault):scene.connect_task_design(review["review_id"],review["digest"])
    assert scene.task==before and scene.scope==scope and scene.host.refs
    with pytest.raises(Fault):scene.connect_task_design(review["review_id"],review["digest"])


def test_missing_role_can_be_removed_without_rebinding_and_bad_overlap_is_rejected(scene,monkeypatch):
    install_host(scene,monkeypatch)
    scene.host.cards[1]["status"]="missing"
    scene.assign_scene_role("source",["object_b"],remove=True)
    assert "object_b" not in scene.task["roles"]
    with pytest.raises(Fault):scene.prepare_task_design()
    scene.assign_scene_role("source",["object_a"])
    with pytest.raises(Fault,match="distinct"):scene.prepare_task_design()


@pytest.mark.parametrize("name",["prepare_task_design","connect_task_design","extend_scene"])
def test_task_grants_and_scope_expansion_are_not_model_callable(scene,name):
    with pytest.raises(Fault) as error:scene.dispatch(name,{})
    assert error.value.code=="UNSUPPORTED_CAPABILITY"


def test_scope_extension_retains_task_roles_and_does_not_reset_read_budget(scene,monkeypatch):
    scene.assign_scene_role("context",["object_a"])
    before=deepcopy(scene.task);scene.calls=9
    def extend(_):
        scene.host.refs.append("extra")
        scene.host.cards.append(dict(object_id="object_c",status="available",label="extra",geometry="unmeasured"))
        return scene.host.scene_snapshot()
    monkeypatch.setattr(scene.host,"extend_scene",extend,raising=False)
    scene.extend_scene(["extra"])
    assert scene.task["task_id"]==before["task_id"] and scene.task["brief"]==before["brief"]
    assert scene.task["roles"]==before["roles"] and scene.calls==9
    assert len(context(scene)["scope"]["snapshot"]["objects"])==3


@pytest.mark.parametrize("failure",["enroll","fingerprint"])
def test_production_host_restores_internal_inspection_state_if_handoff_fails(failure):
    node=object();old={"old":node}
    runtime=SimpleNamespace(isValidNode=lambda n:n is node)
    method=production_method("connect_task_inputs",{"rt":runtime,"require":require})
    host=SimpleNamespace(assert_main=lambda:None,busy=lambda:False,scene_nodes={"receiver":node,"source":node},
                         nodes=old,controllers={},masks={},layouts={},site=None,metre=1,read_only=True)
    def enroll(*_):
        host.nodes={"changed":node}
        if failure=="enroll":raise RuntimeError("Admission failed")
        return {"site":{},"sources":[{}],"regions":[],"excluded":[]}
    host.enroll=enroll
    host.fingerprint=lambda:(_ for _ in ()).throw(RuntimeError("Fingerprint unavailable"))
    with pytest.raises(RuntimeError):method(host,{"receiver":["receiver"],"source":["source"],"boundary":[],"exclusion":[]})
    assert host.nodes is old and host.read_only


def test_source_local_facts_remove_node_translation_without_removing_object_offsets():
    value=source_geometry([[10,3,0],[12,3,4],[10,5,0]],[[1,0,0],[0,1,0],[0,0,1],[-10,-2,0]],.1)
    for key,expected in {"minimum":[0,.1,0],"maximum":[.2,.3,.4],"size":[.2,.2,.4]}.items():
        assert value["local_aabb_m"][key]==pytest.approx(expected)
    assert value["height_m"]==.4 and value["radius_xy_from_pivot_m"]>0
