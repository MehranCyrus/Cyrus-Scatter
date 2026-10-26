"""Run bounded source/UI and reported-asset phases in an owned Max 2027 host."""
from pathlib import Path
from argparse import ArgumentParser
import json,time
p=ArgumentParser();p.add_argument('--host',required=True,type=Path);p.add_argument('--suffix',required=True);p.add_argument('--phase',choices=['sources','swatches','fern'],required=True);a=p.parse_args()
ROOT=Path(__file__).resolve().parents[3];folder=Path(__file__).parent;host=a.host.resolve();assert host.is_relative_to(ROOT/'build') and (host/'launch.json').exists()
assert json.loads((host/'ready.json').read_text()).get('status')=='ready'
def command(label,body):
    path=host/f'{a.suffix}-{label}.ms';assert not path.exists();path.write_text(body,encoding='utf-8');(host/'dev-request.txt').write_text(path.as_posix(),encoding='utf-8');until=time.monotonic()+120
    while True:
        text=(host/'dev-result.txt').read_text() if (host/'dev-result.txt').exists() else ''
        if path.as_posix() in text:assert text.startswith('SUCCESS'),text;return
        assert time.monotonic()<until,label+' timed out';time.sleep(.2)
def run(label,script,prefix=''):command(label,prefix+'python.ExecuteFile @"'+(folder/script).as_posix()+'"')
def result(path):
    data=json.loads((host/path).read_text());assert 'error' not in data,data;return data
if a.phase=='sources':
    for phase in range(6):
        if phase==4:command('undo','max undo')
        if phase==5:command('redo','max redo')
        run('source-'+str(phase),'source_controls.py',f'global WFSourcePhase={phase};');data=result('source-controls.json')
    assert data['status']=='pass';print('Source buttons:',len(data['checks']),'passed')
elif a.phase=='swatches':
    run('swatches','swatch_geometry.py');data=result('swatch-geometry.json');assert data['status']=='pass';print('Swatches:',len(data['checks']),'passed')
elif a.phase=='fern':
    run('fern-setup','broadleaf_setup.py');data=result('broadleaf-setup.json');assert data['status']=='ready';print('Actual fern prepared; crown guides:',data['definition_report']['crown_root_guides'],flush=True)
    for step in range(5):
        run('fern-move-'+str(step),'broadleaf_step.py',f'WFContactStep={step};');entry=result('broadleaf-contacts.json')['moves'][-1];assert entry.get('status')=='pass',entry
        print('Fern move',step,entry['statistics']['fitted_guides'],'fitted guides; complete mesh clear',flush=True)
