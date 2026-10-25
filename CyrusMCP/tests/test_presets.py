"""Frozen settings discovery has no scene/application/approval authority."""
from copy import deepcopy
import hashlib
import json
import pytest
from cyrus_mcp import presets
from cyrus_mcp.contracts import Fault,canonical,digest
from cyrus_mcp.service import Service,Journal
from test_scene_context import SceneHost


def native(category="spacing"):
    if category=="spacing":
        values=dict(enabled=True,multiplier=1.25,gap=.15,planar=True)
        spec=[dict(name=name,kind=kind,minimum=low,maximum=high,distance_metres=distance) for name,kind,low,high,distance in
            (("enabled","boolean",0,1,False),("multiplier","number",0,10000,False),("gap","number",0,1e9,True),("planar","boolean",0,1,False))]
    else:values=dict(domain="unit",samples=[0.,1.],graph=[]);spec=[]
    document=dict(format="cyrus.settings-preset",version=3,category=category,name="Gentle "+category,values=values)
    encoded=json.dumps(document,indent=2)+"\n"
    return dict(document_json=encoded,fields=spec,preset_sha256="a"*64,document_sha256=hashlib.sha256(encoded.encode()).hexdigest())


def row(index=0,category="spacing"):
    value=native(category)
    return dict(entry_key=digest(["native_key",index]),name="Gentle "+category,category=category,
        preset_sha256=value["preset_sha256"],document_sha256=value["document_sha256"],source_bytes=100,
        field_count=4 if category=="spacing" else 0,sample_count=0 if category=="spacing" else 2,graph_count=0,
        domain="settings" if category=="spacing" else "unit")


def payload(entries=None):
    rows=entries if entries is not None else [row(),row(1,"density_curve")]
    return dict(state="complete",scanned=len(rows),entry_count=len(rows),invalid=0,limited=False,has_error=False,pages=1,entries=rows)


class PresetHost(SceneHost):
    def __init__(self):super().__init__();self.closed=0;self.result=payload();self.started=[];self.inspected=[]
    def start_preset_catalog(self,kind,root):self.started.append((kind,root))
    def stop_preset_catalog(self):self.closed+=1
    def poll_preset_catalog(self):return deepcopy(self.result)
    def inspect_preset_entry(self,key):
        self.inspected.append(key);return native(next(item["category"] for item in self.result["entries"] if item["entry_key"]==key))


@pytest.fixture
def service(tmp_path):
    value=Service(PresetHost(),Journal(tmp_path/"ops.json"));value.inspect_scene(["receiver"])
    return value


def shared(service):
    service.share_preset_catalog("custom_presets","private-local-folder");service.poll_preset_catalog()
    return dict(scope_id=service.scope["scope_id"],library_id=service.preset_grant["library_id"])


def test_only_local_sharing_and_closed_read_dispatch(service,monkeypatch):
    before=deepcopy(service.task),deepcopy(service.scope),service.revision
    with pytest.raises(Fault) as exc:service.search_presets(service.scope["scope_id"],"invented")
    assert exc.value.code=="APPROVAL_REQUIRED"
    for name in ("share_preset_catalog","presets.share","presets.apply","presets.approve"):
        with pytest.raises(Fault):service.dispatch(name,{})
    args=shared(service);monkeypatch.setattr(service.host,"fingerprint",lambda:pytest.fail("No geometry evaluation"))
    monkeypatch.setattr(service.host,"poll_preset_catalog",lambda:pytest.fail("Remote reads must not scan"))
    page=service.dispatch("presets.search",args)
    info=service.dispatch("presets.inspect_entry",dict(**args,preset_ref=page["entries"][0]["preset_ref"]))
    assert not info["use_supported"] and not info["evidence"]["ready_for_application"]
    assert info["document"]["version"]==3 and service.host.inspected
    assert "private-local-folder" not in canonical(info) and "entry_key" not in info["entry"]
    assert (service.task,service.scope,service.revision)==before and not service.owned and not service.journal.records
    with pytest.raises(Fault):service.dispatch("presets.inspect_entry",dict(**args,preset_ref="unknown",path="private"))


def test_scalar_physical_units_and_curve_data_are_native_frozen_documents():
    grant=presets.snapshot(payload());grant.update(library_id="presets_test",kind="custom_presets")
    for entry in grant["entries"]:
        result=presets.inspect(grant,entry,native(entry["category"]))
        if entry["category"]=="spacing":
            assert result["document"]["values"]["gap"]==.15
            assert next(field for field in result["fields"] if field["name"]=="gap")["distance_metres"]
        else:assert result["document"]["values"]==dict(domain="unit",samples=[0.,1.],graph=[])


def test_capability_resource_advertises_discovery_and_separate_preparation_authority():
    from cyrus_mcp.settings import capability_manifest
    value=capability_manifest()
    discovery=value["content_discovery"]["settings_presets"]
    assert discovery["tools"]==["presets_search","presets_inspect_entry"]
    assert discovery["entries"]==512 and discovery["page_size"]==24 and discovery["categories"]==list(presets.CATEGORIES)
    preparation=value["prepared_source_use"]["installed_preparation"]
    assert preparation["tool"]=="assets_prepare_sources" and preparation["native_retained_snapshot_api"]==1 and preparation["local_permission_required"]


