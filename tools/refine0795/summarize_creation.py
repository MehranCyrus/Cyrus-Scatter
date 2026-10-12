"""Verify and preserve the focused creation correction receipts and delivery hashes."""
from pathlib import Path
import hashlib,json,statistics,zipfile
ROOT=Path(__file__).resolve().parents[2]
DOC=ROOT/'docs/Terrace_Workflow_0.79.5_2026-10-11'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
e=dict(version='0.79.5',schema=55,script_sha256=sha(ROOT/'AminScatter/scripts/AminScatterObject.ms'),hosts={},packages={},limitations=[
    'SDK callbacks and traced geometry submission are not physical mouse input or presented pixels.',
    'Scripted navigation times are not presented FPS.',
    'Initial settings-panel mounting remains B21; no UI speedup is claimed.',
    'No artist installation, normal-profile mutation, Git push, or website change.'])
for year,run in [(2026,'01'),(2027,'02')]:
    host=ROOT/f'build/mcp-qualification/refine0795-create-fixed-{year}-{run}'
    launch=read(host/'launch.json')
    assert launch['script_sha256']==e['script_sha256']==sha(host/'scripts/CyrusScatter.ms')
    receipts={};total=0
    for name in ['create-callbacks','create-visibility','create-existing','workflow','navigation0792']:
        path=host/(name+'.json');d=read(path);checks=d['assertions']
        assert not d['errors'] and checks and all(c['passed'] for c in checks),name
        total+=len(checks)
        receipts[name]=dict(path=str(path),sha256=sha(path),checks=checks)
    callbacks=read(host/'create-callbacks.json')
    metrics=dict(create_entry_ms=callbacks['checkpoints'][0]['action_ms'],
        sizing_callback_median_ms=statistics.median(x['elapsed_ms'] for x in callbacks['events'] if x['label'].startswith('sizing')),
        navigation=[dict(label=x['label'],held=x['held'],median_ms=x['median_ms']) for x in read(host/'navigation0792.json')['measurements']])
    package=read(DOC/f'creation-package-{year}.json');target=Path(package['package'])
    assert sha(target)==package['sha256']
    with zipfile.ZipFile(target) as archive:
        manifest=json.loads(archive.read('manifest.json'))
        assert manifest['files']['CyrusScatter.ms']==e['script_sha256']
        for name,digest in manifest['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest,name
        assert not any('probe' in n.lower() or 'transport' in n.lower() for n in archive.namelist())
    e['hosts'][str(year)]=dict(launch=launch,assertions=total,receipts=receipts,metrics=metrics)
    e['packages'][str(year)]=package
(DOC/'creation-evidence.json').write_text(json.dumps(e,indent=2)+'\n',encoding='utf-8')
print(json.dumps({year:dict(assertions=h['assertions'],metrics=h['metrics']) for year,h in e['hosts'].items()},indent=2))
