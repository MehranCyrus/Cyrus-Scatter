from copy import deepcopy
import ast
import json
from pathlib import Path
from types import SimpleNamespace
import pytest
from cyrus_mcp import asset_use
from cyrus_mcp.contracts import Fault
from cyrus_mcp.service import Service,Journal
from cyrus_mcp.models import AssetUse
from test_scene_context import SceneHost
from test_service import apply

def info():
    return dict(schema="cyrus.prepared-source/1.0",vertices=12000,triangles=20000,
                minimum_m=[-1,-1,0],maximum_m=[1,1,2],radius_xy_m=1.5,radius_xyz_m=2.5,
                mesh_storage_bytes=2000000,mapping_channels=2,stored_normals=True)

def snapshot():
    return dict(package_revision="a"*64,entries=[dict(node_id="node-1",name="Grass",mesh_sha256="b"*64,geometry=info()),
                dict(node_id="node-2",name="Flowers",mesh_sha256="c"*64,geometry=info())],
                resources=dict(file_bytes=2000000,mesh_encoded_bytes=1800000,image_pixels=10000,source_nodes=2,materials=2,maps=3),
                dependencies=dict(status="native_finite_adapter_preflight"))

class AssetHost(SceneHost):
    def __init__(self):super().__init__();self.imported=0;self.ready=False;self.released=0;self.fail_mode=None
    def begin_source_package(self,path):self.ready=False
    def release_source_package(self):self.released+=1
    def poll_source_package(self):return snapshot() if self.ready else None
    def use_source_assets(self,value):
        if self.fail_mode=="none":raise Fault("LICENSE_REQUIRED","License denied",effects="none")
        if self.fail_mode=="rollback":raise Fault("ASSET_USE_FAILED","Injected native rollback",rollback="verified")
        self.imported+=1
        rows=[dict(object_id="imported_"+str(i),asset_ref=row["asset_ref"]) for i,row in enumerate(value["sources"])]
        self.cards.extend(dict(object_id=row["object_id"],label="new source",status="available",geometry="unmeasured") for row in rows)
        result=dict(asset_use_id="asset_use_one",sources=rows,package_revision=value["package_revision"],undo_label="Source assets")
        if self.fail_mode=="committed":raise Fault("POST_COMMIT_FAILED","Injected after commit",effects="committed",result=result)
        return result

@pytest.fixture
def service(tmp_path):
    s=Service(AssetHost(),Journal(tmp_path/"ops.json"));s.inspect_scene(["receiver"],"Plant a meadow")
    s.assign_scene_role("receiver",["object_a"])
    return s

def ready(s):
    s.share_source_package("local-only-not-a-model-argument")
    assert s.poll_source_package() is True
    s.host.ready=True
    assert s.poll_source_package() is False
    return s.asset_grant

def use(s):
    return dict(use_schema="cyrus.asset-use/1.0",scope_id=s.scope["scope_id"],task_id=s.task["task_id"],task_revision=s.task["task_revision"],
                grant_id=s.asset_grant["grant_id"],asset_refs=[row["asset_ref"] for row in s.asset_grant["entries"]],destination="task_sources")

def validated(s):ready(s);return s.validate_asset_use(use(s))

def test_separate_grant_and_exact_approval_are_required(service):
    ready(service);request=use(service)
    AssetUse.model_validate(request)
    with pytest.raises(Exception):AssetUse.model_validate({**request,"path":"C:/arbitrary.max"})
    original=deepcopy(service.task)
    v=service.dispatch("assets.validate_use",dict(use=request))
    assert service.host.imported==0 and service.task==original and not service.journal.records
    with pytest.raises(Fault) as exc:apply(service,v)
    assert exc.value.code=="APPROVAL_REQUIRED"
    service.revoke_source_package()
    with pytest.raises(Fault):service.validate_asset_use(request)
    assert service.host.imported==0

def test_committed_sources_join_same_task_without_consuming_placement_budget(service):
    value=validated(service);task_id=service.task["task_id"];scope_id=service.scope["scope_id"]
    service.approve(value["validation_id"]);queued=apply(service,value)
    service.step();result=apply(service,value)
    assert result["operation"]["state"]=="succeeded" and result["operation"]["effects"]=="committed"
    assert service.host.imported==1 and service.applications==0 and not service.owned
    assert service.task["task_id"]==task_id and service.scope["scope_id"]==scope_id
    assert service.task["roles"]["object_a"]==["receiver"]
    assert service.task["roles"]["imported_0"]==service.task["roles"]["imported_1"]==["source"]
    assert len(service.context(scope_id)["scope"]["snapshot"]["objects"])==4
    assert apply(service,value)==result and queued["operation"]["operation_id"]==result["operation"]["operation_id"]
    assert service.asset_grant["uses"]==1
    with pytest.raises(Fault):service.validate_asset_use(use(service))

