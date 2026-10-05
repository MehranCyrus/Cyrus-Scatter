"""Policy-3 read-only qualification through the actual Max MCP transport."""
import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/mcp'))
from qualify import Qualification
from runtime_driver import run_script


def main(folder):
    folder = folder.resolve()
    q = Qualification(folder)
    q.local('setup')
    plan = q.plan(q.context(), count=200)
    plan['schema_version'] = '2.0'
    operation = q.apply(plan)
    assert operation['state'] == 'succeeded', operation
    script = folder / 'procedural-mcp-setup.py'
    script.write_text('''import json
import host_fixture
import pymxs
from pymxs import runtime as rt
from cyrus_mcp.contracts import Fault
from cyrus_mcp.procedural import require_legacy_mutation
panel=host_fixture.PANEL
node=next(iter(panel.host.controllers.values()))
with pymxs.undo(True,"Private procedural setup"):
    node.procUpgrade()
    parent=node.layerObjects[0]
    child=node.addPaintSet(parent,label="Flowers")
    child.sources=parent.sources
    rt.cyrusBrushFill(child.paintDocument,1.0)
    node.procMove(child,-1,sets=True)
    node.procSetPair(1,parent,child,True,0.5,0.2,True)
    node.updateMode=1
    node.refreshAll()
before=panel.host.fingerprint()
try:
    require_legacy_mutation(node)
    raise AssertionError("Legacy mutation accepted policy 3")
except Fault as exc:
    assert exc.code=="UNSUPPORTED_CAPABILITY",exc
assert panel.host.fingerprint()==before
with pymxs.undo(True,"Private pending recipe"):
    parent.amount=250
rt.select(node)
panel.inspect_selected()
(host_fixture.OUTPUT/"procedural-mcp-setup.json").write_text(json.dumps({
    "parent":str(parent.layerID),"child":str(child.layerID),
    "prepared":[list(x.procStatistics())[2] for x in node.layerObjects],
    "epoch":int(parent.procStatistics()[4]),"mutation_guard":True}))
''', encoding='utf-8')
    result = run_script(folder, 'python.ExecuteFile @"' + script.as_posix() + '"')
    assert result.startswith('SUCCESS '), result
    setup = json.loads((folder / 'procedural-mcp-setup.json').read_text())
    # Enroll after Max has processed the completed scene mutation callbacks.
    q.local('boundary', kind='inspect')
    before = q.local('snapshot')
    context = q.context()
    cid = next(iter(context['observed_controllers']))
    config = q.call('scatter.get_configuration', scene_epoch=context['scene_epoch'], controller_id=cid)['configuration']
    after = q.local('snapshot')
    assert before == after, 'Inspection changed Max state'
    proc = config['procedural']
    assert config['group_policy'] == 3 and proc['mutation_supported'] is False
    sets = proc['layers_in_order'][0]['sets_in_order']
    assert [s['set_id'] for s in sets] == [setup['child'], setup['parent']]
    assert [s['prepared_builds'] for s in reversed(sets)] == setup['prepared']
    assert all(s['last_published']['epoch'] == setup['epoch'] for s in sets)
    assert config['layers'][0]['count'] == 250
    assert all(asset['entry_id'] for layer in config['layers'] for asset in layer['assets'])
    assert proc['pair_rules'][0]['scope'] == 'paint_sets'
    record = {'pure_inspection': True, 'new_order_and_rule': True,
              'pending_recipe_separate_from_epoch': True, 'legacy_mutation_guard_rejected': True,
              'configuration': config}
    (folder / 'procedural-mcp.json').write_text(json.dumps(record, indent=2))
    print(json.dumps({k:v for k,v in record.items() if k != 'configuration'}, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('folder', type=Path)
    main(parser.parse_args().folder)
