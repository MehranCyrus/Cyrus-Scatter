from copy import deepcopy
import pytest
from pydantic import ValidationError
from cyrus_mcp.contracts import Fault, validate_shape, digest
from cyrus_mcp.settings import normalize_v2, normalize_settings, LAYER_SETTINGS, SOURCE_SETTINGS, DISPLAY_SETTINGS, capability_manifest
from cyrus_mcp.models import DesignPlanV2
from cyrus_mcp.geometry import outset, contains
from cyrus_mcp.records import execution_record, correction_record
from test_contracts import plan
from test_service import service


def v2(context="context_x"):
    p=plan(context);p["schema_version"]="2.0"
    return p


def test_all_registry_defaults_are_strict_and_round_trip():
    p=v2();validate_shape(p)
    canonical=normalize_v2(p)
    assert normalize_v2(canonical)==canonical
    assert DesignPlanV2.model_validate(canonical).model_dump(exclude_none=True)=={**canonical,"clearance_m":canonical.get("clearance_m",0)}
    for registry in (LAYER_SETTINGS,SOURCE_SETTINGS,DISPLAY_SETTINGS):
        for key,(kind,_,bounds,_) in registry.items():
            value=True if kind=="bool" else bounds[-1] if kind=="enum" else list(bounds) if kind=="range" else bounds[1]
            assert normalize_settings({key:value},registry)[key]==value
            bad=1 if kind=="bool" else "unrecognized" if kind=="enum" else [bounds[1],bounds[0]] if kind=="range" else bounds[1]+1
            with pytest.raises(Fault):normalize_settings({key:bad},registry)


@pytest.mark.parametrize("mutation",[
    lambda p:p.update(execute="delete objects"),
    lambda p:p["layers"][0].update(settings={"relax_enabled":True}),
    lambda p:p["layers"][0].update(settings={"collision_radius_m":float("nan")}),
    lambda p:p["layers"][0].update(settings={"enabled":1}),
    lambda p:p["layers"][0]["sources"][0].update(settings={"scale":0}),
    lambda p:p.update(pair_rules=[{"a":0,"b":0,"gap_m":1,"footprints":False,"planar":True}]),
    lambda p:p["layers"][0].update(exclude_region_ids=["not/a/path"]),
])
def test_v2_rejects_unknown_unsafe_or_ambiguous_settings(mutation):
    p=v2();mutation(p)
    with pytest.raises(Fault):validate_shape(p)


def test_v1_cannot_silently_adopt_v2_settings():
    p=plan();p["layers"][0]["settings"]={"collision_enabled":True}
    with pytest.raises(Fault):validate_shape(p)


def test_outset_contains_circular_boundary_and_corner_margin():
    square=[[-1,-1],[1,-1],[1,1],[-1,1]]
    expanded=outset(square,.5)
    assert contains(expanded,[1.5,1.5])
    assert not contains(expanded,[1.501,0])
    with pytest.raises(Fault):outset(square,-1)


def test_v2_compiles_exclusions_and_normalizes_before_approval(service):
    service.scope["excluded"]=[{"region_id":"region_hole","polygon_m":[[-1,-1],[1,-1],[1,1],[-1,1]]}]
    context=service.context(service.scope["scope_id"])
    p=v2(context["context_id"])
    p["layers"][0]["settings"]={"collision_enabled":True,"collision_radius_m":.4}
    validated=service.validate(p);stored=service.validations[validated["validation_id"]]
    assert validated["digest"]==digest(normalize_v2(p))
    assert len(stored["compiled"][0]["exclusions_m"])==1
    assert validated["derived_masks"]==2
    p["layers"][0]["exclude_region_ids"]=["region_missing"]
    with pytest.raises(Fault,match="not enrolled"):service.validate(p)


def test_records_use_actual_transforms_and_never_infer_training_consent():
    rows=[{"transform":[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]],"source_index":1}]
    key=digest([[r["transform"],r["source_index"]] for r in rows])
    receipt={"transform_digest":key,"emitted":1}
    layout={"transform_digest":key,"instances":rows}
    record=execution_record({},v2(),receipt,layout)
    assert record["provenance"]["training_eligible"] is False
    assert record["lineage"]["instance_correspondence"] is None
    bad=deepcopy(layout);bad["instances"][0]["source_index"]=2
    with pytest.raises(Fault,match="transforms differ"):execution_record({},v2(),receipt,bad)
    correction=correction_record("generation_a","generation_b",[{"kind":"parameter_change","before_id":None,"after_id":None}],"consent_x")
    assert correction["training_eligible"] is False
    with pytest.raises(Fault,match="No inferred"):correction_record("generation_a","generation_b",[{"kind":"parameter_change","before_id":"a","after_id":"b"}])


def test_capabilities_do_not_advertise_brush_or_training_mutations():
    caps=capability_manifest()
    assert "brush_history_mutation" in caps["unavailable"]
    assert "training_or_ml_inference" in caps["unavailable"]
    assert caps["layer_settings"]["collision_radius_m"]["units"]=="metres"
