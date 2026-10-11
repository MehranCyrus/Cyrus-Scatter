"""Run independent checks serially in one owned Max process; stop on failure."""
from pathlib import Path
import argparse,subprocess,sys

p=argparse.ArgumentParser();p.add_argument('profile',type=Path);a=p.parse_args()
phases=['undo_prepare','undo_check','scene','falloff','points','reopen','empty','layout','units']
for phase in phases:
    result=subprocess.run([sys.executable,str(Path(__file__).with_name('run_phase.py')),str(a.profile),phase],capture_output=True,text=True)
    (a.profile/(phase+'-driver.log')).write_text(result.stdout+result.stderr,encoding='utf-8')
    status='OBSERVATION RECORDED (not qualified)' if phase=='units' else 'PASS'
    print(phase+': '+(status if result.returncode==0 else 'FAILED'),flush=True)
    if result.returncode:
        print(result.stdout+result.stderr,flush=True)
        raise SystemExit(result.returncode)
