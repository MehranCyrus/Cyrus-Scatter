"""Package only the tested 0.79.2 script/native pair, without installation."""
from pathlib import Path
from types import SimpleNamespace
import argparse,hashlib,json,shutil,sys,zipfile
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
import build_max
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
p=argparse.ArgumentParser()
for name in ('host','candidate','output','receipt'):p.add_argument('--'+name,type=Path,required=True)
a=p.parse_args();host=a.host.resolve();candidate=a.candidate.resolve()
launch=json.loads((host/'launch.json').read_text(encoding='utf-8'))
if build_max.scatter_version()!='0.79.2':raise RuntimeError('Use the matching release packager')
if sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')!=launch['script_sha256']:raise RuntimeError('Untested script')
for name,digest in json.loads((candidate/'source.json').read_text(encoding='utf-8')).items():
    if name!='team_public_key.h' and (name.endswith(('.cpp','.h','.inc')) or name.endswith('CMakeLists.txt')):
        if sha(ROOT/name)!=digest:raise RuntimeError('Compiled source changed: '+name)
for name in ('display0792','navigation0792','invalidation0792','layer-lifecycle'):
    result=json.loads((host/(name+'.json')).read_text(encoding='utf-8'))
    if result['errors'] or not result['assertions'] or not all(c['passed'] for c in result['assertions']):raise RuntimeError('Failed '+name)
for name in ('layer-cache-probe','point-model-probe','artist-layer-probe'):
    if json.loads((host/(name+'.json')).read_text(encoding='utf-8'))['errors']:raise RuntimeError('Failed '+name)
for kind,phases in [('layer-undo',('prepare','delete','undo','redo')),('radius-undo',('prepare','edit','undo','redo'))]:
    for phase in phases:
        if not json.loads((host/(kind+'-'+phase+'.json')).read_text())['passed']:raise RuntimeError('Failed '+kind)
for phase in ('scene','falloff','points','reopen','empty','layout'):
    result=json.loads((host/(phase+'-results.json')).read_text())
    if not result['checks'] or not all(c['passed'] for c in result['checks']):raise RuntimeError('Failed '+phase)
native_names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
stage=host/'package-stage';(stage/'AminScatter').mkdir(parents=True,exist_ok=False)
for name in native_names:
    if sha(host/'bin'/name)!=launch['binaries'][name] or sha(candidate/'native'/name)!=launch['binaries'][name]:raise RuntimeError('Untested binary '+name)
    shutil.copy2(host/'bin'/name,stage/'AminScatter'/name)
args=SimpleNamespace(max_year=launch['max_year'],tools_version='14.38.33130',windows_sdk='10.0.19041.0',
    output=a.output,team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h')
target=a.output/f'CyrusScatter-0.79.2-Max{launch["max_year"]}.mzp'
if target.exists():raise RuntimeError('Use a fresh delivery path')
build_max.package('AminScatter','Cyrus Scatter','0.79.2',native_names,'AminScatterObject.ms',args,stage)
with zipfile.ZipFile(target) as z:
    manifest=json.loads(z.read('manifest.json'))
    if manifest['files']['CyrusScatter.ms']!=launch['script_sha256']:raise RuntimeError('Archive script mismatch')
a.receipt.parent.mkdir(parents=True,exist_ok=True)
a.receipt.write_text(json.dumps(dict(package=str(target.resolve()),sha256=sha(target),manifest=manifest,
    host=str(host),candidate=str(candidate),installed=False),indent=2)+'\n',encoding='utf-8')
