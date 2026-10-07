from types import SimpleNamespace as Obj
import pytest
from cyrus_mcp.procedural import read_procedural, require_unified_mutation, STAT_FIELDS
from cyrus_mcp.contracts import Fault
from cyrus_mcp.settings import capability_manifest


def fixture_controller():
    leaf=Obj(layerID="set_b",paintSetName="Grass",procSamplingSalt=27,
             procSelfOverride=True,procBackground=4,procBackgroundIDs=["set_a"],
             procRadiusIDs=["c:3","clone:9"],procRadiusModes=[1,2],procRadiusValues=[50,1.2],
             procSourceSlots=["source-entry-a"],procSelfRule=lambda:[True,.5,10,True],
             procStatistics=lambda:[[30,10,2,1,4,5,6,3,2,40,10,120],[3,True],4,2,17])
    parent=Obj(layerID="layer_a",procPopulation=2,procAttemptFactor=8,procRounds=8,procRepair=True,
               procLayerSelfEnabled=False,procLayerSelfMultiplier=1,procLayerSelfGap=0,procLayerSelfPlanar=False,procSiblingEnabled=True,procSiblingMultiplier=1,procSiblingGap=20,procSiblingPlanar=False)
    controller=Obj(calculationModel=lambda:"CyrusUnified1",logicalLayers=lambda:[parent],layerSets=lambda _:[leaf],
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
    controller.calculationModel=lambda:"retired"
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


def test_container_helper_metadata_is_bounded_cached_presentation_only():
    controller,leaf=fixture_controller()
    class Helper:
        handle=123;name='Palette';containerID='container-uuid'
        contextRootID='root-uuid';contextSetID='set_b'
        cachedLabel='x'*2048;cachedActiveCount=2;cachedSavedCount=3
        movementStatus='y'*2048
        @property
        def transform(self):
            pytest.fail('Passive container inspection read transforms')
        def movePalette(self,*_):
            pytest.fail('Passive container inspection moved sources')
    helper=Helper()
    controller.containerGlobalNodes=[helper]
    leaf.containerMode=4;leaf.containerNodes=[helper]
    leaf.containerRefresh=lambda:pytest.fail('Passive container inspection reconciled sources')
    row=read_procedural(controller,1)['global_source_containers'][0]
    assert row['cached_helper']['container_id']=='container-uuid'
    assert row['cached_helper']['context_set_id']=='set_b'
    assert len(row['cached_helper']['label'])==1024
    assert len(row['cached_helper']['movement_status'])==1024
    assert (row['cached_helper']['active'],row['cached_helper']['saved'])==(2,3)


def test_cached_membership_preserves_parked_and_missing_rows_without_reconciliation():
    controller,leaf=fixture_controller()
    a,b=Obj(handle=1),Obj(handle=2)
    leaf.containerMode=4;leaf.containerNodes=[];leaf.sources=[a,b,None,None]
    leaf.containerTrackedSources=[a,b,None,None];leaf.containerActive=[True,False,False,False]
    leaf.sourcePoint=[False,False,True,False];leaf.sourceEmpty=[False,False,True,False]
    leaf.procSourceSlots=["a","b","placeholder:3","old_deleted"]
    leaf.containerMembershipBuilds=5;leaf.containerScan=False;leaf.containerPending=[];leaf.dirty=True
    leaf.containerRefresh=lambda:pytest.fail("Passive membership reader reconciled sources")
    pool=read_procedural(controller,1)["layers_in_order"][0]["sets_in_order"][0]["source_pool"]["cached_membership"]
    assert [r["cached_status"] for r in pool["rows"]]==["active","parked","placeholder","missing"]
    assert pool["revision"]==5 and pool["pending_by_cached_flags"]
    leaf.sources[0]=Obj(handle=99)
    stale=read_procedural(controller,1)["layers_in_order"][0]["sets_in_order"][0]["source_pool"]["cached_membership"]
    assert not stale["aligned_with_registered_order"]
    assert stale["rows"][0]["cached_status"]=="unavailable_until_reconciliation" and stale["rows"][0]["source_entry_id"] is None


def test_apply_requires_the_sole_explicit_model_and_rejects_retired_schemas():
    require_unified_mutation(None)
    require_unified_mutation(Obj(calculationModel=lambda:"CyrusUnified1"))
    for controller in (Obj(groupPolicy=1),Obj(groupPolicy=2),Obj(calculationModel=lambda:"other")):
        with pytest.raises(Fault,match="Only a matching"):
            require_unified_mutation(controller)
    caps=capability_manifest()
    assert caps["plan_versions"]==["0.73"]
    assert "unified_recipe_read_only" in caps["supported"]
    assert "full_procedural_recipe_mutation" in caps["unavailable"]
