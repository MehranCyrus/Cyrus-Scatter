"""Read-only final provenance and result gate; no Max mutation or installation."""
from pathlib import Path
import hashlib,json,re,zipfile
from urllib.parse import unquote
ROOT=Path(__file__).resolve().parents[2];DOC=ROOT/'docs/Terrace_Workflow_0.79.5_2026-10-11'
def read(p): return json.loads(p.read_text())
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(value,label):
    checks.append(dict(passed=bool(value),label=label))
    if not value: raise RuntimeError(label)
e=read(DOC/'evidence.json')
for year,host in e['hosts'].items():
    launch=host['launch'];folder=Path(launch['output'])
    check(sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')==launch['script_sha256'],year+' tested script unchanged')
    frozen=read(ROOT/f'build/refine0795-20261011/max{year}-02/source.json')
    for name,digest in frozen.items():
        if name.endswith(('.cpp','.h','.inc','.cmake')) or name.endswith('CMakeLists.txt'):
            path=ROOT/('CyrusLicensing/team/team_public_key.h' if name=='team_public_key.h' else name)
            check(sha(path)==digest,year+' frozen source '+name)
    for name,receipt in host['receipts'].items():
        check(sha(Path(receipt['path']))==receipt['sha256'],year+' raw receipt '+name)
        check(not receipt.get('errors') and not receipt.get('failures') and all(c['passed'] for c in receipt.get('checks',[])),year+' passing '+name)
        if name.startswith(('radius-undo-','layer-undo-')):check(receipt['result']['passed'],year+' Undo phase '+name)
    package=read(DOC/f'package-{year}.json');path=Path(package['package'])
    check(sha(path)==package['sha256'],year+' package hash')
    with zipfile.ZipFile(path) as z:
        manifest=read(DOC/f'package-{year}.json')['manifest']
        for name,digest in manifest['files'].items():
            check(hashlib.sha256(z.read(name)).hexdigest()==digest,year+' archive '+name)
        check(not any('transport' in n.lower() or 'test-authority' in n.lower() for n in z.namelist()),year+' no diagnostic transport')
    check(sha(folder/'input-examples.max')==sha(ROOT/'build/vector-brush-078/include-exclude-visible2026-01/Include_Exclude_Point_Examples.max'),year+' original example file matches preserved input')
for p in [DOC/'README.md',DOC/'COVERAGE.md',DOC/'CONTROL_REGISTER.md']:
    for link in re.findall(r'\]\(([^)]+)\)',p.read_text()):
        if link.startswith(('http:','https:','#')): continue
        check((p.parent/unquote(link.split('#')[0])).exists(),'Document link '+link)
for artifact in e['scene_artifacts']:check(sha(Path(artifact['path']))==artifact['sha256'],'Scene artifact '+Path(artifact['path']).name)
(DOC/'verification.json').write_text(json.dumps(dict(checks=checks),indent=2)+'\n')
print(str(len(checks))+' final delivery checks passed')
