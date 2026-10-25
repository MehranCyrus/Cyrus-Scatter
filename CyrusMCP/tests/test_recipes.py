"""Local recipe-root grants, atomic metadata snapshots and read-only client use."""
from copy import deepcopy

import pytest

from cyrus_mcp import recipes
from cyrus_mcp.contracts import Fault, canonical
from cyrus_mcp.service import Service,Journal
from test_scene_context import SceneHost
from test_task_handoff import install_host,grant


def entry(index=0):
    return dict(entry_key=f"{index:064x}",name="Meadow "+str(index),recipe_id="meadow:"+str(index),category="Garden",tags=["flowers"],
                description="Grass and flowers",layer_count=2,paint_documents=1,role_count=2,layer_names=["Grass","Flowers"],role_names=["Receiver","Source"],
                recipe_sha256="a"*64,thumbnail_declared=True,metadata_warning=False,revision=1,requirements_summary="Packaged Paint needs compatible terrain.",
                package_status="Packaged; checked on Load",omissions=[])


def payload(entries=None):
    entries=[entry()] if entries is None else entries
    return dict(state="complete",scanned=len(entries),entry_count=len(entries),invalid=0,limited=False,has_error=False,entries=entries)


class Host(SceneHost):
    def __init__(self):
        super().__init__();self.reader=None;self.polls=0;self.closed=[];self.value=payload()
    def start_recipe_catalog(self,kind,root):
        assert self.reader is None
        self.reader=(kind,root)
    def stop_recipe_catalog(self):
        if self.reader is not None:self.closed.append(self.reader)
        self.reader=None
    def poll_recipe_catalog(self):
        assert self.reader is not None
        self.polls+=1
        if isinstance(self.value,Exception):raise self.value
        return deepcopy(self.value)


@pytest.fixture
def scene(tmp_path):
    service=Service(Host(),Journal(tmp_path/"ops.json"));service.inspect_scene(["a","b"])
    return service


def args(scene):return dict(scope_id=scene.scope["scope_id"],library_id=scene.recipe_grant["library_id"])


def start(scene):return scene.share_recipe_catalog("custom_recipes","F:/owned/recipes")


def test_local_grant_pending_then_atomic_cache_and_no_scene_or_authority_change(scene,monkeypatch):
    before=deepcopy(scene.scope),deepcopy(scene.task),scene.last_fingerprint,scene.revision,scene.last_undo
    for method in ("share_recipe_catalog","poll_recipe_catalog","revoke_recipe_catalog","recipes.import","recipes.start"):
        with pytest.raises(Fault) as exc:scene.dispatch(method,{})
        assert exc.value.code=="UNSUPPORTED_CAPABILITY"
    with pytest.raises(Fault) as exc:scene.search_recipes(scene.scope["scope_id"],"not_shared")
    assert exc.value.code=="APPROVAL_REQUIRED"
    start(scene)
    assert scene.connection()["recipe_catalog"]["status"]=="scanning"
    with pytest.raises(Fault) as exc:scene.dispatch("recipes.search",args(scene))
    assert exc.value.code=="CATALOG_SCANNING" and scene.host.polls==0
    assert "entries" not in scene.recipe_grant and "snapshot_sha256" not in scene.recipe_grant
    scene.poll_recipe_catalog()
    assert scene.recipe_grant["status"]=="ready" and scene.host.reader is None and scene.host.polls==1
    monkeypatch.setattr(scene.host,"poll_recipe_catalog",lambda:pytest.fail("remote reload"))
    monkeypatch.setattr(scene.host,"fingerprint",lambda:pytest.fail("geometry evaluation"))
    page=scene.dispatch("recipes.search",args(scene))
    detail=scene.dispatch("recipes.inspect_entry",dict(**args(scene),recipe_ref=page["entries"][0]["recipe_ref"]))
    assert not detail["evidence"]["ready_for_application"] and not detail["use_supported"]
    assert detail["entry"]["package_status"]=="Packaged; checked on Load" and "entry_key" not in detail["entry"]
    assert before==(scene.scope,scene.task,scene.last_fingerprint,scene.revision,scene.last_undo)
    assert scene.host.generated==0 and not scene.journal.records


@pytest.mark.parametrize("value",[RuntimeError("C:/private/secret.json"),dict(payload(),has_error=True),dict(payload(),state="cancelled")])
def test_failure_discards_entries_and_hides_native_paths(scene,value):
    start(scene);scene.host.value=value;scene.poll_recipe_catalog()
    assert scene.recipe_grant["status"]=="failed" and scene.host.reader is None
    public=canonical(scene.connection()["recipe_catalog"])
    assert "secret" not in public and "entries" not in scene.recipe_grant and "snapshot_sha256" not in scene.recipe_grant
    with pytest.raises(Fault) as exc:scene.search_recipes(**args(scene))
    assert exc.value.code=="CATALOG_UNAVAILABLE"


def test_missing_folder_failure_is_distinct_from_empty_valid_folder(scene):
    start(scene);scene.host.value=dict(payload([]),has_error=True);scene.poll_recipe_catalog()
    assert scene.recipe_grant["status"]=="failed"
    scene.host.value=payload([]);start(scene);scene.poll_recipe_catalog()
    assert scene.recipe_grant["status"]=="ready" and scene.search_recipes(**args(scene))["entries"]==[]


