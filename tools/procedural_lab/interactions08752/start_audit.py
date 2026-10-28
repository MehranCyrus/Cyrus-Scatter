"""Freeze the pre-edit workspace and reusable numeric inputs for this audit."""
from pathlib import Path
import hashlib, json, shutil, subprocess

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'build/interactions08752-20261027-01'
OUT.mkdir(exist_ok=False)
paths = [p for p in (ROOT/'AminScatter').rglob('*') if p.is_file() and
         p.suffix in ('.h','.cpp','.inc','.ms','.cjs','.cs','.txt','.json') and
         not any(x in p.parts for x in ('node_modules','build','bin','obj'))]
for rel in ('README.md','docs/AGENT_WORKFLOW.md','docs/ARCHITECTURE.md','docs/ARTIST_GUIDE.md',
            'docs/Release_Versioning.md','docs/README.md','docs/plans/improvement-program/PROGRESS.md',
            'tools/procedural_lab/check_generated.py'):
    paths.append(ROOT/rel)
hashes = {}
for p in paths:
    relative = p.relative_to(ROOT).as_posix()
    hashes[relative] = hashlib.sha256(p.read_bytes()).hexdigest()
    destination = OUT/'source-before'/relative
    destination.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(p,destination)
state = {k: subprocess.check_output(v,cwd=ROOT,text=True) for k,v in {
    'status':['git','status','--short'],'branch':['git','branch','--show-current'],
    'head':['git','rev-parse','HEAD']}.items()}
state['files'] = hashes
(OUT/'starting-state.json').write_text(json.dumps(state,indent=2),encoding='utf-8')
previous = ROOT/'build/interactions0875-20261027-01/gpu-final-pair/gpu-audit.json'
audit = json.loads(previous.read_text())
fixtures = []
for i,entry in enumerate(audit['results']):
    source = Path(entry['fixture']); data = json.loads(source.read_text())
    assert hashlib.sha256(source.read_bytes()).hexdigest() == entry['fixture_sha256']
    data['compact_audit'] = False
    data.pop('compact_export',None)
    target = OUT/'fixtures'/f'natural-{i}.json'
    target.parent.mkdir(exist_ok=True)
    target.write_text(json.dumps(data,indent=2),encoding='utf-8')
    fixtures.append(str(target))
(OUT/'fixtures.json').write_text(json.dumps(fixtures,indent=2),encoding='utf-8')
print(json.dumps({'output':str(OUT),'preserved_sources':len(hashes),'fixtures':fixtures},indent=2))
