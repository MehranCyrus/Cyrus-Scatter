"""Serialize correctness phases in one private host; benchmark separately."""
from pathlib import Path
import argparse,subprocess,sys
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);a=p.parse_args()
for phase in ['radius_undo','display','features','layers']:
    result=subprocess.run([sys.executable,str(Path(__file__).with_name('run.py')),str(a.profile),phase],capture_output=True,text=True)
    (a.profile/(phase+'-driver0792.log')).write_text(result.stdout+result.stderr,encoding='utf-8')
    print(phase+': '+('completed' if result.returncode==0 else 'FAILED'),flush=True)
    if result.returncode:print(result.stdout+result.stderr);raise SystemExit(result.returncode)