@pytest.mark.parametrize("edit",["role","brief","rename","revoke","replace"])
def test_changed_task_or_grant_cannot_reuse_approval(service,edit):
    value=validated(service);service.approve(value["validation_id"])
    if edit=="role":service.assign_scene_role("preserve",["object_b"])
    if edit=="brief":service.update_scene_brief("Use flowers near the gate")
    if edit=="rename":service.host.cards[0]["label"]="changed"
    if edit=="revoke":service.revoke_source_package()
    if edit=="replace":ready(service)
    with pytest.raises(Fault):apply(service,value)
    assert service.host.imported==0

def test_queued_cancel_does_not_import_and_revoke_requires_cancel_first(service):
    value=validated(service);service.approve(value["validation_id"]);apply(service,value)
    with pytest.raises(Fault):service.revoke_source_package()
    service.cancel();service.revoke_source_package();service.step()
    assert apply(service,value)["operation"]["state"]=="cancelled" and service.host.imported==0

@pytest.mark.parametrize("mode,effects,state",[("none","none","failed"),("rollback","verified_rollback","failed"),("committed","committed","failed")])
def test_native_faults_report_their_actual_effects_without_replay(service,mode,effects,state):
    value=validated(service);service.approve(value["validation_id"]);apply(service,value)
    service.host.fail_mode=mode;service.step();record=apply(service,value)["operation"]
    assert record["effects"]==effects and record["state"]==state
    assert service.recovery_required==(effects=="committed")
    if effects=="committed":
        assert record["result"]["asset_use_id"]=="asset_use_one"
        assert record["commit_identity"]["asset_use_id"]=="asset_use_one"
        with pytest.raises(Fault):service.validate_asset_use(use(service))

def test_queued_metadata_staleness_has_no_native_effect(service):
    value=validated(service);service.approve(value["validation_id"]);apply(service,value)
    service.host.cards[0]["label"]="intervening rename";service.step()
    record=apply(service,value)["operation"]
    assert record["effects"]=="none" and record["state"]=="failed" and service.host.imported==0

def test_prepare_failure_reset_and_lifecycle_release_only_handles(service,monkeypatch):
    service.share_source_package("local")
    monkeypatch.setattr(service.host,"poll_source_package",lambda:(_ for _ in ()).throw(RuntimeError("private path")))
    with pytest.raises(Fault):service.poll_source_package()
    assert service.asset_grant["status"]=="failed" and "private path" not in json.dumps(service.connection())
    released=service.host.released;service.reset()
    assert service.asset_grant is None and service.host.released==released+1 and service.task is None

def test_journal_failure_before_import_preserves_no_effects(service,monkeypatch):
    value=validated(service);service.approve(value["validation_id"])
    monkeypatch.setattr(service.journal,"save",lambda:(_ for _ in ()).throw(OSError("disk")))
    with pytest.raises(Fault):apply(service,value)
    assert service.host.imported==0 and service.pending is None
    record=next(iter(service.journal.records.values()))
    assert record["effects"]=="none" and service.recovery_required

@pytest.mark.parametrize("mutation",["large_faces","nan","bytes","duplicate","outside","destination"])
def test_prepared_contracts_and_references_are_bounded(service,mutation):
    if mutation in ("large_faces","nan","bytes","duplicate"):
        value=snapshot()
        if mutation=="large_faces":value["entries"][0]["geometry"]["triangles"]=2000001
        if mutation=="nan":value["entries"][0]["geometry"]["maximum_m"][0]=float("nan")
        if mutation=="bytes":value["entries"][0]["geometry"]["mesh_storage_bytes"]=asset_use.MAX_MESH_BYTES+1
        if mutation=="duplicate":value["entries"][1]["node_id"]="node-1"
        with pytest.raises(Fault):asset_use.ready_snapshot(value,"grant_one")
    else:
        ready(service);request=use(service)
        if mutation=="outside":request["asset_refs"][0]="unshared"
        if mutation=="destination":request["destination"]="existing_source_replacement"
        with pytest.raises(Fault):service.validate_asset_use(request)

