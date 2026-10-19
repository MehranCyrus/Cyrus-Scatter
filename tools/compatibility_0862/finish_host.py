"""Finish the campaign after the independently recorded cold-baseline correction."""
from pathlib import Path
import json, subprocess, sys
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send
name='density0862-compat-max2026-01';host=ROOT/'build/mcp-qualification'/name
retry=(host/'examples-retry.log').read_text(encoding='utf-8-sig');assert 'PASS campaign examples' in retry and 'FAIL:' not in retry
stages=json.loads((host/'compatibility-campaign.json').read_text());assert stages[-1]=={'name':'examples','exit_code':1}
stages[-1]={'name':'examples','exit_code':0,'receipt':'examples-retry.log','fixture_note':'Wait for deferred cold scene publication before capturing stable pre-import baseline. Initial logs preserved in first-example-attempt.'}
def save():(host/'compatibility-campaign.json').write_text(json.dumps(stages,indent=2)+'\n')
save()
for label,args in (
    ('save',['tools/density_0862/run_campaign.py',name,'save','--year','2026','--library',str(host/'scripts/Library-0.86.2')]),
    ('thumbnail',['tools/density_0862/run_thumbnail.py',name]),
    ('layout',['tools/density_0862/run_layout.py',name])):
    r=subprocess.run([sys.executable,*args],cwd=ROOT,capture_output=True,text=True)
    (host/(label+'.log')).write_text(r.stdout+r.stderr,encoding='utf-8');stages.append({'name':label,'exit_code':r.returncode});save()
    print(label+': '+str(r.returncode),flush=True);assert r.returncode==0,(r.stdout+r.stderr)[-3000:]
send(host,ROOT/'tools/ui_polish_0862/panel_contract.ms','Current panel contract');stages.append({'name':'panel-contract','exit_code':0});save()
script=host/'run-installer-wrapper.ms';script.write_text('python.executeFile @"'+(ROOT/'tools/compatibility_0862/installer_mzp.py').as_posix()+'"',encoding='utf-8-sig')
send(host,script,'Exact MZP wrapper in owned profile')
assert json.loads((host/'installer-wrapper.json').read_text())['status']=='passed'
stages.append({'name':'installer-wrapper','exit_code':0});save()
