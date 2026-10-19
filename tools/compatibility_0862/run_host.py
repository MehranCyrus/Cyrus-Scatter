"""Run current density/library/UI regressions against the exact older-host package."""
from pathlib import Path
import argparse, hashlib, json, shutil, subprocess, sys, time
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send, ready
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args();assert a.host.startswith('density0862-compat-max2026-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
metadata=json.loads((host/'launch.json').read_text());assert metadata['max_year']==2026
payload=ROOT/'build/compatibility-0862-20261019/package01/payload2026'
manifest=json.loads((payload/'manifest.json').read_text())
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for name in metadata['binaries']:assert sha(host/'bin'/name)==manifest['files'][name]
assert sha(host/'scripts/CyrusScatter.ms')==manifest['files']['CyrusScatter.ms']
assert sha(host/'scripts/CyrusGallery.dll')==manifest['files']['CyrusGallery.dll']
library=host/'scripts/Library-0.86.2';assert not library.exists();shutil.copytree(payload/'Library',library)
stages=[]
def record(name,code):
    stages.append({'name':name,'exit_code':code});(host/'compatibility-campaign.json').write_text(json.dumps(stages,indent=2)+'\n')
def command(name,args):
    r=subprocess.run([sys.executable,*args],cwd=ROOT,capture_output=True,text=True)
    (host/(name+'.log')).write_text(r.stdout+r.stderr,encoding='utf-8');record(name,r.returncode)
    print(name+': '+str(r.returncode),flush=True);assert r.returncode==0,(r.stdout+r.stderr)[-4000:]
command('extended',['tools/density_0862/run_extended.py',a.host])
for phase in ('liveStart','liveVerify','liveIdle','unrelatedTime','staleField'):
    time.sleep(5 if phase=='liveIdle' else 1)
    (host/'lifecycle-phase.txt').write_text(phase);send(host,ROOT/'tools/density_0862/lifecycle.ms',phase)
record('lifecycle',0)
for name in ('field_numeric','channels'):
    send(host,ROOT/f'tools/density_0862/{name}.ms',name);record(name,0)
for campaign in ('workflow','examples','save'):
    command(campaign,['tools/density_0862/run_campaign.py',a.host,campaign,'--year','2026','--library',str(library)])
command('thumbnail',['tools/density_0862/run_thumbnail.py',a.host])
command('layout',['tools/density_0862/run_layout.py',a.host])
send(host,ROOT/'tools/ui_polish_0862/panel_contract.ms','Current UI contract');record('panel-contract',0)
print('PASS: older-host exact-pair campaigns',flush=True)
