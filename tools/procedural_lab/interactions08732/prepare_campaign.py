"""Serialize bounded integration phases in one already-owned Max 2027 profile."""
from pathlib import Path
from argparse import ArgumentParser
import json,time
p=ArgumentParser();p.add_argument('--host',type=Path,required=True);p.add_argument('--suffix',required=True);p.add_argument('--phases',nargs='+',required=True);a=p.parse_args()
ROOT=Path(__file__).resolve().parents[3];host=a.host.resolve();assert host.is_relative_to(ROOT/'build') and (host/'launch.json').exists();assert a.suffix.replace('-','').isalnum()
end=time.monotonic()+180
while not (host/'ready.json').exists():assert time.monotonic()<end,'Host did not finish booting';time.sleep(.25)
assert json.loads((host/'ready.json').read_text())['status']=='ready'
def command(label,body):
    path=host/f'{a.suffix}-{label}.ms';assert not path.exists();path.write_text(body,encoding='utf-8');(host/'dev-request.txt').write_text(path.as_posix(),encoding='utf-8');end=time.monotonic()+180
    while True:
        result=(host/'dev-result.txt').read_text() if (host/'dev-result.txt').exists() else ''
        if path.as_posix() in result:assert result.startswith('SUCCESS'),result;return
        assert time.monotonic()<end,label+' timed out';time.sleep(.25)
def run(label,script,prefix=''):command(label,prefix+'python.ExecuteFile @"'+(ROOT/'tools/procedural_lab/interactions08732'/script).as_posix()+'"')
if 'controls' in a.phases:
    run('controls','prepare_controls.py');r=json.loads((host/'prepare-controls.json').read_text());assert r.get('status')=='pass',r;print('Controls:',len(r['checks']),'passed',flush=True)
if 'contacts' in a.phases:
    run('setup','prepare_contact_setup.py');r=json.loads((host/'hover-setup.json').read_text());assert r.get('status')=='ready',r
    for step in range(5):
        run('move-'+str(step),'prepare_contact_step.py',f'WFContactStep={step};');r=json.loads((host/'hover-contacts.json').read_text())['moves'][-1];assert r.get('status')=='pass',r
        print('Hover move',step,'passed,',r['statistics']['fitted_guides'],'guides,',r['statistics']['hidden_roots'],'hidden roots',flush=True)
if 'undo' in a.phases:
    script='prepare_undo.py'
    run('undo-before',script,'global WFPrepareUndoPhase=0;')
    run('undo-edit',script,'WFPrepareUndoPhase=1;')
    command('undo','max undo')
    run('undo-read',script,'WFPrepareUndoPhase=2;')
    command('redo','max redo')
    run('redo-read',script,'WFPrepareUndoPhase=3;')
    r=json.loads((host/'prepare-undo.json').read_text());assert r.get('status')=='pass',r;print('Preparation Undo/Redo: passed',flush=True)
if 'lifecycle' in a.phases:
    for phase in range(10):
        run('lifecycle-'+str(phase),'prepare_lifecycle.py',f'global WFPrepareLifePhase={phase};');r=json.loads((host/'prepare-lifecycle.json').read_text());assert 'error' not in r,r
    assert r.get('status')=='pass',r;print('Lifecycle:',len(r['checks']),'passed',flush=True)
