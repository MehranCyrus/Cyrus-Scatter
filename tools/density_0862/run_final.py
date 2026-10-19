"""Run the final exact-pair host campaign and retain compact receipts."""
from pathlib import Path
import argparse,json,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'));from run_generation import send,ready
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args();assert a.host.startswith('density0862-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host);stages=[]
def command(label,args):
    r=subprocess.run([sys.executable,*args],cwd=ROOT,capture_output=True,text=True)
    (host/(label+'.log')).write_text(r.stdout+r.stderr,encoding='utf-8')
    stages.append({'name':label,'exit_code':r.returncode});(host/'final-campaign.json').write_text(json.dumps(stages,indent=2))
    print(label+': '+str(r.returncode),flush=True)
    if r.returncode:raise RuntimeError((r.stdout+r.stderr)[-3000:])
command('extended',['tools/density_0862/run_extended.py',a.host])
for phase in ('liveStart','liveVerify','liveIdle','unrelatedTime','staleField'):
    time.sleep(5 if phase=='liveIdle' else 1)
    (host/'lifecycle-phase.txt').write_text(phase);send(host,ROOT/'tools/density_0862/lifecycle.ms',phase)
    print('lifecycle '+phase+': pass',flush=True)
stages.append({'name':'lifecycle','exit_code':0});(host/'final-campaign.json').write_text(json.dumps(stages,indent=2))
send(host,ROOT/'tools/density_0862/field_numeric.ms','field_numeric')
send(host,ROOT/'tools/density_0862/channels.ms','channels')
for campaign in ('workflow','examples','save'):command(campaign,['tools/density_0862/run_campaign.py',a.host,campaign])
for name in ('demo','demo_verify','ui_demo_setup','layout_prepare','layout'):
    if name=='layout':time.sleep(.5)
    send(host,ROOT/('tools/density_0862/'+name+'.ms'),name);print(name+': pass',flush=True)
    stages.append({'name':name,'exit_code':0});(host/'final-campaign.json').write_text(json.dumps(stages,indent=2))
