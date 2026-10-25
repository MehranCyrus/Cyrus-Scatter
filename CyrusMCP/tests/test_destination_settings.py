"""Destination snapshots are passive evidence, never application or task freshness."""
from copy import deepcopy
import json
from types import SimpleNamespace
import pytest
from cyrus_mcp.contracts import Fault,require
from cyrus_mcp.destination_settings import snapshot,request_categories,targets
from cyrus_mcp.presets import CATEGORIES,COUNTS
from test_changes import changed
from test_operation_integrity import production_method


def captured(category,values):
    return json.dumps(dict(format="cyrus.settings-preset",version=3,category=category,name="Current destination",values=values))


def raw(categories=None):
    categories=categories or list(CATEGORIES);groups=[]
    for category in categories:
        if category in ("population","transforms"):
            values=[["field_"+str(i),1,False,float(i),True,"none",0] for i in range(COUNTS[category])]
            groups.append([category,values,captured(category,{field[0]:field[3] for field in values}),True,"",[]])
        elif category=="spacing":
            values=[["procSelfEnabled",3,False,True,True,"none",0],["procSelfMultiplier",1,False,1.,True,"none",0],
                    ["procSelfGap",1,True,.25,True,"none",0],["procSelfPlanar",3,False,False,True,"none",0],
                    ["procSelfOverride",3,False,False,True,"none",0],["procLayerSelfEnabled",3,False,False,True,"none",0],
                    ["procLayerSelfMultiplier",1,False,2.,True,"none",0],["procLayerSelfGap",1,True,.75,True,"none",0],
                    ["procLayerSelfPlanar",3,False,True,True,"none",0]]
            groups.append([category,values,captured(category,dict(enabled=False,multiplier=2.,gap=.75,planar=True)),True,"",[False,2.,.75,True]])
        else:
            values=[0.,1.]
            groups.append([category,values,captured(category,dict(domain="unit" if category=="density_curve" else "multiplier",samples=values,graph=[])),True,"",["",False,2.]])
    return ["layer_1","layer_1",False,1,1,True,100.,"0f",groups,False]


def test_snapshot_preserves_all_native_families_metres_and_distinct_spacing_scopes():
    value=snapshot(raw(),"controller_1","layer_1",list(CATEGORIES))
    assert value["metres_per_system_unit"]==.01 and value["pending_by_cached_flag"]
    spacing=value["categories"][2]
    assert spacing["effective_self_rule"]["gap_m"]==.75
    fields={row["name"]:row for row in spacing["fields"]}
    assert fields["procSelfGap"]["value"]==.25 and fields["procLayerSelfGap"]["value"]==.75
    assert not fields["procSelfOverride"]["value"]
    assert value["categories"][3]["stored_samples"]==[0,1] and len(value["settings_sha256"])==64


def test_empty_stored_curve_and_unavailable_scalar_track_are_not_fabricated_defaults():
    values=raw(["population","density_curve"])
    values[8][0][1][0][3:]=[None,False,"Float_Script",-1]
    values[8][0][2:5]=[None,False,"animated_or_unsupported_controller_or_nonfinite_value"]
    values[8][1][1:]=[[],None,False,"stored_curve_not_exportable_as_preset",["",False,0.]]
    result=snapshot(values,"controller_1","layer_1",["population","density_curve"])
    assert result["categories"][0]["fields"][0]["value"] is None and not result["categories"][0]["fields"][0]["available"]
    assert not result["categories"][0]["exportable_as_preset"] and result["categories"][1]["stored_samples"]==[]
    assert "preset_document" not in result["categories"][1]


@pytest.mark.parametrize("mutation",["layer","duplicate_field","count","curve_size","graph_size","document","units","bad_flag","sampled_unavailable","wrong_capture"])
def test_inconsistent_or_unbounded_native_data_rejected(mutation):
    value=raw()
    if mutation=="layer":value[0]="replaced"
    if mutation=="duplicate_field":value[8][0][1][1][0]=value[8][0][1][0][0]
    if mutation=="count":value[8][0][1].pop()
    if mutation=="curve_size":value[8][3][1]*=130
    if mutation=="graph_size":value[8][3][5][0]=" "*65537
    if mutation=="document":value[8][0][2]='{"format":"unsupported"}'
    if mutation=="units":value[6]=0
    if mutation=="bad_flag":value[5]=1
    if mutation=="sampled_unavailable":value[8][0][1][0][4]=False
    if mutation=="wrong_capture":
        data=json.loads(value[8][0][2]);data["values"]["field_0"]=99;value[8][0][2]=json.dumps(data)
    with pytest.raises(Fault):snapshot(value,"controller_1","layer_1",list(CATEGORIES))


