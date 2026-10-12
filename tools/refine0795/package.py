"""Package the matched, tested 0.79.5 pair without installing it."""
from pathlib import Path
from types import SimpleNamespace
import argparse, hashlib, json, shutil, sys, zipfile
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
import build_max
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def read(path): return json.loads(path.read_text(encoding='utf-8'))
p=argparse.ArgumentParser()
for name in ('host','candidate','output','receipt'): p.add_argument('--'+name,type=Path,required=True)
p.add_argument('--creation-fix',action='store_true',help='Require the focused creation/display regression campaign')
a=p.parse_args();host=a.host.resolve();candidate=a.candidate.resolve()
launch=read(host/'launch.json')
if a.creation_fix:
    loaded=[]
    for line in (host/'loaded.tsv').read_text(encoding='utf-8-sig').splitlines():
        name,path=line.split('\t');loaded.append(dict(name=name,path=path,sha256=sha(Path(path))))
else: loaded=read(host/'loaded-modules.json')
if len(loaded)!=5: raise RuntimeError('Missing loaded module evidence')
for module in loaded:
    if module['sha256']!=launch['binaries'][module['name']] or Path(module['path']).resolve()!=host/'bin'/module['name']:
        raise RuntimeError('Host loaded a different module: '+module['name'])
if build_max.scatter_version()!='0.79.5': raise RuntimeError('Wrong release packager')
if sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')!=launch['script_sha256']: raise RuntimeError('Untested script')
for name,digest in read(candidate/'source.json').items():
    if name.endswith(('.cpp','.h','.inc','.cmake')) or name.endswith('CMakeLists.txt'):
        path=ROOT/('CyrusLicensing/team/team_public_key.h' if name=='team_public_key.h' else name)
        if sha(path)!=digest: raise RuntimeError('Compiled source changed: '+name)
tests=['display0792','invalidation0792','layer-lifecycle','reuse-checks','endurance','navigation0792',
    'scene-results','falloff-results','points-results','reopen-results','empty-results','layout-results']
tests += ['workflow'] if launch['max_year']==2026 else ['garden-checks','garden-reopen','controls','render','benchmark','final-scene','final-render']
if a.creation_fix: tests=['create-callbacks','create-visibility','create-existing','workflow','navigation0792']
for name in tests:
    d=read(host/(name+'.json'));checks=d.get('assertions',d.get('checks',[]))
    if d.get('errors') or not checks or not all(c['passed'] for c in checks): raise RuntimeError('Failed '+name)
if not a.creation_fix:
    if read(host/'point-model-probe.json')['errors']: raise RuntimeError('Failed Point/model probe')
    for kind,phases in [('layer-undo',('prepare','delete','undo','redo')),('radius-undo',('prepare','edit','undo','redo'))]:
        for phase in phases:
            if not read(host/(kind+'-'+phase+'.json'))['passed']: raise RuntimeError('Failed '+kind)
native_names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
stage=host/'package-stage';(stage/'AminScatter').mkdir(parents=True,exist_ok=False)
for name in native_names:
    if sha(host/'bin'/name)!=launch['binaries'][name] or sha(candidate/'native'/name)!=launch['binaries'][name]:
        raise RuntimeError('Untested binary '+name)
    shutil.copy2(host/'bin'/name,stage/'AminScatter'/name)
args=SimpleNamespace(max_year=launch['max_year'],tools_version='14.38.33130',windows_sdk='10.0.19041.0',
    output=a.output,team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h')
target=a.output/f'CyrusScatter-0.79.5-Max{launch["max_year"]}.mzp'
if target.exists(): raise RuntimeError('Use a fresh delivery path')
build_max.package('AminScatter','Cyrus Scatter','0.79.5',native_names,'AminScatterObject.ms',args,stage)
with zipfile.ZipFile(target) as z:
    manifest=json.loads(z.read('manifest.json'))
    if manifest['files']['CyrusScatter.ms']!=launch['script_sha256']: raise RuntimeError('Archive script mismatch')
a.receipt.parent.mkdir(parents=True,exist_ok=True)
a.receipt.write_text(json.dumps(dict(package=str(target.resolve()),sha256=sha(target),manifest=manifest,
    host=str(host),candidate=str(candidate),installed=False,qualification=tests),indent=2)+'\n',encoding='utf-8')
print(str(target.resolve()))
