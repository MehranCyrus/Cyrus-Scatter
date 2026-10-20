"""Run receiver-context map witnesses in a source-matched disposable Max 2027 host."""
from pathlib import Path
import argparse, hashlib, json, re, sys, time

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send,ready

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('host');p.add_argument('--phases',nargs='+');a=p.parse_args()
assert re.fullmatch(r'density0862-reliability-[a-z0-9-]+',a.host)
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
assert json.loads((host/'launch.json').read_text())['max_year']==2027
phases=a.phases or ('setup','white','channels','checker','receivers','live','verifyLive','idle','verifyIdle','reopen','verifyReopen')
logs={}
for phase in phases:
    time.sleep(3)
    (host/'receiver-map-phase.txt').write_text(phase)
    send(host,ROOT/'tools/reliability_0870/receiver_maps.ms',phase)
    path=host/('receiver-map-'+phase+'.txt');result=path.read_text(encoding='utf-8-sig')
    print(result,flush=True)
    assert 'PASS: complete' in result and 'FAIL:' not in result
    logs[phase]=hashlib.sha256(path.read_bytes()).hexdigest()
(host/'receiver-map-result.json').write_text(json.dumps({'status':'passed','max_year':2027,
    'phases':phases,'logs':logs,'script_sha256':hashlib.sha256((host/'scripts/CyrusScatter.ms').read_bytes()).hexdigest(),
    'test_sha256':hashlib.sha256((ROOT/'tools/reliability_0870/receiver_maps.ms').read_bytes()).hexdigest()},indent=2)+'\n')