def test_service_read_does_not_fingerprint_geometry_change_revision_or_issue_authority(changed,monkeypatch):
    observed=[]
    def read(controller_id,layer_id,categories):
        observed.append((controller_id,layer_id,categories))
        return snapshot(raw(categories),controller_id,layer_id,categories)
    monkeypatch.setattr(changed.host,"destination_settings",read,raising=False)
    before=deepcopy(changed.authored),deepcopy(changed.owned),changed.revision,deepcopy(changed.journal.records)
    monkeypatch.setattr(changed,"fresh",lambda:pytest.fail("Settings read must not invoke task freshness/geometry"))
    monkeypatch.setattr(changed.host,"fingerprint",lambda:pytest.fail("No geometry fingerprint"))
    result=changed.dispatch("scatter.get_settings",dict(scene_epoch=changed.epoch,controller_id="controller_1",layer_id="layer_1",categories=["spacing"]))
    assert result["settings"]["categories"][0]["category"]=="spacing" and len(observed)==1
    assert before==(changed.authored,changed.owned,changed.revision,changed.journal.records)
    assert not changed.approved and not changed.pending
    for args in (dict(scene_epoch="wrong",controller_id="controller_1",layer_id="layer_1",categories=["spacing"]),
                 dict(scene_epoch=changed.epoch,controller_id="unknown",layer_id="layer_1",categories=["spacing"]),
                 dict(scene_epoch=changed.epoch,controller_id="controller_1",layer_id="layer_1",categories=["spacing","spacing"])):
        with pytest.raises(Fault):changed.dispatch("scatter.get_settings",args)
    assert len(observed)==1


def test_actual_adapter_rejects_busy_missing_and_old_native_before_reader_execution():
    calls=[]
    runtime=SimpleNamespace(isValidNode=lambda _:True,maxVersion=lambda:[29000],cyrusPresetVersion=lambda:2,execute=lambda _:calls.append(True))
    adapter=SimpleNamespace(assert_main=lambda:None,busy=lambda:True,controllers={"controller_1":object()})
    method=production_method("destination_settings",dict(__package__="cyrus_mcp",require=require,Fault=Fault,rt=runtime))
    with pytest.raises(Fault) as exc:method(adapter,"controller_1","layer_1",["spacing"])
    assert exc.value.code=="HOST_BUSY"
    adapter.busy=lambda:False
    with pytest.raises(Fault) as exc:method(adapter,"missing","layer_1",["spacing"])
    assert exc.value.code=="STALE_CONTEXT"
    with pytest.raises(Fault) as exc:method(adapter,"controller_1","layer_1",["spacing"])
    assert exc.value.code=="UNSUPPORTED_CAPABILITY" and not calls


def test_target_discovery_preserves_exact_ids_and_rejects_duplicates():
    raw=[["layer_1","layer_1",False,"Untrusted\nlabel",True]]
    result=targets(raw,"controller_1")
    assert result["targets"][0]["layer_id"]=="layer_1" and result["targets"][0]["name"]=="Untrusted label"
    assert result["targets"][0]["name_sanitized"] and result["targets"][0]["name_clipped"]
    with pytest.raises(Fault) as exc:targets(raw*2,"controller_1")
    assert exc.value.code=="STALE_CONTEXT"


def test_service_lists_targets_without_freshness_geometry_or_settings_sampling(changed,monkeypatch):
    monkeypatch.setattr(changed,"fresh",lambda:pytest.fail("No task fingerprint"))
    monkeypatch.setattr(changed.host,"settings_targets",lambda cid:targets([["layer_1","layer_1",False,"Layer",False]],cid),raising=False)
    result=changed.dispatch("scatter.get_settings",dict(scene_epoch=changed.epoch,controller_id="controller_1"))
    assert result["settings_targets"]["targets"][0]["layer_id"]=="layer_1" and "settings" not in result
    with pytest.raises(Fault):changed.destination_settings(changed.epoch,"controller_1",categories=["spacing"])


@pytest.mark.parametrize("categories",[[],["spacing"]*2,["arbitrary"],"population",[[]]])
def test_category_selection_is_closed(categories):
    with pytest.raises(Fault):request_categories(categories)
