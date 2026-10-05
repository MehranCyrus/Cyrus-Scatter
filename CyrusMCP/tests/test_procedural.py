from types import SimpleNamespace as Obj
import pytest
from cyrus_mcp.procedural import read_procedural, require_legacy_mutation, STAT_FIELDS
from cyrus_mcp.contracts import Fault
from cyrus_mcp.settings import capability_manifest


def fixture_controller():
    leaf=Obj(layerID="set_b",paintSetName="Grass",procSamplingSalt=27,
             procSelfOverride=True,procBackground=4,procBackgroundIDs=["set_a"],
             procRadiusIDs=["c:3","clone:9"],procRadiusModes=[1,2],procRadiusValues=[50,1.2],
             procSourceSlots=["source-entry-a"],procSelfRule=lambda:[True,.5,10,True],
             procStatistics=lambda:[[30,10,2,1,4,5,6,3,2,40,10,120],[3,True],4,2,17])
    parent=Obj(layerID="layer_a",procPopulation=2,procAttemptFactor=8,procRounds=8,procRepair=True,
               procSiblingEnabled=True,procSiblingMultiplier=1,procSiblingGap=20,procSiblingPlanar=False)
    controller=Obj(groupPolicy=3,logicalLayers=lambda:[parent],layerSets=lambda _:[leaf],
                   procRuleScope=[2],procRuleA=["layer_a"],procRuleB=["layer_b"],procRuleEnabled=[True],
                   procRuleMultiplier=[.8],procRuleGap=[100],procRulePlanar=[True])
    return controller,leaf


def test_snapshot_exports_units_identities_and_cached_epoch_without_evaluation():
    controller,leaf=fixture_controller()
    result=read_procedural(controller,.001)
    set_state=result["layers_in_order"][0]["sets_in_order"][0]
    assert set_state["self_rule"]["gap_m"]==.01
    assert set_state["radius_overrides"][0]=={"instance_id":"c:3","mode":"world_radius","value":.05,"units":"metres"}
    assert set_state["radius_overrides"][1]["value"]==1.2
    assert set_state["last_published"]["epoch"]==17
    assert set_state["last_published"]["protected_conflicts"]==1
    assert result["pair_rules"][0]["gap_m"]==.1
    assert result["mutation_supported"] is False
    assert len(STAT_FIELDS)==12
    # No eager solve or creation API exists on the fixture.
    assert leaf.procRadiusValues==[50,1.2]


def test_unbuilt_and_legacy_snapshots_are_not_invented():
    controller,leaf=fixture_controller()
    leaf.procStatistics=lambda:[[],[],0,0,0]
    assert read_procedural(controller,1)["layers_in_order"][0]["sets_in_order"][0]["last_published"] is None
    controller.groupPolicy=2
    assert read_procedural(controller,1) is None


def test_container_recipe_is_read_only_and_preserves_deleted_references():
    controller,leaf=fixture_controller()
    node=Obj(handle=123,name="Trees")
    controller.containerGlobalNodes=[node]
    leaf.containerMode=2
    leaf.containerNodes=[node,None]
    def unexpected():
        pytest.fail("Inspection evaluated or enrolled scene sources")
    leaf.containerRefresh=unexpected
    controller.evaluateGroups=unexpected
    result=read_procedural(controller,1)
    pool=result["layers_in_order"][0]["sets_in_order"][0]["source_pool"]
    assert pool["mode"]=="layer_default"
    assert pool["own_rectangles"]==[{"handle":123,"name":"Trees"},None]
    assert result["global_source_containers"]==[{"handle":123,"name":"Trees"}]
    assert leaf.procSourceSlots==["source-entry-a"]


def test_old_script_does_not_claim_container_support():
    controller,_=fixture_controller()
    result=read_procedural(controller,1)
    assert result["global_source_containers"] is None
    assert result["layers_in_order"][0]["sets_in_order"][0]["source_pool"] is None


def test_old_apply_contract_cannot_downgrade_new_policy():
    for controller in (None,Obj(groupPolicy=1),Obj(groupPolicy=2)):
        require_legacy_mutation(controller)
    for policy in (3,4):
        with pytest.raises(Fault,match="cannot overwrite"):
            require_legacy_mutation(Obj(groupPolicy=policy))
    caps=capability_manifest()
    assert caps["plan_versions"]==["1.0","2.0"]
    assert "procedural_policy_3_read_only" in caps["supported"]
    assert "procedural_policy_3_mutation" in caps["unavailable"]
