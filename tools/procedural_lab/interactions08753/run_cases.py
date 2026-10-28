"""Run ordered owned-host cases; stop on first failure and keep the receipt."""
from argparse import ArgumentParser
from pathlib import Path
import json,subprocess,sys,time

ROOT=Path(__file__).resolve().parents[3]
p=ArgumentParser();p.add_argument('--host',required=True,type=Path);p.add_argument('--script',required=True,type=Path);p.add_argument('cases',nargs='+');a=p.parse_args()
host=a.host.resolve();results=[];started=time.time_ns();failed=False
for case in a.cases:
    begin=time.perf_counter()
    completed=subprocess.run([sys.executable,str(ROOT/'tools/procedural_lab/interactions08752/dispatch_job.py'),'--host',str(host),'--script',str(a.script.resolve()),'--case',case,'--timeout','50'],text=True,capture_output=True)
    row={'case':case,'exit_code':completed.returncode,'seconds':time.perf_counter()-begin,'stdout':completed.stdout,'stderr':completed.stderr};results.append(row)
    print(case+': '+('pass' if completed.returncode==0 else 'FAILED'),flush=True)
    if completed.returncode:failed=True;print(completed.stderr,flush=True);break
(host/('ordered-cases-'+str(started)+'.json')).write_text(json.dumps({'status':'failed' if failed else 'pass','script':str(a.script.resolve()),'cases':results},indent=2),encoding='utf-8')
raise SystemExit(1 if failed else 0)
