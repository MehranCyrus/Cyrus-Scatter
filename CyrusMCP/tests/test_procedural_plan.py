from copy import deepcopy
import random
import pytest
from cyrus_mcp.contracts import Fault
from cyrus_mcp.procedural_plan import allocate,compile_draft


def draft():
    rule=dict(enabled=True,radius_factor=1,gap_m=.1,metric="xyz")
    sets=[dict(set_id=f"set_{i}",name=f"Set {i}",weight=1,enabled=True,sampling_salt=i,
               sources=[dict(source_id="tree",weight=1,radius_m=.5,radius_follows_scale=True)],
               self_rule="inherit",coverage=dict(mode="existing_brush",coverage_id="brush_a") if i==0 else dict(mode="whole_surface"),
               background=dict(mode="off",earlier_set_ids=[])) for i in range(3)]
    plan=dict(schema_version="3.0-draft1",name="Test garden",receiver_id="site",max_candidates=20000,pair_rules=[],
              layers=[dict(layer_id="layer_a",name="Trees",seed=7,
                population=dict(mode="accepted_target",count=10,attempt_factor=4,rounds=3,refill_after_cleanup=True,underfill="allow"),
                defaults=dict(self_rule=rule,between_sets=deepcopy(rule),scale=[.8,1.2],yaw_degrees=[0,360],
                              cleanup=dict(enabled=False,radius_m=1,minimum_neighbors=2,minimum_island=4,metric="xy")),sets=sets)])
    enrollment=dict(receiver_id="site",topology_id="topo_1",sources=[dict(source_id="tree",kind="mesh")],
                    coverages=[dict(coverage_id="brush_a",receiver_id="site",topology_id="topo_1")])
    return plan,enrollment


def test_draft_freezes_normalized_values_and_bounds_work():
    plan,enrolled=draft();before=deepcopy(plan)
    compiled=compile_draft(plan,enrolled)
    assert plan==before and [v["quota"] for v in compiled["populations"]]==[4,3,3]
    assert compiled["admitted_candidates"]==40 and not compiled["mutation_supported"]
    plan["layers"][0]["defaults"]["self_rule"]["gap_m"]=100
    assert compiled["populations"][0]["self_rule"]["gap_m"]==.1


def test_quota_allocation_is_stable_and_conserves_enabled_population():
    rng=random.Random(7)
    for _ in range(1000):
        sets=[dict(weight=rng.random(),enabled=bool(rng.randrange(2))) for i in range(10)]
        count=rng.randrange(20001);quotas=allocate(count,sets)
        assert sum(quotas)==(count if any(s["enabled"] for s in sets) else 0)
        assert all(q==0 for q,s in zip(quotas,sets) if not s["enabled"])
        assert quotas==allocate(count,sets)


def test_background_order_and_pair_override_are_independent():
    plan,enrolled=draft();sets=plan["layers"][0]["sets"]
    sets[1]["background"]=dict(mode="both",earlier_set_ids=["set_0"])
    compile_draft(plan,enrolled)
    plan["pair_rules"]=[dict(scope="paint_sets",a="set_1",b="set_0",distance=dict(enabled=False,radius_factor=1,gap_m=0,metric="xy"))]
    with pytest.raises(Fault,match="nonzero"):compile_draft(plan,enrolled)
    plan["pair_rules"]=[]
    sets[1]["background"]["earlier_set_ids"]=["set_2"]
    with pytest.raises(Fault,match="earlier siblings"):compile_draft(plan,enrolled)


@pytest.mark.parametrize("case",["foreign_source","stale_brush","duplicate_pair","work_budget","empty_target","unknown_field","wrong_scope","duplicate_identity","nan","bool_count"])
def test_invalid_or_unsupported_draft_fails_closed(case):
    p,e=draft();layer=p["layers"][0];sets=layer["sets"]
    if case=="foreign_source":sets[0]["sources"][0]["source_id"]="not_enrolled"
    if case=="stale_brush":e["topology_id"]="changed"
    if case=="duplicate_pair":
        rule=dict(scope="paint_sets",a="set_0",b="set_1",distance=deepcopy(layer["defaults"]["self_rule"]))
        p["pair_rules"]=[rule,dict(rule,a="set_1",b="set_0")]
    if case=="work_budget":p["max_candidates"]=39
    if case=="empty_target":e["sources"][0]["kind"]="empty"
    if case=="unknown_field":layer["execute_script"]="unsafe"
    if case=="wrong_scope":p["pair_rules"]=[dict(scope="layers",a="set_0",b="set_1",distance=layer["defaults"]["self_rule"])]
    if case=="duplicate_identity":sets[0]["set_id"]="layer_a"
    if case=="nan":sets[0]["weight"]=float("nan")
    if case=="bool_count":layer["population"]["count"]=True
    with pytest.raises(Fault):compile_draft(p,e)
