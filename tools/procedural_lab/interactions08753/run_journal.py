"""Pure MAXScript journal actions and reads; standalone Undo/Redo host events.

The small source replacement fixture must already be loaded and bound. This
runner does not clear history, accept unexpected holds, launch a host, or enter
Python inside Max. Its Python process orchestrates the external owned transport.
"""
from argparse import ArgumentParser
from pathlib import Path
import json,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[3]
p=ArgumentParser();p.add_argument('--host',required=True,type=Path)
p.add_argument('--resume',nargs='+',choices=('model','empty','point','remove','scale','offset','fast'))
a=p.parse_args()
host=a.host.resolve();results=[]

def run(script,case):
    result=subprocess.run([sys.executable,str(ROOT/'tools/procedural_lab/interactions08752/dispatch_job.py'),
                           '--host',str(host),'--script',str(ROOT/script),'--case',case,'--timeout','50'],
                          capture_output=True,text=True)
    results.append({'case':case,'exit_code':result.returncode,'stdout':result.stdout,'stderr':result.stderr})
    if result.returncode:raise RuntimeError(case+': '+result.stderr)
    # Let the Max callback return and its deferred UI timers fire naturally.
    # Sleeping here is outside Max and never pumps an open authored hold.
    time.sleep(1.25)

report={'status':'running'}
try:
    script='tools/procedural_lab/interactions08753/journal_native.ms'
    if not a.resume:
        run(script,'journal-native-prepare')
        run(script,'journal-native-observe')
    for kind in a.resume or ('model','empty','point','remove','scale','offset','fast'):
        run(script,'journal-native-action-'+kind)
        run(script,'journal-native-record')
        run('tools/procedural_lab/interactions0875/undo_host.ms','undo-native')
        run(script,'journal-native-undo-check')
        run('tools/procedural_lab/interactions0875/undo_host.ms','redo-native')
        run(script,'journal-native-redo-check')
        print(kind+': action / Undo / Redo pass',flush=True)
    for case in ('journal-native-cancel','journal-native-nested-cancel'):run(script,case);print(case+': pass',flush=True)
    report['status']='pass'
except Exception as error:report.update(status='failed',error=str(error));raise
finally:
    report['events']=results
    report['resumed_kinds']=a.resume
    report['scope']='Native MAXScript actions/checks and standalone Undo/Redo in an already owned Max 2027 fixture. No Python inside Max, history clearing or automatic hold acceptance.'
    (host/('journal-campaign-'+str(time.time_ns())+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
