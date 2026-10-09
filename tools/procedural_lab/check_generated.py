"""Check reproducible source/help and reviewed control ports, not Max runtime."""
import csv
import hashlib
import json
from pathlib import Path
import re
import subprocess
import argparse

ROOT=Path(__file__).resolve().parents[2]
BASE='01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2'
SCRIPT=ROOT/'AminScatter/scripts/AminScatterObject.ms'


def check_balanced(text):
    """Ignore MAXScript strings/comments and check grouping delimiters."""
    stack=[];i=0;line=1
    while i<len(text):
        ch=text[i]
        if ch=='\n':line+=1
        if text.startswith('--',i):
            stop=text.find('\n',i);i=len(text) if stop<0 else stop;continue
        if text.startswith('/*',i):
            stop=text.find('*/',i+2)
            if stop<0:raise AssertionError(f'Unterminated comment at {line}')
            line+=text[i:stop+2].count('\n');i=stop+2;continue
        if ch=='"':
            raw=i>0 and text[i-1]=='@';i+=1
            while i<len(text) and text[i]!='"':
                if text[i]=='\n':line+=1
                if text[i]=='\\' and not raw:i+=1
                i+=1
            if i==len(text):raise AssertionError(f'Unterminated string at {line}')
        elif ch in '([{':stack.append((ch,line))
        elif ch in ')]}':
            assert stack and stack[-1][0]=='([{'[')]}'.index(ch)],f'Unmatched {ch} at {line}'
            stack.pop()
        i+=1
    assert not stack,f'Unclosed delimiters: {stack[-5:]}'


def controls(inventory):
    return {f'{group}/{section}/{entry["name"]}':entry
            for group in ('general','layer','container')
            for section,entries in inventory[group].items() for entry in entries}


