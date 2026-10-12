"""0.79.2 private-host regression driver. Never attaches to an artist host."""
from pathlib import Path
import argparse, json, shutil, sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab'))
from runtime_driver import run_script
p=argparse.ArgumentParser();p.add_argument('profile',type=Path)
p.add_argument('phase',choices=['layers','navigation','display','features','radius_undo','invalidation','artist'])
a=p.parse_args();folder=a.profile.resolve()
if folder.parent!=ROOT/'build/mcp-qualification' or not folder.name.startswith('refine0791-layer0792-'):
    raise ValueError('A freshly launched 0.79.2 owned profile is required')
def execute(script):
    result=run_script(folder,script,timeout=240)
    print(result,flush=True)
    if not result.startswith('SUCCESS '):raise RuntimeError(result)
def fixture(path):execute('undo off (python.ExecuteFile @"'+path.as_posix()+'")')
if a.phase=='layers':
    shutil.copy2(ROOT/'Test Scene/for layering test.max',folder/'artist-layering-input.max')
    for name in ['layer_lifecycle','layer_cache_probe','point_model_probe']:
        fixture(ROOT/'tools/refine0791'/f'{name}.py')
    for phase in ['prepare','delete','undo','redo']:
        execute('global L791Phase="'+phase+'";fileIn @"'+(ROOT/'tools/refine0791/layer_undo_probe.ms').as_posix()+'"')
    fixture(ROOT/'tools/refine0791/artist_layer_probe.py')
elif a.phase=='artist':fixture(ROOT/'tools/refine0791/artist_layer_probe.py')
elif a.phase=='radius_undo':
    for phase in ['prepare','edit','undo','redo']:
        execute('global R792UndoPhase="'+phase+'";fileIn @"'+Path(__file__).with_name('radius_undo.ms').as_posix()+'"')
elif a.phase=='features':
    for phase in ['scene','falloff','points','reopen','empty','layout']:
        execute('global R791ExpectedVersion="0.79.2",R791Phase="'+phase+'";undo off (python.ExecuteFile @"'+(ROOT/'tools/refine0791/host_checks.py').as_posix()+'")')
else:fixture(Path(__file__).with_name(a.phase+'.py'))
