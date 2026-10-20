"""Serialized real Max workflows. Every command records its own terminal result."""
from pathlib import Path
import argparse,json,sys,time
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/native_placement'));from run_generation import send,ready
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('campaign',choices=('workflow','examples','save'))
p.add_argument('--year',type=int,choices=(2024,2026,2027),default=2027);p.add_argument('--library',type=Path);a=p.parse_args()
assert a.host.startswith('density0862-');host=ROOT/'build/mcp-qualification'/a.host;ready(host)
assert json.loads((host/'launch.json').read_text())['max_year']==a.year
library=(a.library or ROOT/'AminScatter/library').resolve();inventory=json.loads((library/'inventory.json').read_text(encoding='utf-8'))
assert inventory['max_year']==a.year
entries={entry['id']:entry for entry in inventory['entries']}
def write(name,value):(host/name).write_text(value,encoding='utf-8')
def wait(editor):
    probe=host/'observe-terminal.ms'
    probe.write_text('(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"terminal.txt") (('+editor+'!=undefined and '+editor+'.finished) as string)',encoding='utf-8-sig')
    deadline=time.monotonic()+120
    while True:
        time.sleep(.5);send(host,probe,'Observe existing '+editor)
        if (host/'terminal.txt').read_text(encoding='utf-8-sig')=='true':return
        if time.monotonic()>deadline:raise TimeoutError('Observe pending worker before another mutation')
def step(script,phase,phasefile,log):
    write(phasefile,phase);send(host,ROOT/'tools/density_0862'/script,phase)
    text=(host/log).read_text(encoding='utf-8-sig');print(text,flush=True)
    assert 'PASS: complete' in text and 'FAIL:' not in text
def panels(root,node,label):
    probe=host/'mount-library-panels.ms'
    probe.write_text('select '+node+'; max modify mode; '+root+'.bindNativeUI()',encoding='utf-8-sig')
    send(host,probe,'Mount library result panels')
    send(host,ROOT/'tools/density_0862/panel_checks.ms','Load panel checks')
    probe=host/'inspect-library-panels.ms'
    probe.write_text('DCheckRootPanels '+root+' "'+label+'"',encoding='utf-8-sig')
    send(host,probe,'Inspect each library layer')
    result=(host/('panels-'+label+'.txt')).read_text(encoding='utf-8-sig')
    assert 'PASS: complete' in result and 'ERROR:' not in result
    print(result,flush=True)
if a.campaign=='workflow':
    write('library-path.txt',library.as_posix());write('meadow-package.txt',(library/entries['meadow']['ready_package']).as_posix())
    write('mask-package.txt',(library/entries['valley']['ready_package']).as_posix())
    for phase in ('setup','load','verify','undo','verifyUndo','redo','verifyRedo','append','verifyAppend','undo','verifyAppendUndo','save','reopen','boundaries','cancel','idleStart','idleEnd'):
        if phase in ('verify','verifyAppend'):wait('CyrusReadyPresetEditor')
        if phase=='load':time.sleep(1)
        if phase=='idleEnd':time.sleep(5)
        step('workflow.ms',phase,'phase.txt','workflow-'+phase+'.txt')
        if phase=='verify':panels('LRoot','LNode','library-new')
        if phase=='verifyAppend':panels('LRoot','LNode','library-append')
elif a.campaign=='examples':
    for entry in inventory['entries']:
        write('example-id.txt',entry['id']);write('example-scene.txt',(library/entry['scene']).as_posix());write('example-package.txt',(library/entry['ready_package']).as_posix())
        for phase in ('setup','baseline','baselineVerify','load','verify','undo','verifyUndo','redo','verifyRedo'):
            if phase in ('baseline','baselineVerify'):time.sleep(2)
            if phase=='verify':wait('CyrusReadyPresetEditor')
            step('examples.ms',phase,'example-phase.txt','example-'+entry['id']+'-'+phase+'.txt')
        panels('ERoot','ENode','example-'+entry['id'])
else:
    write('save-scene.txt',(library/entries['borders']['scene']).as_posix())
    for phase in ('save','verifySave','verifyLoad','historyWithoutPackage'):
        if phase in ('verifySave','verifyLoad'):wait('CyrusPresetSaveEditor' if phase=='verifySave' else 'CyrusReadyPresetEditor')
        step('save_roundtrip.ms',phase,'save-phase.txt','save-'+phase+'.txt')
        if phase=='verifyLoad':panels('SRoot','SNode','saved-image-paint')
print('PASS campaign',a.campaign,flush=True)
