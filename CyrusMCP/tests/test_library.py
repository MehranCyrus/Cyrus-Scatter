"""Catalog grants must remain cheap read-only evidence, never import authority."""
from copy import deepcopy

import pytest

from cyrus_mcp.contracts import Fault, canonical
from cyrus_mcp import library
from cyrus_mcp.service import Journal, Service
from test_scene_context import SceneHost


def entry(index=0, **changes):
    return dict(entry_id="model_"+str(index),name="Flower "+str(index),category="Plants",
                scene_sha256="a"*64,scene_bytes=2048,thumbnail_sha256="b"*64,thumbnail_bytes=512,**changes)


def payload(entries=None):
    return dict(entries=entries or [entry()],host_year=2027,load_duration_ms=10)


@pytest.fixture
def service(tmp_path):
    host=SceneHost()
    host.installed_model_catalog=lambda:payload()
    value=Service(host,Journal(tmp_path/"ops.json"))
    value.inspect_scene(["native_a"])
    return value


def args(service):
    return dict(scope_id=service.scope["scope_id"],library_id=service.library_grant["library_id"])


def test_explicit_local_grant_and_revoke_do_not_change_task_scene_or_authority(service,monkeypatch):
    before=deepcopy(service.task),deepcopy(service.scope),service.last_fingerprint,service.revision,service.last_undo
    with pytest.raises(Fault) as exc:
        service.dispatch("library.search",dict(scope_id=service.scope["scope_id"],library_id="invented"))
    assert exc.value.code=="APPROVAL_REQUIRED"
    for name in ("share_installed_catalog","revoke_installed_catalog","library.import","library.share"):
        with pytest.raises(Fault) as exc:service.dispatch(name,{})
        assert exc.value.code=="UNSUPPORTED_CAPABILITY"
    service.share_installed_catalog()
    assert service.connection()["installed_catalog"]["shared"]
    assert service.context(service.scope["scope_id"])["installed_catalog"]["entry_count"]==1
    # A remote catalog read may neither reload files nor evaluate/fingerprint geometry.
    monkeypatch.setattr(service.host,"installed_model_catalog",lambda:pytest.fail("remote filesystem access"))
    monkeypatch.setattr(service.host,"fingerprint",lambda:pytest.fail("remote geometry evaluation"))
    page=service.dispatch("library.search",args(service))
    info=service.dispatch("library.inspect_entry",dict(**args(service),asset_ref=page["entries"][0]["asset_ref"]))
    assert info["evidence"]["dimensions_m"] is None and info["evidence"]["ready_for_import"] is False
    assert not info["use_supported"] and service.host.generated==0 and not service.journal.records
    assert before==(service.task,service.scope,service.last_fingerprint,service.revision,service.last_undo)
    service.revoke_installed_catalog()
    assert service.library_grant is None and not service.connection()["installed_catalog"]["shared"]
    with pytest.raises(Fault):service.search_catalog(service.scope["scope_id"],page["library_id"])


def test_refresh_failure_revokes_old_grant_and_reset_revokes_all_refs(service):
    service.share_installed_catalog();old=args(service)
    service.share_installed_catalog()
    assert old["library_id"]!=service.library_grant["library_id"]
    with pytest.raises(Fault) as exc:service.search_catalog(**old)
    assert exc.value.code=="STALE_CONTEXT"
    def fail():raise Fault("CATALOG_UNAVAILABLE","missing")
    service.host.installed_model_catalog=fail
    with pytest.raises(Fault):service.share_installed_catalog()
    assert service.library_grant is None
    service.host.installed_model_catalog=lambda:payload()
    service.share_installed_catalog();old=args(service)
    service.reset()
    assert service.library_grant is None
    with pytest.raises(Fault) as exc:service.search_catalog(**old)
    assert exc.value.code=="UNKNOWN_REFERENCE"


def test_stable_content_refs_are_independent_of_load_time_input_order_and_grant_id():
    first=library.snapshot(payload([entry(1),entry(0)]))
    second=library.snapshot(dict(payload([entry(0),entry(1)]),load_duration_ms=200))
    assert first["snapshot_sha256"]==second["snapshot_sha256"]
    assert first["entries"]==second["entries"]
    changed=payload([entry(0),entry(1)]);changed["entries"][1]["scene_sha256"]="c"*64
    assert library.snapshot(changed)["entries"][0]["asset_ref"]!=first["entries"][0]["asset_ref"]


def test_paging_search_categories_and_no_returned_mutable_aliases():
    values=[entry(i) for i in range(104)]
    for i,row in enumerate(values):row["category"]="Category "+str(i)
    grant=library.snapshot(payload(values));grant["library_id"]="library_test"
    all_rows=[];offset=0
    while offset is not None:
        page=library.search(grant,offset=offset)
        all_rows+=page["entries"];offset=page["next_offset"]
        assert len(page["entries"])<=12 and len(canonical(page).encode())<=32768
        assert page["categories_omitted"]==92
    assert len({r["asset_ref"] for r in all_rows})==104
    assert library.search(grant,query="fLOWer 51")["total_matches"]==1
    assert library.search(grant,category="Category 51")["total_matches"]==1
    assert library.search(grant,query="absent")["next_offset"] is None
    all_rows[0]["name"]="modified"
    assert grant["entries"][0]["name"]!="modified"
    with pytest.raises(Fault):library.inspect(grant,"asset_outside")


@pytest.mark.parametrize("changes",[{"offset":True},{"offset":-1},{"offset":105},{"limit":0},{"limit":13},{"query":"a"*81},{"category":"x\n"}])
def test_remote_queries_are_bounded(service,changes):
    service.share_installed_catalog()
    with pytest.raises(Fault):service.dispatch("library.search",dict(**args(service),**changes))


@pytest.mark.parametrize("change",["count","duplicate","hash","bytes","year","path","control"])
def test_bad_host_metadata_is_rejected_before_grant(service,change):
    value=payload()
    if change=="count":value["entries"]=[entry(i) for i in range(105)]
    if change=="duplicate":value["entries"]=[entry(),entry()]
    if change=="hash":value["entries"][0]["scene_sha256"]="Z"*64
    if change=="bytes":value["entries"][0]["scene_bytes"]=2*1024**3+1
    if change=="year":value["host_year"]=2026
    if change=="path":value["entries"][0]["path"]="C:/private/model.max"
    if change=="control":value["entries"][0]["name"]="bad\nlabel"
    service.host.installed_model_catalog=lambda:value
    with pytest.raises(Fault):service.share_installed_catalog()
    assert service.library_grant is None


def test_catalog_reads_consume_normal_scope_budget(service):
    service.share_installed_catalog()
    for _ in range(24):service.dispatch("library.search",args(service))
    with pytest.raises(Fault) as exc:service.dispatch("library.search",args(service))
    assert exc.value.code=="BUDGET_EXCEEDED"
    service.revoke_installed_catalog();service.share_installed_catalog()
    assert service.calls==24
