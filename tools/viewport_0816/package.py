"""Package only the exact 0.81.6 script/native pair qualified in owned hosts."""
from pathlib import Path
from types import SimpleNamespace
import argparse,hashlib,json,shutil,sys,zipfile
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools'))
import build_max
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
p=argparse.ArgumentParser()
for name in ['host','candidate','output','receipt','stage']:p.add_argument('--'+name,type=Path,required=True)
a=p.parse_args();host=a.host.resolve();candidate=a.candidate.resolve()
launch=read(host/'launch.json');build=read(candidate/'receipt.json');year=launch['max_year']
assert host.parent==ROOT/'build/mcp-qualification' and host.name.startswith('foundation-viewport0816-')
assert year==build['max_year'] and build_max.scatter_version()=='0.81.6'
assert not build['preview_fault_lab'] and all(s['exit_code']==0 for s in build['stages'])
for path,digest in build['sources'].items():assert sha(ROOT/path)==digest,'Changed source: '+path
script=ROOT/'AminScatter/scripts/AminScatterObject.ms'
assert sha(script)==launch['script_sha256']==sha(host/'scripts/CyrusScatter.ms')
names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
loaded={n:Path(path).resolve() for n,path in (line.split('\t') for line in (host/'loaded.tsv').read_text(encoding='utf-8-sig').splitlines())}
assert set(loaded)==set(names)
build_hashes={Path(name).name:h for name,h in build['binaries'].items()}
for name in names:
    assert loaded[name]==host/'bin'/name
    assert sha(loaded[name])==sha(candidate/name)==launch['binaries'][name]==build_hashes[name]
checks={}
for name in ['small','retained-results','publication-results']+(['terrace','terrace-extra'] if year==2027 else []):
    d=read(host/(name+'.json'));c=d.get('checks',d.get('assertions',[]))
    assert c and all(x['passed'] for x in c) and not d.get('errors'),name
    assert d.get('status','complete')=='complete' and d.get('passed',True),name
    checks[name]=len(c)
stage=a.stage.resolve();assert stage.is_relative_to(ROOT/'build')
target=a.output/f'CyrusScatter-0.81.6-Max{year}.mzp';assert not target.exists()
(stage/'AminScatter').mkdir(parents=True,exist_ok=False)
for name in names:shutil.copy2(loaded[name],stage/'AminScatter'/name)
args=SimpleNamespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=a.output,team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h')
build_max.package('AminScatter','Cyrus Scatter','0.81.6',names,'AminScatterObject.ms',args,stage)
with zipfile.ZipFile(target) as z:
    manifest=json.loads(z.read('manifest.json'))
    assert manifest['files']['CyrusScatter.ms']==launch['script_sha256']
    for name in names:assert manifest['files'][name]==launch['binaries'][name]
    assert b'__MAX_YEAR__' not in z.read('install.ms') and b'__NATIVE_ID__' not in z.read('install.ms')
a.receipt.parent.mkdir(parents=True,exist_ok=True)
assert not a.receipt.exists()
a.receipt.write_text(json.dumps({'package':str(target.resolve()),'sha256':sha(target),'manifest':manifest,'host':str(host),'candidate':str(candidate),'installed':False,'checks':checks,'presented_fps_qualified':False},indent=2)+'\n')
print('Verified package: '+str(target.resolve()))