def port_rows(inventory):
    current=controls(inventory)
    with (ROOT/'docs/Unified_Procedural_Settings_2026-10-06/CONTROL_PORT_REGISTER.csv').open(encoding='utf-8-sig',newline='') as file:
        baseline=list(csv.DictReader(file))
    assert len(baseline)==245 and len({r['control_key'] for r in baseline})==245
    replacements={
        'general/surface/policyButton':[],
        'layer/distributionUI/showCenterCheck':['general/previewUI/displayModeDrop'],
        'layer/spacingUI/collisionCheck':['layer/proceduralUI/scopeList','layer/proceduralUI/enabledCheck'],
        'layer/spacingUI/radiusSpin':['layer/proceduralUI/multiplierSpin','layer/proceduralUI/gapSpin'],
        'layer/separationUI/prioritySpin':['general/manager/upButton','general/manager/downButton'],
        'layer/separationUI/peerList':['layer/proceduralUI/peerList'],
        'layer/separationUI/blockerList':['layer/proceduralUI/scopeList','layer/proceduralUI/peerList'],
        'layer/separationUI/overlapCheck':['layer/proceduralUI/enabledCheck'],
        'layer/separationUI/radiusMode':['layer/proceduralUI/multiplierSpin'],
        'layer/separationUI/gapSpin':['layer/proceduralUI/gapSpin'],
        'layer/separationUI/radiusSpin':['layer/proceduralUI/multiplierSpin','layer/proceduralUI/gapSpin'],
        'layer/separationUI/statsButton':['layer/detailsUI/refreshButton'],
        **{f'layer/separationUI/{name}':[f'layer/spacingUI/{name}'] for name in
           ('boundaryRelaxCheck','finalStrengthSpin','finalIterSpin','finalMoveSpin')},
    }
    # Retired artist-facing history and old set-specific background controls.
    replacements.update({f'layer/brushUI/{name}': [] for name in
        ('strokeList','strokeEnabled','strokeErase','strokeRadius','strokeStrength','strokeSoft','deleteStroke','resetTarget','detailsToggle','coverageMode')})
    replacements.update({f'layer/backgroundUI/{name}': [] for name in
        ('backgroundList','referenceList','applyBackground')})
    replacements.update({f'layer/setsUI/{name}': [] for name in ('weightSpin','visibleCheck','upButton','downButton')})
    replacements['layer/brushUI/coverageMode']=['layer/setsUI/paintedCheck']
    result=[]
    for row in baseline:
        key=row['control_key']
        targets=[key] if key in current else replacements[key]
        assert all(target in current for target in targets),(key,targets)
        if targets==[key]:assert current[key]['kind']==row['kind'],key
        result.append(dict(control_key=key,planned_disposition=row['disposition'],
            actual_controls='|'.join(targets),status='retired_conversion' if not targets else
            'present' if targets==[key] and row['disposition']=='retain' else 'merged_or_ported',
            evidence='README.md; IMPLEMENTATION.md; RESULTS.md; current generated inventory',
            limitation='Control mapping is source evidence; runtime acceptance is by feature/scenario, not every combination.'))
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=ROOT/'build/approved-layout-073-20261006')
    args=parser.parse_args()
    products=[SCRIPT,ROOT/'AminScatter/tools/ui/layers-control-inventory.json',ROOT/'AminScatter/tools/ui/layer-editor-tooltips.json']
    before={p:p.read_bytes() for p in products}
    subprocess.run(['node','tools/ui/generate.cjs','--check'],cwd=ROOT/'AminScatter',check=True)
    assert all(p.read_bytes()==data for p,data in before.items()),'Generated source/help was stale; inspect and rerun.'
    text=SCRIPT.read_text(encoding='utf-8')
    check_balanced(text)
    assert re.findall(r'fn uiVersion = "([^"]+)"',text)==['0.74']
    assert 'version:54\ninitialRollupState' in text and 'CyrusUnified1' in text
    for obsolete in ('groupPolicy','procUpgrade','paintIdentity','Layer priority','legacyUI','if true then','if false then'):
        assert obsolete not in text,obsolete
    for name in ('evaluateProcedural','procRefreshPreview','procApplyPaint','procEditKey','procCopyRelations',
                 'CyrusContainerConsumers','CyrusContainerLinks','CyrusContainerRefreshAll'):
        assert re.search(r'fn '+name+r'\b',text),name
    inventory=json.loads(products[1].read_text())
    current=controls(inventory)
    assert len(current)==232
    layout=json.loads((ROOT/'AminScatter/tools/ui/approved-layout-manifest.json').read_text())
    assert len(layout['sections'])==10
    for section in layout['sections']:
        assert len(re.findall(r'rollout '+section['name']+r'\b',text))==2,section['name']
        for control in section['controls']:
            assert len(re.findall(r'\b'+control['presentation']+r'\b',text))>=2,control
    assert not re.search(r'rollout selected_\w+UI\b',text)
    assert 'rollout layerPanel_' not in text
    for group in ('general','layer','container'):
        for section,entries in inventory[group].items():
            assert len({e['name'] for e in entries})==len(entries),(group,section)
    ports=port_rows(inventory)
    report_dir=args.output
    report_dir.mkdir(parents=True,exist_ok=True)
    with (report_dir/'CONTROL_PORT_RESULTS.csv').open('w',newline='',encoding='utf-8') as file:
        writer=csv.DictWriter(file,fieldnames=list(ports[0]));writer.writeheader();writer.writerows(ports)
    # The known retained-display implementation is intentionally unchanged.
    preserved=['AminScatter/src/preview.cpp','AminScatter/src/point_display.cpp']
    for name in preserved:
        original=subprocess.check_output(['git','show',BASE+':'+name],cwd=ROOT).replace(b'\r\n',b'\n')
        assert (ROOT/name).read_bytes().replace(b'\r\n',b'\n')==original,name
    schema=json.loads((ROOT/'CyrusMCP/cyrus_mcp/plan.schema.json').read_text())
    assert schema['properties']['schema_version']['const']=='0.73'
    catalog=json.loads((ROOT/'CyrusMCP/cyrus_mcp/feature-catalog.json').read_text())
    assert catalog['development_version']=='0.74' and catalog['calculation_model']=='CyrusUnified1'
    assert len(catalog['controls'])==len(current) and len(catalog['features'])==34
    assert catalog['control_inventory_sha256']==hashlib.sha256(products[1].read_bytes()).hexdigest()
    assert catalog['capability_source_sha256']==hashlib.sha256((ROOT/'docs/Current_System_2026-10-05/CAPABILITY_MATRIX.md').read_bytes()).hexdigest()
    fixtures=sorted((ROOT/'tools/procedural_lab').glob('Max_*073*.ms'))
    fixtures += sorted((ROOT/'tools/procedural_lab').glob('Max_*074*.ms'))
    fixtures += [ROOT/'tools/procedural_lab/Max_Procedural_07_Fixture.ms',ROOT/'tools/procedural_lab/Max_Procedural_07_Acceptance.ms']
    for fixture in fixtures:check_balanced(fixture.read_text(encoding='utf-8-sig'))
    result=dict(check='unified_073_generator_integration',passed=True,development_version='0.74',
        baseline=BASE,maxscript_compiled=False,ui_controls_in_inventory=len(current),baseline_controls_accounted=245,
        generated_sha256=hashlib.sha256(SCRIPT.read_bytes()).hexdigest(),preserved_files=preserved,
        fixture_delimiters_checked=len(fixtures),interactive_max_run=False)
    out=args.output;out.mkdir(parents=True,exist_ok=True)
    (out/'generated-check.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,indent=2))


if __name__=='__main__':main()