def test_local_preflight_is_bounded_and_leaves_native_hash_verification_separate(tmp_path):
    graph=dict(nodes=[{}],meshes=[{}],materials=[],maps=[],files=[dict(kind="mesh",bytes=1024)],splines=[])
    for name,value in (("cyrus.package.json",dict(hostYear=2027)),("assets.json",graph),("entry.csrecipe.json",{})):
        (tmp_path/name).write_text(json.dumps(value))
    root,revision,resources=asset_use.preflight(tmp_path)
    assert root==tmp_path and len(revision)==64 and resources["mesh_encoded_bytes"]==1024
    graph["files"][0]["bytes"]=33*1024**2
    (tmp_path/"assets.json").write_text(json.dumps(graph))
    with pytest.raises(Fault):asset_use.preflight(tmp_path)
    (tmp_path/"assets.json").write_bytes(b" "*(asset_use.MAX_GRAPH_BYTES+1))
    with pytest.raises(Fault):asset_use.preflight(tmp_path)

def test_actual_plant_image_tier_is_finite_and_not_the_legacy_16mp_tier(tmp_path):
    graph=dict(version=3,nodes=[{}],meshes=[{}],materials=[],files=[dict(kind="mesh",bytes=1024)],
               maps=[dict(kind="bitmap",size=[5000,5000]),dict(kind="bitmap",size=[5000,5000])])
    for name,value in (("cyrus.package.json",dict(hostYear=2027)),("assets.json",graph),("entry.csrecipe.json",{})):
        (tmp_path/name).write_text(json.dumps(value))
    assert asset_use.preflight(tmp_path)[2]["image_pixels"]==50000000
    graph["maps"].append(dict(kind="bitmap",size=[5000,5000]))
    (tmp_path/"assets.json").write_text(json.dumps(graph))
    with pytest.raises(Fault):asset_use.preflight(tmp_path)

@pytest.mark.parametrize("licensed",[False,True])
def test_actual_host_use_keeps_preflight_and_post_commit_effects_distinct(licensed):
    # Execute the actual host method against a tiny runtime double; no copied method.
    tree=ast.parse((Path(__file__).parents[1]/"cyrus_mcp/source_assets_host.py").read_text())
    cls=next(node for node in tree.body if isinstance(node,ast.ClassDef) and node.name=="PreparedSources")
    method=next(node for node in cls.body if isinstance(node,ast.FunctionDef) and node.name=="use")
    entered=[]
    class Undo:
        def __enter__(self):entered.append("undo")
        def __exit__(self,*args):return False
    node=SimpleNamespace(renderable=True)
    runtime=SimpleNamespace(selection=[],units=SimpleNamespace(decodeValue=lambda _:1),cyrusLicenseAllows=lambda:licensed,
        theHold=SimpleNamespace(GetUndoNames=lambda:[]),Array=lambda *args:list(args),hide=lambda _:None,
        setUserProp=lambda *args:None,getHandleByAnim=lambda _:123,clearSelection=lambda:None)
    geometry=asset_use.source_info(info())
    host=SimpleNamespace(assert_main=lambda:None,busy=lambda:False,scene_nodes={},source_descriptor=lambda _:dict(triangles=20000,vertices=12000,source_geometry=dict(local_aabb_m=geometry["local_aabb_m"])),
        node_label=lambda _:"Source")
    def checkpoint(phase):
        if phase=="asset_after_native_commit":raise Fault("HOST_ERROR","Injected completion fault")
    host.checkpoint=checkpoint
    adapter=SimpleNamespace(host=host,token=1,graph=object(),preflight_revision="a"*64,entries={"node-1":object()},
        dependencies=lambda:None,scope_state=lambda:dict(original=True),root=Path("C:/owned"),
        stage=lambda *args:None,stage_sources=lambda sources,created:(created.append(node) or [node]))
    from cyrus_mcp.contracts import require,number
    namespace=dict(__package__="cyrus_mcp",Fault=Fault,require=require,number=number,rt=runtime,pymxs=SimpleNamespace(undo=lambda *args:Undo()))
    exec(compile(ast.Module(body=[method],type_ignores=[]),"actual_source_use","exec"),namespace)
    with pytest.raises(Fault) as exc:
        namespace["use"](adapter,dict(package_revision="a"*64,sources=[dict(node_id="node-1",asset_ref="prepared_one",geometry=geometry)]))
    if not licensed:
        assert exc.value.code=="LICENSE_REQUIRED" and exc.value.details["effects"]=="none" and not entered
    else:
        assert entered==["undo"] and exc.value.details["effects"]=="committed"
        assert exc.value.details["result"]["selection_preserved"] is None and exc.value.details["result"]["asset_use_id"]
