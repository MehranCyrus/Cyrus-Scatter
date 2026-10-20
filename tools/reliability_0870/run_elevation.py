"""Qualify explicit relative-elevation fields in an owned Max 2027 host."""
from pathlib import Path
import argparse,hashlib,json,re,sys,time,uuid
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send,ready
p=argparse.ArgumentParser(description=__doc__);p.add_argument('host');p.add_argument('--phases',nargs='+');a=p.parse_args()
assert re.fullmatch(r'density0862-reliability-[a-z0-9-]+',a.host)
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
assert json.loads((host/'launch.json').read_text())['max_year']==2027
fixture=host/('elevation-fixture-'+uuid.uuid4().hex+'.ms');fixture.write_bytes((ROOT/'tools/reliability_0870/elevation.ms').read_bytes())
phases=a.phases or ('setup','flat','slope','transforms','channels','save','reopen','verifyReopen')
logs={}
for phase in phases:
 time.sleep(2);(host/'elevation-phase.txt').write_text(phase);send(host,fixture,phase)
 path=host/('elevation-'+phase+'.txt');result=path.read_text(encoding='utf-8-sig');print(result,flush=True)
 assert 'PASS: complete' in result and 'FAIL:' not in result,result
 logs[phase]=hashlib.sha256(path.read_bytes()).hexdigest()
(host/'elevation-result.json').write_text(json.dumps({'status':'passed','max_year':2027,'phases':phases,'logs':logs,
 'test_fixture':str(fixture),'test_sha256':hashlib.sha256(fixture.read_bytes()).hexdigest(),
 'script_sha256':hashlib.sha256((host/'scripts/CyrusScatter.ms').read_bytes()).hexdigest()},indent=2)+'\n')
