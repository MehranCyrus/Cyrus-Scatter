"""Package only the exact 0.81.5 binaries and script exercised in owned hosts."""
from pathlib import Path
from types import SimpleNamespace
import argparse,hashlib,json,shutil,sys,zipfile
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools'))
import build_max
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
p=argparse.ArgumentParser()
for n in ['host','candidate','output','receipt']:p.add_argument('--'+n,type=Path,required=True)
a=p.parse_args();host=a.host.resolve();candidate=a.candidate.resolve();launch=read(host/'launch.json');build=read(candidate/'receipt.json')
assert host.name.startswith('foundation-terrace0815-candidate')
assert launch['max_year']==build['max_year'] and build_max.scatter_version()=='0.81.5'
assert all(s['exit_code']==0 for s in build['stages'])
for path,digest in build['sources'].items():assert sha(ROOT/path)==digest,'Changed compiled source: '+path
assert sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')==launch['script_sha256']
native_names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
loaded={n:Path(path).resolve() for n,path in (line.split('\t') for line in (host/'loaded.tsv').read_text(encoding='utf-8-sig').splitlines())}
assert set(loaded)==set(native_names)
for n in native_names:
    assert loaded[n]==host/'bin'/n
    assert sha(loaded[n])==sha(candidate/n)==launch['binaries'][n]
assert read(host/'focused-qualification.json')['complete']
assert read(host/'regressions-0815.json')['complete'] and not read(host/'regressions-0815.json')['failures']
checks={}
for name in ['capacity-host-01','containers-final','preview-oracle','retained-results','workflow','invalidation0792','publication-results']:
    d=read(host/(name+'.json'));c=d.get('checks',d.get('assertions',[]))
    assert c and all(x['passed'] for x in c) and not d.get('errors'),name
    assert d.get('status','complete')=='complete',name
    checks[name]=len(c)
assert read(host/'render-scale-01.json')['parity']
movement=(host/'container-native-fresh.txt').read_text(encoding='utf-8-sig')
assert all(x in movement for x in ['PASS Move','PASS Undo','PASS Redo','PASS Resize'])
if launch['max_year']==2027:
    assert read(host/'garden-final-acceptance.json')['status']=='complete'
stage=host/'package-stage';(stage/'AminScatter').mkdir(parents=True,exist_ok=False)
for n in native_names:shutil.copy2(loaded[n],stage/'AminScatter'/n)
args=SimpleNamespace(max_year=launch['max_year'],tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=a.output,team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h')
target=a.output/f'CyrusScatter-0.81.5-Max{launch["max_year"]}.mzp'
assert not target.exists(),'Use a fresh delivery path'
build_max.package('AminScatter','Cyrus Scatter','0.81.5',native_names,'AminScatterObject.ms',args,stage)
with zipfile.ZipFile(target) as z:
    manifest=json.loads(z.read('manifest.json'))
    assert manifest['files']['CyrusScatter.ms']==launch['script_sha256']
    for n in native_names:assert manifest['files'][n]==launch['binaries'][n]
a.receipt.parent.mkdir(parents=True,exist_ok=True)
a.receipt.write_text(json.dumps({'package':str(target.resolve()),'sha256':sha(target),'manifest':manifest,'host':str(host),'candidate':str(candidate),'installed':False,'checks':checks,'movement_undo_redo_resize':True,'render_source_frame_parity':True},indent=2)+'\n')
print(target.resolve())
