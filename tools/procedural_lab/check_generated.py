"""Offline integration checks. This is not a MAXScript compiler or Max test."""
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'AminScatter/scripts/AminScatterObject.ms'


def check_balanced(text):
    """Ignore strings/comments, then check all MAXScript grouping delimiters."""
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


def main():
    before=SCRIPT.read_bytes()
    subprocess.run(['node','tools/ui/generate.cjs'],cwd=ROOT/'AminScatter',check=True)
    after=SCRIPT.read_bytes()
    assert before==after,'Generated source was stale; inspect regeneration and rerun.'
    text=after.decode('utf-8')
    check_balanced(text)
    assert re.findall(r'fn uiVersion = "([^"]+)"',text)==['0.7.1']
    assert 'version:53\ninitialRollupState' in text
    assert not re.search(r'\b(?:\w+\.)*groupPolicy[!=]=2',text),'Unclassified shared-policy consumer'
    for call in ('evaluateProcedural','procRefreshPreview','procApplyPaint','procEditKey','procCopyRelations'):
        assert re.search(r'fn '+call+r'\b',text),call
    inventory=json.loads((ROOT/'AminScatter/tools/ui/layers-control-inventory.json').read_text())
    controls=sum(len(v) for section in ('general','layer') for v in inventory[section].values())
    assert controls==241,'Review the documented control inventory after changes.'
    check_balanced((ROOT/'tools/procedural_lab/Max_Procedural_07_Fixture.ms').read_text())
    for group in inventory['layer']:
        assert len(re.findall(r'rollout '+group+r'_1\b',text))==1,group
        assert not re.search(r'rollout '+group+r'_(?:[2-9]|10)\b',text),group
    assert 'rollout layerPanel_' not in text,'Obsolete per-layer pages remain'
    # Feature controls from 0.7.0 must survive the move/split, not just preserve
    # a total count. Topic structure and host behavior still require Max tests.
    baseline=json.loads(subprocess.check_output(['git','show',
        'addccb492a88292529594de81c287cc26e5ffe98:AminScatter/tools/ui/layers-control-inventory.json'],cwd=ROOT))
    split={'populationList':'populationPolicyUI','attemptSpin':'populationPolicyUI',
           'roundSpin':'populationPolicyUI','repairCheck':'populationPolicyUI',
           'backgroundList':'backgroundUI','referenceList':'backgroundUI','applyBackground':'backgroundUI',
           'radiusMode':'instanceRadiusUI','radiusSpin':'instanceRadiusUI','applyRadius':'instanceRadiusUI',
           'resetRadius':'instanceRadiusUI','clearRadius':'instanceRadiusUI'}
    for section,entries in baseline['layer'].items():
        for entry in entries:
            target=split.get(entry['name'],section) if section=='proceduralUI' else section
            assert entry in inventory['layer'].get(target,[]),(section,entry,'lost feature control')
    for section in ('general','layer'):
        for name,entries in inventory[section].items():
            assert len({e['name'] for e in entries})==len(entries),(section,name,'duplicate control')
    # Protect the proven display implementations and closed MCP mutation schemas.
    # Rollout scrolling now resolves the actual native column (review fix).
    # Its host behavior is qualified by pointer tests, not source immutability.
    preserved=['AminScatter/src/point_display.cpp','AminScatter/src/preview.cpp',
               'CyrusMCP/cyrus_mcp/models.py',
               'CyrusMCP/cyrus_mcp/contracts.py']
    for name in preserved:
        original=subprocess.check_output(['git','show','HEAD:'+name],cwd=ROOT)
        current=(ROOT/name).read_bytes()
        assert original.replace(b'\r\n',b'\n')==current.replace(b'\r\n',b'\n'),name+' changed unexpectedly'
    result={'check':'offline_generator_and_integration','passed':True,'maxscript_compiled':False,
            'ui_controls_in_inventory':controls,'generated_sha256':hashlib.sha256(after).hexdigest(),
            'preserved_files':preserved,'interactive_max_run':False}
    out=ROOT/'build/procedural-07';out.mkdir(parents=True,exist_ok=True)
    (out/'generated-check.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,indent=2))


if __name__=='__main__':main()
