"""Resource, empty-source, damaged-package and repeated-import checks in owned Max."""
from pathlib import Path
import argparse,hashlib,json,re,shutil,sys,time,uuid
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send,ready
p=argparse.ArgumentParser(description=__doc__);p.add_argument('host');p.add_argument('--library',type=Path,required=True);a=p.parse_args()
assert re.fullmatch(r'density0862-reliability-[a-z0-9-]+',a.host)
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
assert json.loads((host/'launch.json').read_text())['max_year']==2027
run=host/('edge-run-'+uuid.uuid4().hex);run.mkdir();fixture=run/'edges.ms';fixture.write_bytes((ROOT/'tools/reliability_0870/edges.ms').read_bytes())
logs={}
def phase(name,token=None):
 time.sleep(2);(host/'edge-phase.txt').write_text(name);send(host,fixture,name)
 path=host/('edge-'+name+'.txt');result=path.read_text(encoding='utf-8-sig');print(result,flush=True)
 assert 'PASS: complete' in result and 'FAIL:' not in result,result
 key=token or name;shutil.copy2(path,run/(key+'.txt'));logs[key]=hashlib.sha256(path.read_bytes()).hexdigest()
for name in ('setup','mount','leadingSource','emptyReopen','gap','mapBudget'):phase(name)
library=a.library.resolve();inventory=json.loads((library/'inventory.json').read_text());entry=next(e for e in inventory['entries'] if e['id']=='meadow');package=library/entry['ready_package']
missing=run/'missing';shutil.copytree(package,missing)
graph=json.loads((missing/'assets.json').read_text());descriptor=next(f for f in graph['files'] if f['id']==graph['meshes'][0]['file'])
relative=Path('assets')/(descriptor['sha256']+'.cmesh');mesh=missing/relative;assert mesh.resolve().is_relative_to(missing);mesh.unlink()
damaged=run/'damaged';shutil.copytree(package,damaged);mesh=damaged/relative;data=bytearray(mesh.read_bytes());data[-1]^=1;mesh.write_bytes(data)
def load(path,expected,token):
 (host/'edge-package.txt').write_text(path.as_posix());phase('load',token+'-load');deadline=time.monotonic()+180
 while True:
  phase('poll',token+'-poll');state=(host/'edge-state.txt').read_text(encoding='utf-8-sig')
  if state==expected:break
  assert state=='pending',state
  if time.monotonic()>deadline:raise TimeoutError('Inspect existing pending request; do not replay')
 phase('success' if expected=='ready' else 'failure',token+'-verify')
load(missing,'error','missing');load(damaged,'error','damaged')
for i in range(3):load(package,'ready','repeat-'+str(i))
load(package,'error','capacity')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
(host/'edge-result.json').write_text(json.dumps({'status':'passed','run':str(run),'logs':logs,'test_sha256':sha(fixture),'script_sha256':sha(host/'scripts/CyrusScatter.ms'),'max_year':2027},indent=2)+'\n')
