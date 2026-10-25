from copy import deepcopy
from types import SimpleNamespace

import pytest

from cyrus_mcp.contracts import Fault,require,digest
from cyrus_mcp.source_metadata import decode
from test_scene_context import scene
from test_operation_integrity import fingerprint_fixture


def raw():return [20000,12000,[-3,0,0],[4,5,6],[20,30,0],[27,35,6],7.,10.,"a"*64,"b"*64,"cyrus.source-measurement/1.0"]


def test_native_bounds_are_physical_pivot_metrics_with_explicit_provenance_limits():
    value=decode(raw())
    assert value["triangles"]==20000 and value["vertices"]==12000
    assert value["source_geometry"]["local_aabb_m"]["size"]==[7,5,6]
    assert value["source_geometry"]["height_m"]==6 and value["source_geometry"]["radius_xy_from_pivot_m"]==7
    assert value["geometry_world_sha256"]!=value["source_geometry"]["source_geometry_sha256"]
    assert "Asset unit provenance" in value["source_geometry"]["unchecked"]


@pytest.mark.parametrize("change",["size","schema","faces","vertices","bounds","finite","radius","hash"])
def test_native_metadata_is_independently_validated(change):
    value=raw()
    if change=="size":value.append([])
    if change=="schema":value[-1]="future"
    if change=="faces":value[0]=2000001
    if change=="vertices":value[1]=1000001
    if change=="bounds":value[2]=[9,9,9]
    if change=="finite":value[4][0]=float("nan")
    if change=="radius":value[7]=1
    if change=="hash":value[8]="wrong"
    with pytest.raises(Fault):decode(value)


def test_source_purpose_requires_explicit_shared_objects_and_preserves_task(scene,monkeypatch):
    calls=[]
    monkeypatch.setattr(scene.host,"measure_sources",lambda ids:(calls.append(ids) or {"measurements":[decode(raw())]}),raising=False)
    before=deepcopy(scene.task)
    result=scene.dispatch("scene.measure_objects",dict(scope_id=scene.scope["scope_id"],object_ids=["object_a"],purpose="source"))
    assert calls==[["object_a"]] and result["measurements"][0]["triangles"]==20000
    assert scene.task==before and scene.host.generated==0
    with pytest.raises(Fault):scene.measure_scene(scene.scope["scope_id"],["outside"],"source")
    with pytest.raises(Fault):scene.measure_scene(scene.scope["scope_id"],["object_a"],"guess")
    assert calls==[["object_a"]]


def test_fingerprint_native_path_never_copies_source_mesh_and_detects_changes():
    fingerprint,host,runtime=fingerprint_fixture(False)
    host.has_native_source=lambda _:True
    runtime.getPolygonCount=lambda _:(20000,12000)
    state={"sha":"a"*64}
    host.source_descriptor=lambda _:dict(source_geometry={"source_geometry_sha256":state["sha"]},geometry_fingerprint_schema="native-1")
    host.mesh=lambda *args:pytest.fail("Native sources must not marshal geometry")
    before=fingerprint(host)
    runtime.sliderTime=160
    assert fingerprint(host)==before
    state["sha"]="b"*64
    assert fingerprint(host)!=before
    runtime.getPolygonCount=lambda _:(2000001,12000)
    host.source_descriptor=lambda _:pytest.fail("Reject aggregate admission before native scans")
    with pytest.raises(Fault) as exc:fingerprint(host)
    assert exc.value.code=="BUDGET_EXCEEDED"
    runtime.isValidNode=lambda _:False
    with pytest.raises(Fault) as exc:fingerprint(host)
    assert exc.value.code=="STALE_CONTEXT"
