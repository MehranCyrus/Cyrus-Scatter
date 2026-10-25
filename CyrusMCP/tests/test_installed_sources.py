"""Installed catalog selection is distinct from preparation permission and scene approval."""
import ast
from copy import deepcopy
import hashlib
import json
from pathlib import Path
from types import SimpleNamespace
import pytest
from cyrus_mcp import installed_sources as links
from cyrus_mcp.contracts import Fault,canonical,digest,require
from cyrus_mcp.service import Service,Journal
from test_asset_use import AssetHost,snapshot,use
from test_library import entry,payload
from test_service import apply


class InstalledHost(AssetHost):
    def __init__(self):super().__init__();self.preparations=[];self.begin_error=None
    def version(self):return {**super().version(),"prepared_source_use_api":1,"prepared_source_cohort_api":1}
    def installed_model_catalog(self):
        return payload([entry(i,prepared_source=dict(status="prepared",ready_for_import=False,
            package_revision="a"*64,source_node_id="node-1")) for i in range(3)])
    def begin_installed_sources(self,entries):
        self.preparations.append(deepcopy(entries));self.ready=False
        if self.begin_error:raise self.begin_error


@pytest.fixture
def service(tmp_path):
    value=Service(InstalledHost(),Journal(tmp_path/"ops.json"));value.inspect_scene(["receiver"])
    value.share_installed_catalog()
    return value


def request(s,key="select_one",count=2):
    return dict(scope_id=s.scope["scope_id"],library_id=s.library_grant["library_id"],
        permission_id=s.installed_source_grant["permission_id"] if s.installed_source_grant else "not_enabled",
        asset_refs=[row["asset_ref"] for row in s.library_grant["entries"][:count]],request_key=key)


def test_metadata_alone_does_not_grant_preparation_or_import(service):
    with pytest.raises(Fault) as exc:service.dispatch("assets.prepare_sources",request(service))
    assert exc.value.code=="APPROVAL_REQUIRED" and not service.host.preparations
    for method in ("enable_installed_sources","revoke_installed_sources"):
        with pytest.raises(Fault):service.dispatch(method,{})
    service.enable_installed_sources();before=deepcopy(service.task)
    result=service.dispatch("assets.prepare_sources",request(service))
    assert result["prepared_sources"]["status"]=="preparing"
    assert service.task==before and service.host.imported==0 and not service.journal.records
    service.host.ready=True;service.poll_source_package()
    assert service.asset_grant["origin"]=="installed_catalog"
    v=service.validate_asset_use(use(service))
    with pytest.raises(Fault) as exc:apply(service,v)
    assert exc.value.code=="APPROVAL_REQUIRED" and service.host.imported==0
    service.approve(v["validation_id"]);apply(service,v);service.step()
    assert service.host.imported==1 and service.asset_grant["uses"]==1


def test_same_preparation_key_observes_without_restart_or_budget_consumption(service):
    service.enable_installed_sources();args=request(service)
    first=service.prepare_installed_sources(**args)
    assert service.prepare_installed_sources(**args)==first
    assert len(service.host.preparations)==1 and service.installed_source_grant["preparations_remaining"]==7
    with pytest.raises(Fault) as exc:service.prepare_installed_sources(**{**args,"asset_refs":list(reversed(args["asset_refs"]))})
    assert exc.value.code=="IDEMPOTENCY_CONFLICT"
    with pytest.raises(Fault) as exc:service.prepare_installed_sources(**request(service,"other"))
    assert exc.value.code=="HOST_BUSY"
    service.host.ready=True;service.poll_source_package()
    assert service.prepare_installed_sources(**args)["prepared_sources"]["status"]=="ready"
    service.revoke_source_package()
    assert service.prepare_installed_sources(**args)["status"]=="retired"
    assert len(service.host.preparations)==1 and service.asset_grant is None


@pytest.mark.parametrize("action",["revoke","refresh","reset","metadata_revoke"])
def test_permission_lifecycle_releases_installed_handles_and_approvals(service,action):
    service.enable_installed_sources();args=request(service);service.prepare_installed_sources(**args)
    service.host.ready=True;service.poll_source_package();v=service.validate_asset_use(use(service));service.approve(v["validation_id"])
    released=service.host.released
    {"revoke":service.revoke_installed_sources,"refresh":service.share_installed_catalog,
     "reset":service.reset,"metadata_revoke":service.revoke_installed_catalog}[action]()
    assert service.installed_source_grant is None and service.asset_grant is None and not service.approved
    assert service.host.released==released+1 and service.host.imported==0
    with pytest.raises(Fault):service.prepare_installed_sources(**args)