def test_512_entry_paging_and_stable_refs_fit_the_scope_read_budget(service):
    service.host.result=payload([row(index) for index in range(512)]);args=shared(service)
    all_rows=[];offset=0
    while offset is not None:
        page=service.dispatch("presets.search",dict(**args,offset=offset))
        assert len(page["entries"])<=24 and len(canonical(page).encode())<=32768
        all_rows+=page["entries"];offset=page["next_offset"]
    assert len({entry["preset_ref"] for entry in all_rows})==512 and service.calls==22
    assert service.search_presets(**args,query="GENTLE",category="spacing")["total_matches"]==512
    before=deepcopy(service.preset_grant);service.host.result["entries"].reverse();shared(service)
    assert before["snapshot_sha256"]==service.preset_grant["snapshot_sha256"] and before["entries"]==service.preset_grant["entries"]


@pytest.mark.parametrize("action",["refresh","revoke","reset","failed_refresh"])
def test_old_grants_are_revoked_and_do_not_rebind(service,action):
    args=shared(service);ref=service.preset_grant["entries"][0]["preset_ref"]
    if action=="refresh":shared(service)
    if action=="revoke":service.revoke_preset_catalog()
    if action=="reset":service.reset()
    if action=="failed_refresh":
        def fail(*args):raise OSError("private secret folder")
        service.host.start_preset_catalog=fail
        with pytest.raises(OSError):service.share_preset_catalog("custom_presets","local")
    with pytest.raises(Fault):service.inspect_preset(**args,preset_ref=ref)
    assert not service.host.inspected


def test_failed_scan_does_not_publish_partial_entries_or_private_errors(service,monkeypatch):
    service.share_preset_catalog("custom_presets","private")
    monkeypatch.setattr(service.host,"poll_preset_catalog",lambda:(_ for _ in ()).throw(OSError("private path")))
    service.poll_preset_catalog()
    assert service.preset_grant["status"]=="failed" and "entries" not in service.preset_grant
    assert "private path" not in canonical(service.connection())


def test_same_task_design_handoff_retains_only_read_discovery(service,monkeypatch):
    from test_task_handoff import install_host,grant
    install_host(service,monkeypatch);args=shared(service)
    original=deepcopy(service.preset_grant);closed=service.host.closed
    scope=grant(service)
    assert service.preset_grant==original and service.host.closed==closed
    assert not service.connection()["preset_catalog"]["use_supported"]
    with pytest.raises(Fault):service.search_presets(**args)
    result=service.search_presets(scope["scope_id"],original["library_id"])
    assert result["entry_count"]==2 and not service.owned


@pytest.mark.parametrize("mutation",["hash","version","extra","field_kind","distance","curve_dimension","curve_type"])
def test_native_document_boundary_rejects_inconsistent_or_unbounded_data(mutation):
    category="density_curve" if mutation.startswith("curve") else "spacing"
    grant=presets.snapshot(payload([row(category=category)]));grant.update(library_id="presets_test",kind="custom_presets")
    entry=grant["entries"][0];value=native(category)
    if mutation=="hash":value["preset_sha256"]="f"*64
    if mutation in ("version","extra","curve_dimension","curve_type"):
        doc=json.loads(value["document_json"])
        if mutation=="version":doc["version"]=True
        if mutation=="extra":doc["path"]="secret"
        if mutation=="curve_dimension":doc["values"]["samples"]=[0]
        if mutation=="curve_type":doc["values"]["samples"]=dict(a=0,b=1)
        value["document_json"]=canonical(doc);entry["document_sha256"]=value["document_sha256"]=hashlib.sha256(value["document_json"].encode()).hexdigest()
    if mutation=="field_kind":value["fields"][0]["kind"]="script"
    if mutation=="distance":value["fields"][0]["distance_metres"]=1
    with pytest.raises(Fault):presets.inspect(grant,entry,value)


@pytest.mark.parametrize("mutation",["entries","duplicate","name","category","field_count","domain","bytes","hash","unknown","counts"])
def test_metadata_admission_rejects_invalid_snapshots(mutation):
    value=payload([row()]);entry=value["entries"][0]
    if mutation=="entries":value["entries"]*=513;value.update(entry_count=513,scanned=513)
    if mutation=="duplicate":value["entries"]*=2;value.update(entry_count=2,scanned=2)
    if mutation=="name":entry["name"]="x"*81
    if mutation=="category":entry["category"]="unknown"
    if mutation=="field_count":entry["field_count"]=3
    if mutation=="domain":entry["domain"]="multiplier"
    if mutation=="bytes":entry["source_bytes"]=65537
    if mutation=="hash":entry["preset_sha256"]="bad"
    if mutation=="unknown":entry["path"]="private"
    if mutation=="counts":value["scanned"]=False
    with pytest.raises(Fault):presets.snapshot(value)
