"""Selected-terrain preset transfers in owned fresh Max 2027 scenes."""
from pathlib import Path
import argparse,hashlib,json,re,sys,time,uuid
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send,ready
p=argparse.ArgumentParser(description=__doc__);p.add_argument('host')
p.add_argument('--ids',nargs='+',required=True);p.add_argument('--units',nargs='+',default=['centimeters'])
p.add_argument('--variant',choices=['plain','transformed','folded','tiny','huge','heightfield'],default='plain')
p.add_argument('--library',type=Path,default=ROOT/'AminScatter/library');a=p.parse_args()
assert re.fullmatch(r'density0862-reliability-[a-z0-9-]+',a.host)
assert set(a.units)<=set(('meters','centimeters','millimeters','feet'))
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
assert json.loads((host/'launch.json').read_text())['max_year']==2027
library=a.library.resolve();assert library==ROOT/'AminScatter/library' or library.is_relative_to(ROOT/'build/reliability-0870-20261019')
inventory=json.loads((library/'inventory.json').read_text())
entries={entry['id']:entry for entry in inventory['entries']};assert set(a.ids)<=entries.keys()
script=host/('preset-transfer-fixture-'+uuid.uuid4().hex+'.ms')
script.write_bytes((ROOT/'tools/reliability_0870/preset_transfer.ms').read_bytes())
for identifier in a.ids:
 entry=entries[identifier];package=library/entry['ready_package']
 assert package.resolve().is_relative_to(library.resolve()) and (package/'cyrus.package.json').is_file()
 for unit in a.units:
  token=identifier+'-'+unit+'-'+a.variant;assert re.fullmatch(r'[a-z0-9_-]+',token)
  for key,value in {'case':token,'package':package.as_posix(),'unit':unit,'variant':a.variant}.items():
   (host/('preset-transfer-'+key+'.txt')).write_text(value)
  logs={}
  def phase(name):
   time.sleep(2);(host/'preset-transfer-phase.txt').write_text(name);send(host,script,token+' / '+name)
   path=host/('preset-'+token+'-'+name+'.txt');result=path.read_text(encoding='utf-8-sig')
   assert 'PASS: complete' in result and 'FAIL:' not in result,result
   logs[name]=hashlib.sha256(path.read_bytes()).hexdigest()
   if name!='poll':print(result,flush=True)
  def load(expected):
   phase('load');deadline=time.monotonic()+180
   while True:
    phase('poll');state=(host/'preset-transfer-state.txt').read_text(encoding='utf-8-sig')
    if state==expected:break
    if state in ('ready','error'):raise RuntimeError((host/('preset-'+token+'-poll.txt')).read_text(encoding='utf-8-sig'))
    if time.monotonic()>deadline:raise TimeoutError('Preset is still pending; inspect this request/host before retrying')
  phase('setup');load('error' if a.variant=='folded' else 'ready')
  if a.variant=='folded':phase('verifyFailure');phase('repair');load('ready')
  for name in ('verify','physicalUnits','undo','verifyUndo','redo','verifyRedo','save','reopen','verifyReopen'):phase(name)
  (host/('preset-'+token+'-result.json')).write_text(json.dumps({'status':'passed','case':token,'max_year':2027,
   'package_manifest_sha256':hashlib.sha256((package/'cyrus.package.json').read_bytes()).hexdigest(),
   'test_fixture':str(script),'test_sha256':hashlib.sha256(script.read_bytes()).hexdigest(),'logs':logs,
   'script_sha256':hashlib.sha256((host/'scripts/CyrusScatter.ms').read_bytes()).hexdigest()},indent=2)+'\n')