def test_failed_prepare_retains_key_and_sanitizes_private_errors(service):
    service.enable_installed_sources();args=request(service)
    service.host.begin_error=OSError("F:/private/models/tree.max")
    with pytest.raises(Fault) as exc:service.prepare_installed_sources(**args)
    assert "private" not in str(exc.value) and not service.asset_grant
    service.host.begin_error=None
    assert service.prepare_installed_sources(**args)["status"]=="failed"
    assert len(service.host.preparations)==1


def test_unavailable_unknown_duplicate_and_arbitrary_path_are_not_prepared(service):
    service.enable_installed_sources();args=request(service)
    for refs in ([args["asset_refs"][0]]*2,["unknown"],["F:/private/file"],[],[[]]):
        with pytest.raises(Fault):service.prepare_installed_sources(**{**args,"asset_refs":refs})
    with pytest.raises(Fault):service.dispatch("assets.prepare_sources",{**args,"path":"F:/private/file"})
    service.library_grant["entries"][0]["prepared_source"]["status"]="deferred"
    with pytest.raises(Fault):service.prepare_installed_sources(**args)
    assert not service.host.preparations and service.installed_source_grant["preparations_remaining"]==8


def test_preparation_budget_cannot_be_reset_by_toggling_permission(service):
    service.enable_installed_sources()
    for index in range(8):
        service.prepare_installed_sources(**request(service,"key_"+str(index)))
        service.revoke_source_package()
    service.revoke_installed_sources();service.enable_installed_sources()
    with pytest.raises(Fault) as exc:service.prepare_installed_sources(**request(service,"ninth"))
    assert exc.value.code=="BUDGET_EXCEEDED" and len(service.host.preparations)==8


def test_old_native_pair_cannot_grant_installed_cohort_permission(service,monkeypatch):
    monkeypatch.setattr(service.host,"version",lambda:dict(prepared_source_use_api=1))
    with pytest.raises(Fault) as exc:service.enable_installed_sources()
    assert exc.value.code=="UNSUPPORTED_CAPABILITY" and service.installed_source_grant is None


def index_fixture(tmp_path):
    folder=tmp_path/"PreparedModels/model_0/package";folder.mkdir(parents=True)
    manifest=canonical(dict(hostYear=2027)).encode();(folder/"cyrus.package.json").write_bytes(manifest)
    model=entry()
    row=dict(entry_id=model["entry_id"],scene_sha256=model["scene_sha256"],status="prepared",
        package="PreparedModels/model_0/package",manifest_sha256=hashlib.sha256(manifest).hexdigest(),
        package_revision=digest(json.loads(manifest)),source_node_id="node-1")
    value=dict(format="cyrus.prepared-model-index",version=1,host_year=2027,catalog_sha256="d"*64,entries=[row])
    (tmp_path/links.INDEX_NAME).write_text(canonical(value))
    return value,model,folder


def test_index_binding_uses_only_bounded_manifest_metadata(tmp_path):
    value,model,folder=index_fixture(tmp_path)
    index,entries=links.load(tmp_path,"d"*64,[model])
    assert entries["model_0"]["_directory"]==str(folder)
    descriptor=links.descriptor(entries["model_0"],index)
    assert descriptor["status"]=="prepared" and descriptor["ready_for_import"] is False
    assert str(tmp_path) not in canonical(descriptor) and "package" not in descriptor
    # Meshes/images need not be read or even exist for availability metadata.
    assert list(folder.iterdir())==[folder/"cyrus.package.json"]


@pytest.mark.parametrize("mutation",["catalog","scene","manifest","revision","escape","absolute","duplicate","unknown","oversize","extra"])
def test_index_rejects_changed_or_unconfined_bindings(tmp_path,mutation):
    value,model,folder=index_fixture(tmp_path);row=value["entries"][0]
    if mutation=="catalog":value["catalog_sha256"]="e"*64
    if mutation=="scene":row["scene_sha256"]="e"*64
    if mutation=="manifest":(folder/"cyrus.package.json").write_text('{"hostYear":2026}')
    if mutation=="revision":row["package_revision"]="e"*64
    if mutation=="escape":row["package"]="../outside"
    if mutation=="absolute":row["package"]="F:/outside"
    if mutation=="duplicate":value["entries"].append(deepcopy(row))
    if mutation=="unknown":row["entry_id"]="unknown"
    if mutation=="extra":row["path"]="private"
    encoded=canonical(value) if mutation!="oversize" else " "*(links.MAX_INDEX_BYTES+1)
    (tmp_path/links.INDEX_NAME).write_text(encoded)
    with pytest.raises(Fault):links.load(tmp_path,"d"*64,[model])


