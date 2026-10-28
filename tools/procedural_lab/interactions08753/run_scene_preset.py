"""Four pure-MAXScript Scene preset phases in an existing owned small fixture."""
from argparse import ArgumentParser
from pathlib import Path
import json,subprocess,sys,time

ROOT=Path(__file__).resolve().parents[3]
p=ArgumentParser();p.add_argument('--host',required=True,type=Path);p.add_argument('--timeout',type=int,default=180);a=p.parse_args()
host=a.host.resolve();events=[];report={'status':'running'}
if not 10<=a.timeout<=600:p.error('--timeout must be 10..600 seconds per async wait')
if host.parent!=ROOT/'build/interactions08753-20261028-01' or not host.name.startswith('host-') or not (host/'launch.json').is_file():
    p.error('--host must identify an already launched owned scene-repair host')

def run(case):
    result=subprocess.run([sys.executable,str(ROOT/'tools/procedural_lab/interactions08752/dispatch_job.py'),
        '--host',str(host),'--script',str(ROOT/'tools/procedural_lab/interactions08753/scene_preset_native.ms'),
        '--case',case,'--timeout','60'],capture_output=True,text=True)
    events.append({'case':case,'exit_code':result.returncode,'stdout':result.stdout,'stderr':result.stderr})
    if result.returncode:raise RuntimeError(case+': '+result.stderr)
    receipt=json.loads((host/(case+'.json')).read_text(encoding='utf-8'))
    if receipt['status']!='pass':raise RuntimeError(case+': '+receipt.get('error',receipt['status']))
    return receipt

def poll(case,wanted):
    until=time.monotonic()+a.timeout
    while time.monotonic()<until:
        time.sleep(1.25)  # External orchestration; no Python or event pumping inside Max.
        receipt=run(case)
        if receipt['state']==wanted:return receipt
    raise TimeoutError(case+' did not reach '+wanted+' within the bounded wait')

try:
    run('scene-native-save')
    poll('scene-native-poll','preparing')
    poll('scene-native-ready','ready')
    time.sleep(1.25)
    report['merge']=run('scene-native-merge')
    report['status']='pass';print('Native Scene preset save / PrepareScene / independent merge: pass',flush=True)
except Exception as error:
    report.update(status='failed',error=str(error))
    # Cancel only this harness's copied-byte jobs and restore its library-root
    # override. This phase never accepts or cancels an unrelated host hold.
    try:run('scene-native-cancel')
    except Exception as cleanup_error:report['cleanup_error']=str(cleanup_error)
    raise
finally:
    report['events']=events
    report['scope']='Small owned Max2027 Scene preset; standard merge clears Undo; no material patching or artist-file overwrite. Native geometry fingerprints do not qualify renderer/material/UV/normal output.'
    (host/('scene-native-campaign-'+str(time.time_ns())+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
