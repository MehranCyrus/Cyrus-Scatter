"""Scoped plugin regressions from an actual MZP-installed runtime."""
from pathlib import Path
import argparse,json,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send,ready
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args();assert a.host.startswith('density0862-installer-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host);meta=json.loads((host/'launch.json').read_text())
assert not meta['startup_filein_product'];year=meta['max_year'];library=Path(meta['installed_release'])/'Library-0.86.2'
stages=[]
def record(name,code):
 stages.append({'name':name,'exit_code':code});(host/'installer-campaign.json').write_text(json.dumps(stages,indent=2)+'\n')
def command(name,args):
 r=subprocess.run([sys.executable,*args],cwd=ROOT,capture_output=True,text=True)
 (host/(name+'.log')).write_text(r.stdout+r.stderr,encoding='utf-8');record(name,r.returncode)
 print(name+': '+str(r.returncode),flush=True);assert r.returncode==0,(r.stdout+r.stderr)[-4000:]
command('extended',['tools/density_0862/run_extended.py',a.host])
for phase in ('liveStart','liveVerify','liveIdle','unrelatedTime','staleField'):
 time.sleep(5 if phase=='liveIdle' else 1);(host/'lifecycle-phase.txt').write_text(phase);send(host,ROOT/'tools/density_0862/lifecycle.ms',phase)
record('lifecycle',0)
for name in ('field_numeric','channels'):
 send(host,ROOT/f'tools/density_0862/{name}.ms',name);record(name,0)
for campaign in ('workflow','examples','save'):
 command(campaign,['tools/density_0862/run_campaign.py',a.host,campaign,'--year',str(year),'--library',str(library)])
command('thumbnail',['tools/density_0862/run_thumbnail.py',a.host])
command('layout',['tools/density_0862/run_layout.py',a.host])
send(host,ROOT/'tools/ui_polish_0862/panel_contract.ms','Current UI contract');record('panel-contract',0)
print('PASS: installed runtime campaigns',flush=True)