@pytest.mark.parametrize("change",["count","hash","extra_path","duplicates","layers","flags","omissions","overflow"])
def test_bad_native_metadata_cannot_publish_a_partial_grant(scene,change):
    value=payload()
    if change=="count":value["entry_count"]=2
    if change=="hash":value["entries"][0]["recipe_sha256"]="Z"*64
    if change=="extra_path":value["entries"][0]["path"]="F:/private"
    if change=="duplicates":value=payload([entry(),entry()])
    if change=="layers":value["entries"][0]["layer_names"]=[]
    if change=="flags":value["limited"]="false"
    if change=="omissions":value["entries"][0]["omissions"]=["unknown"]
    if change=="overflow":value=payload([entry(i) for i in range(257)])
    start(scene);scene.host.value=value;scene.poll_recipe_catalog()
    assert scene.recipe_grant["status"]=="failed" and "entries" not in scene.recipe_grant and scene.host.reader is None


@pytest.mark.parametrize("state",["scanning","ready"])
def test_same_task_design_handoff_retains_grant_but_new_scope_is_required(scene,monkeypatch,state):
    install_host(scene,monkeypatch);start(scene)
    if state=="ready":scene.poll_recipe_catalog()
    previous=deepcopy(scene.recipe_grant);old=args(scene);reader=scene.host.reader;task_id=scene.task["task_id"]
    grant(scene)
    assert scene.recipe_grant==previous and scene.host.reader==reader and scene.task["task_id"]==task_id
    with pytest.raises(Fault) as exc:scene.search_recipes(**old)
    assert exc.value.code=="UNKNOWN_REFERENCE"
    if state=="scanning":scene.poll_recipe_catalog()
    assert scene.search_recipes(**args(scene))["total_matches"]==1
    scene.update_scene_brief("Keep these flowers")
    assert scene.recipe_grant["library_id"]==previous["library_id"]


def test_reset_revoke_refresh_expiry_and_budget_are_independent(scene):
    start(scene);old=args(scene);scene.poll_recipe_catalog();start(scene)
    assert scene.host.reader is not None
    with pytest.raises(Fault) as exc:scene.search_recipes(**old)
    assert exc.value.code=="STALE_CONTEXT"
    scene.recipe_deadline=0;scene.poll_recipe_catalog()
    assert scene.recipe_grant["status"]=="failed" and scene.host.reader is None
    start(scene);scene.poll_recipe_catalog()
    for _ in range(24):scene.dispatch("recipes.search",args(scene))
    with pytest.raises(Fault) as exc:scene.dispatch("recipes.search",args(scene))
    assert exc.value.code=="BUDGET_EXCEEDED"
    old=args(scene);scene.revoke_recipe_catalog();start(scene)
    assert scene.calls==24
    scene.reset()
    assert scene.recipe_grant is None and scene.host.reader is None
    with pytest.raises(Fault) as exc:scene.search_recipes(**old)
    assert exc.value.code=="UNKNOWN_REFERENCE"


def test_snapshot_refs_search_paging_omissions_and_aliases():
    raw=payload([entry(i) for i in range(256)]);raw.update(scanned=256,limited=True)
    value=recipes.snapshot(raw);value.update(library_id="recipes_test",kind="custom_recipes")
    reverse=payload(list(reversed(raw["entries"])));reverse["limited"]=True
    assert recipes.snapshot(reverse)["snapshot_sha256"]==value["snapshot_sha256"]
    all_rows=[];offset=0
    while offset is not None:
        page=recipes.search(value,offset=offset);all_rows+=page["entries"];offset=page["next_offset"]
        assert len(canonical(page).encode())<=32768 and page["limited"]
    assert len({row["recipe_ref"] for row in all_rows})==256
    assert recipes.search(value,query="meadow:51",category="Garden")["total_matches"]==1
    assert recipes.search(value,query="flowers")["total_matches"]==256
    assert recipes.search(value,query="absent")["next_offset"] is None
    detail=recipes.inspect(value,all_rows[0]["recipe_ref"]);detail["entry"]["tags"].clear()
    assert value["entries"][0]["tags"]
    with pytest.raises(Fault):recipes.inspect(value,"recipe_outside")


def test_maximum_unicode_detail_is_bounded_and_controls_are_explicitly_sanitized():
    row=entry();row.update(name="花"*160,recipe_id="id:"+"a"*157,category="花"*96,description="花"*256,
        requirements_summary="花"*640,tags=["花"*64]*16,layer_count=10,layer_names=["花"*80]*10,role_count=8,role_names=["花"*80]*8)
    value=recipes.snapshot(payload([row]));value.update(library_id="recipes_test",kind="custom_recipes")
    assert len(canonical(recipes.inspect(value,value["entries"][0]["recipe_ref"])).encode())<=32768
    row=entry();row["name"]="Read\nthis\ud800";row["omissions"]=["description"]
    cleaned=recipes.snapshot(payload([row]))["entries"][0]
    assert cleaned["name"]=="Read this " and cleaned["omissions"]==["description","sanitized_text"]


@pytest.mark.parametrize("changes",[{"offset":True},{"offset":257},{"offset":-1},{"limit":13},{"limit":0},{"query":"x"*81},{"query":"x\n"},{"category":"x"*97}])
def test_remote_recipe_query_bounds(scene,changes):
    start(scene);scene.poll_recipe_catalog()
    with pytest.raises(Fault):scene.dispatch("recipes.search",dict(**args(scene),**changes))
