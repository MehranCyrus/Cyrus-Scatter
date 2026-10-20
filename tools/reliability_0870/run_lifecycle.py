"""Run only in the recorded disposable reliability Max 2027 process."""
from pathlib import Path
import argparse, ctypes, hashlib, json, re, sys, time

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send,ready

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('host');p.add_argument('--phases',nargs='+')
p.add_argument('--collect-only',action='store_true',help='Verify and index already completed phase logs without rerunning Max')
a=p.parse_args()
assert re.fullmatch(r'density0862-reliability-[a-z0-9-]+',a.host)
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
assert json.loads((host/'launch.json').read_text())['max_year']==2027
phases = a.phases or ('setup','mount','remove','undo','verifyUndo','redo','verifyRedo',
        'point','replace','verifyDelete','emptyEdges','libraryOpen','libraryMinimize','libraryRestore','libraryContext',
        'libraryReopen','libraryVerifyReopen')
for phase in phases:
    if not a.collect_only:
        time.sleep(2)
        (host/'reliability-phase.txt').write_text(phase)
        send(host,ROOT/'tools/reliability_0870/lifecycle.ms',phase)
    result=(host/('lifecycle-'+phase+'.txt')).read_text(encoding='utf-8-sig')
    print(result,flush=True)
    assert 'PASS: complete' in result and 'FAIL:' not in result
    if phase=='libraryRestore' and not a.collect_only:
        api=ctypes.windll.user32;api.GetForegroundWindow.restype=ctypes.c_void_p
        hwnd=int((host/'library-window.txt').read_text(encoding='utf-8-sig').removesuffix('P').removesuffix('L'))
        api.IsIconic.argtypes=[ctypes.c_void_p]
        state={'window':hwnd,'foreground':api.GetForegroundWindow(),'minimized':bool(api.IsIconic(hwnd))}
        state['focus_evidence']='observed' if state['foreground']==hwnd else 'not observed; another window retained foreground during the background test'
        (host/'library-foreground.json').write_text(json.dumps(state,indent=2)+'\n')
        assert not state['minimized'],state
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
(host/'lifecycle-result.json').write_text(json.dumps({
    'status':'passed', 'max_year':2027, 'phases':phases,
    'launch_sha256':sha(host/'launch.json'),
    'script_sha256':sha(host/'scripts/CyrusScatter.ms'),
    'test_sha256':sha(ROOT/'tools/reliability_0870/lifecycle.ms'),
    'logs':{phase:sha(host/('lifecycle-'+phase+'.txt')) for phase in phases},
    'scope':'Only the listed lifecycle phases on this loaded candidate. Not release qualification.'
},indent=2)+'\n')