def actual_adapter_method(name,namespace):
    tree=ast.parse((Path(__file__).parents[1]/"cyrus_mcp/source_assets_host.py").read_text())
    cls=next(n for n in tree.body if isinstance(n,ast.ClassDef))
    method=next(n for n in cls.body if isinstance(n,ast.FunctionDef) and n.name==name)
    exec(compile(ast.Module(body=[method],type_ignores=[]),"actual_adapter","exec"),namespace)
    return namespace[name]


@pytest.mark.parametrize("fail_second",[False,True])
def test_actual_multi_package_stage_tracks_earlier_nodes_and_preserves_request_order(fail_second):
    parts=[dict(graph="graph_a",root="a",token=1),dict(graph="graph_b",root="b",token=2)]
    created=[];calls=[]
    def stage(graph,root,token,ids,nodes):
        calls.append(token)
        if fail_second and token==2:raise RuntimeError("second package failure")
        nodes.extend("node_"+str(token)+"_"+value for value in ids)
    adapter=SimpleNamespace(parts=parts,entries={"a":dict(part=parts[0],node_id="original_a"),"b":dict(part=parts[1],node_id="original_b")},
        host=SimpleNamespace(checkpoint=lambda _:None),stage=stage)
    method=actual_adapter_method("stage_sources",dict(rt=SimpleNamespace(Array=lambda *args:list(args)),require=require))
    sources=[dict(node_id="b"),dict(node_id="a")]
    if fail_second:
        with pytest.raises(RuntimeError):method(adapter,sources,created)
        assert created==["node_1_original_a"]  # The outer native hold can roll this exact tracked node back.
    else:assert method(adapter,sources,created)==["node_2_original_b","node_1_original_a"]
    assert calls==[1,2]


def test_actual_cohort_admission_rejects_aggregate_bytes_before_starting_workers(monkeypatch):
    from cyrus_mcp import asset_use
    started=[]
    resources=dict(file_bytes=30*1024**2,mesh_encoded_bytes=1024,image_pixels=1000,source_nodes=1,materials=1,maps=1,graph_version=1)
    monkeypatch.setattr(asset_use,"preflight",lambda path:(Path(path),"a"*64,deepcopy(resources)))
    adapter=SimpleNamespace(host=SimpleNamespace(assert_main=lambda:None,busy=lambda:False),parts=[],
        release=lambda:None,supported=lambda:True,cohort_supported=lambda:True,start_part=lambda part:started.append(part))
    method=actual_adapter_method("begin_many",dict(__package__="cyrus_mcp",deepcopy=deepcopy,require=require,digest=digest,preflight=asset_use.preflight))
    with pytest.raises(Fault) as exc:method(adapter,[dict(directory=name) for name in ("one","two","three")])
    assert exc.value.code=="BUDGET_EXCEEDED" and not started and all(part["token"] is None for part in adapter.parts)


@pytest.mark.parametrize("retained",[False,True])
def test_actual_cohort_poll_publishes_only_after_all_serial_workers_are_ready(retained):
    import time
    started=[];frozen=[];released=[]
    parts=[dict(token=None,graph=None,identity=i) for i in range(3)]
    def start(part):part["token"]=part["identity"]+1;started.append(part["token"])
    def freeze(part):
        part.update(graph=object(),entries=[dict(node_id="node-1",name="source"+str(part["identity"]))]);frozen.append(part["token"])
    polls={1:["preparing","ready"],2:["ready"],3:["preparing","ready"]}
    adapter=SimpleNamespace(host=SimpleNamespace(assert_main=lambda:None),parts=parts,started=time.monotonic(),
        start_part=start,freeze_part=freeze,resources={},preflight_revision="a"*64,dependencies=lambda:dict(status="checked"),cohort_supported=lambda:retained)
    method=actual_adapter_method("poll",dict(require=require,time=time,deepcopy=deepcopy,
        rt=SimpleNamespace(cyrusAssetPackagePoll=lambda token:[polls[token].pop(0)],
            cyrusAssetPackageRetain=lambda token:token+100,cyrusAssetPackageRelease=lambda token:released.append(token))))
    assert method(adapter) is None and started==[1] and not frozen
    expected=[101,102,103] if retained else [1,2,3]
    assert method(adapter) is None and started==[1,2,3] and frozen==expected[:2]
    result=method(adapter)
    assert frozen==expected and [row["node_id"] for row in result["entries"]]==["p0_node-1","p1_node-1","p2_node-1"]
    assert released==([1,2,3] if retained else [])
    assert result["resources"]["source_nodes"]==3
