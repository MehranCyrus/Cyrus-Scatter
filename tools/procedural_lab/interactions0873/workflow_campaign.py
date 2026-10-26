"""Drive only an already launched, owned workflow fixture via its private transport."""
from argparse import ArgumentParser
from pathlib import Path
import json,time

p=ArgumentParser();p.add_argument('--host',required=True,type=Path);p.add_argument('--suffix',required=True);p.add_argument('--phases',nargs='+',default=['controls','contacts','lifecycle']);a=p.parse_args()
root=Path(__file__).resolve().parents[3];host=a.host.resolve()
assert host.is_relative_to(root/'build') and (host/'launch.json').is_file()
assert a.suffix.replace('-','').isalnum()
deadline=time.monotonic()+180
while not (host/'ready.json').exists():
    assert time.monotonic()<deadline,'Owned fixture did not become ready';time.sleep(.25)
assert json.loads((host/'ready.json').read_text()).get('status')=='ready'

def command(label,body):
    path=host/f'{a.suffix}-{label}.ms';assert not path.exists();path.write_text(body,encoding='utf-8')
    (host/'dev-request.txt').write_text(path.as_posix(),encoding='utf-8')
    deadline=time.monotonic()+180
    while True:
        result=(host/'dev-result.txt').read_text() if (host/'dev-result.txt').exists() else ''
        if path.as_posix() in result:
            assert result.startswith('SUCCESS'),result;return
        assert time.monotonic()<deadline,label+' timed out';time.sleep(.25)

def run(label,script,prefix=''):
    command(label,prefix+'python.ExecuteFile @"'+(root/'tools/procedural_lab/interactions0873'/script).as_posix()+'"')

if 'controls' in a.phases:
    run('controls','workflow_controls.py');result=json.loads((host/'controls.json').read_text());assert result.get('status')=='pass',result;print('Controls:',len(result['checks']),'passed',flush=True)
if 'contacts' in a.phases:
    run('setup','workflow_contact_setup.py')
    for step in range(4):
        run('move-'+str(step),'workflow_contact_step.py',f'WFContactStep={step};')
        result=json.loads((host/'contacts.json').read_text())['moves'][-1];assert result.get('status')=='pass',result
        print('Move',step,'passed,',result['command_seconds'],'seconds',flush=True)
    (host/f'{a.suffix}-contacts.json').write_bytes((host/'contacts.json').read_bytes())
if 'lifecycle' in a.phases:
    run('lifecycle','workflow_lifecycle.py');result=json.loads((host/'lifecycle.json').read_text());assert result.get('status')=='pass',result;print('Lifecycle:',len(result['checks']),'passed',flush=True)
if 'undo' in a.phases:
    write=lambda name,expr:'(dotNetClass "System.IO.File").WriteAllText (GardenRun+"'+a.suffix+'-'+name+'.txt") ('+expr+' as string)'
    command('gap-set',write('gap-original','WFGrass.interactionGapWU')+';undo "Contact gap check" on WFGrass.interactionGapWU=0.02;WFRoot.interactionsEnsure();CyrusPointSync();completeRedraw();'+write('gap-set','WFGrass.interactionGapWU'))
    command('gap-undo','max undo;'+write('gap-undo','WFGrass.interactionGapWU'))
    command('gap-redo','max redo;'+write('gap-redo','WFGrass.interactionGapWU'))
    read=lambda name:(host/f'{a.suffix}-{name}.txt').read_text()
    assert read('gap-undo')==read('gap-original') and read('gap-redo')==read('gap-set') and read('gap-set')!=read('gap-original')
    command('gap-restore','undo off WFGrass.interactionGapWU=0;WFRoot.interactionsEnsure();CyrusPointSync()')
    point='(cyrusPlacementTransformGroups (cyrusInteractionRows WFRoot.interactionState 2))[1][1].row4'
    command('edit-set',write('edit-original',point)+';cyrusEditActiveLayers WFEdit #(WFCollider.editLayerKey);cyrusEditSelect WFEdit #(1);undo "Collider Undo check" on cyrusEditTransform WFEdit 0 [0,0,8] (matrix3 1) false;WFRoot.interactionsEnsure();CyrusPointSync();completeRedraw();'+write('edit-set',point))
    command('edit-undo','max undo;CyrusPointSync();'+write('edit-undo',point))
    command('edit-redo','max redo;CyrusPointSync();'+write('edit-redo',point))
    assert read('edit-undo')==read('edit-original') and read('edit-redo')==read('edit-set') and read('edit-set')!=read('edit-original')
    result={k:read(k) for k in ['gap-original','gap-set','gap-undo','gap-redo','edit-original','edit-set','edit-undo','edit-redo']};result['status']='pass'
    (host/f'{a.suffix}-undo.json').write_text(json.dumps(result,indent=2));print('Undo/Redo: gap and collider passed',flush=True)
