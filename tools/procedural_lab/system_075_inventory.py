"""Generate a per-control audit register and a non-mutating Max binding probe.

Binding presence is deliberately separate from interaction/behavior acceptance.
Run from the repository root. Does not launch or connect to Max.
"""
import json
import hashlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs/System_Qualification_0.75_2026-10-09'


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    inventory = json.loads((ROOT/'AminScatter/tools/ui/layers-control-inventory.json').read_text())
    layout = json.loads((ROOT/'AminScatter/tools/ui/approved-layout-manifest.json').read_text())
    aliases = {'manager':'flow_layersUI', 'surface':'flow_surfaceUI',
               'previewUI':'flow_previewUI', 'diagnostics':'diagnosticsUI'}
    places = {(c['component'],c['control']):(s['name'],s['title'],c['presentation'])
              for s in layout['sections'] for c in s['controls']}
    records=[]
    for scope in ('general','layer','container'):
        for component, controls in inventory[scope].items():
            for c in controls:
                place=places.get((aliases.get(component,component),c['name']))
                records.append(dict(id=f"{scope}.{component}.{c['name']}", kind=c['kind'],
                                    section=place[1] if place else component,
                                    presentation=place[2] if place else None,
                                    page=place[0] if place else None,
                                    inventory_checked=True, interaction_verified=False))
    assert len(records)==234
    bound=set();handlers=set()
    for host in (ROOT/'build/mcp-qualification').glob('*qualification075*'):
        for name in ('control-bindings.tsv','other-control-bindings.tsv'):
            if (host/name).exists():bound.update(line.split('\t')[0] for line in (host/name).read_text().splitlines() if line.endswith('\tBOUND'))
        campaign=host/'campaign.json'
        if not campaign.exists():continue
        for case in json.loads(campaign.read_text()):
            if not case.get('passed'):continue
            # Only direct scripted control-event calls in a completed scenario.
            # A declaration/binding/model setter is not a handler test.
            for filename,expected_hash in case.get('files',{}).items():
                p=ROOT/filename
                if p.suffix!='.ms' or not p.exists():continue
                if hashlib.sha256(p.read_bytes()).hexdigest()!=expected_hash:
                    p=OUT/'fixtures'/p.name
                    if not p.exists() or hashlib.sha256(p.read_bytes()).hexdigest()!=expected_hash:continue
                handlers.update(re.findall(r'\.(\w+)\.(?:changed|pressed|picked|entered|selected|selectionEnd)\b',p.read_text()))
    for r in records:
        r['binding_verified']=r['id'] in bound
        r['passing_fixture_references_handler']=r['presentation'] in handlers
    (OUT/'CONTROL_REGISTER.json').write_text(json.dumps(records,indent=2)+'\n')
    lines=['# Complete control register','',
           'All 234 semantic controls are accounted for against the current generated inventory.',
           '**Binding is not interaction acceptance.** The fixture-reference column identifies event calls in hash-matching scripts loaded by passing scenarios. It is a coverage locator, not per-line execution proof or certification of every option, gesture or picker dialog. Use the family checklist for asserted behavior. Every control still requires final artist interaction acceptance.','',
           '| Inventory | Host binding | Passing fixture references handler | Control | Type | Current section |',
           '| --- | --- | --- | --- | --- | --- |']
    for r in records:
        lines.append(f"| [x] | {'[x]' if r['binding_verified'] else '[ ]'} | {'Yes' if r['passing_fixture_references_handler'] else '—'} | `{r['id']}` | {r['kind']} | {r['section']} |")
    (OUT/'CONTROL_REGISTER.md').write_text('\n'.join(lines)+'\n')
    probes=['-- Load only in an owned host after P07 definitions.', '(',
            'P07Case="All-control binding audit";P07New count:50',
            'select P07Node;max modify mode;modPanel.setCurrentObject P07Root',
            'if not P07Root.mainUI.controlsReady do P07Root.mainUI.mountTimer.tick()',
            'for page in P07Root.mainUI.editors do (page.open=true;P07Root.mainUI.bindSection page)',
            'local f=createFile (MCPFixtureDir+"control-bindings.tsv")']
    for r in records:
        if r['page']:
            probes.append(f'if not isProperty P07Root.{r["page"]} #{r["presentation"]} do throw "Missing binding: {r["id"]}"')
            probes.append(f'format "{r["id"]}\\tBOUND\\n" to:f')
    probes.extend(['close f', ')'])
    (OUT/'Control_Bindings.ms').write_text('\n'.join(probes)+'\n')
    print(f'{len(records)} controls; {sum(r["page"] is not None for r in records)} main-section bindings')


if __name__=='__main__':main()
