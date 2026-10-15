"""Guard Save Everything against future unclassified persistent parameters."""
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]

def test_every_saved_controller_parameter_has_an_explicit_recipe_disposition():
    source=(ROOT/'AminScatter/tools/ui/templates/unified-core.ms').read_text(encoding='utf-8')
    declared=set(re.findall(r'^\s*(\w+)\s+type:#\w+',source,re.M))
    captured=set(re.findall(r'\{"(\w+)"', (ROOT/'AminScatter/src/recipe_fields.inc').read_text(encoding='utf-8')))
    separate={
        'procSchemaValid','procOrder','procSetOrder',
        'procRadiusIDs','procRadiusModes','procRadiusValues','procRadiusDistances','procRadiusBinding',
        'procRuleScope','procRuleA','procRuleB','procRuleEnabled','procRuleMultiplier','procRuleGapWU','procRulePlanar',
        'paintDocument','editLayerKey','nextEditLayerKey','bakedNodes','nextPathID','nextBandID','logicalParentID',
        'layerID','layerVisible','layerObjects','layerNames','layerEnabled','activeLayer','paintAreas','uiAreaID','isPaintArea',
    }
    assert not captured & separate
    assert declared == captured | separate, 'New persistent parameters require an explicit full-save policy.'
    assert len(declared)==265 and len(captured)==234

def test_recipe_distances_follow_authoritative_parameter_types():
    source=(ROOT/'AminScatter/tools/ui/templates/unified-core.ms').read_text(encoding='utf-8')
    types=dict(re.findall(r'^\s*(\w+)\s+type:#(\w+)',source,re.M))
    spec=(ROOT/'AminScatter/src/recipe_fields.inc').read_text(encoding='utf-8')
    for name,kind,distance in re.findall(r'\{"(\w+)","(\w+)",(true|false)\}',spec):
        assert kind==types[name].lower()
        assert (distance=='true')==kind.startswith('worldunits')
