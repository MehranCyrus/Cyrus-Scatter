from pathlib import Path
import argparse,hashlib,json,sys,time
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send,ready
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('--phases',nargs='+');p.add_argument('--collect-only',action='store_true');a=p.parse_args()
assert a.host.startswith('density0862-reliability-surface0866-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
phases=a.phases or ['setup','button','manual','erase','undo','verifyUndo','redo','verifyRedo','spline','fill','copy','surfaces','transform','geometry','save','reopen','verifyReopen','live','verifyLive','idle','verifyIdle']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
logs={}
for phase in phases:
 if not a.collect_only:
  (host/'surface-phase.txt').write_text(phase);send(host,ROOT/'tools/surface_brush_0866/acceptance.ms',phase);time.sleep(1)
 path=host/('surface-'+phase+'.txt');text=path.read_text(encoding='utf-8-sig');print(text,flush=True);assert 'PASS: complete' in text and 'FAIL:' not in text;logs[phase]=sha(path)
(host/'surface-result.json').write_text(json.dumps({'status':'passed','max_year':2027,'phases':phases,'logs':logs,'launch_sha256':sha(host/'launch.json'),'script_sha256':sha(host/'scripts/CyrusScatter.ms'),'test_sha256':sha(ROOT/'tools/surface_brush_0866/acceptance.ms')},indent=2)+'\n')
