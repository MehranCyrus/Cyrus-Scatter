"""Replay established witnesses with explicit adapters, preserving original fixtures."""
from pathlib import Path
import argparse,hashlib,json,re,shutil,sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab'))
from runtime_driver import run_script
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);a=p.parse_args();out=a.profile.resolve()
if out.parent!=ROOT/'build/mcp-qualification' or not out.name.startswith('refine0795-'):raise ValueError('Owned profile required')
receipt=dict(adapters=[],steps=[]);manifest=out/'regressions.json'
def write():manifest.write_text(json.dumps(receipt,indent=2)+'\n')
def adapt(relative):
    path=ROOT/relative;content=path.read_text(encoding='utf-8-sig')
    content=re.sub(r'ROOT\s*=\s*Path\(__file__\)\.resolve\(\)\.parents\[2\]',lambda _: 'ROOT=Path('+repr(ROOT.as_posix())+')',content)
    content=content.replace('refine0791-layer0792-','refine0795-').replace('refine0791-layer','refine0795-').replace('refine0791-','refine0795-')
    target=out/('adapted-'+path.name);target.write_text(content,encoding='utf-8')
    receipt['adapters'].append(dict(source=relative,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),adapter_sha256=hashlib.sha256(target.read_bytes()).hexdigest()));write();return target
def execute(label,code):
    result=run_script(out,code,timeout=600);receipt['steps'].append(dict(label=label,result=result));write();print(label+': '+result[:30],flush=True)
    if not result.startswith('SUCCESS '):raise RuntimeError(result)
shutil.copy2(ROOT/'build/vector-brush-078/include-exclude-visible2026-01/Include_Exclude_Point_Examples.max',out/'input-examples.max')
for name in ('display','invalidation'):
    path=adapt('tools/refine0792/'+name+'.py');execute(name,'python.ExecuteFile @"'+path.as_posix()+'"')
path=adapt('tools/refine0791/layer_lifecycle.py');execute('layer-lifecycle','python.ExecuteFile @"'+path.as_posix()+'"')
path=adapt('tools/refine0791/point_model_probe.py');execute('point-model-setup','python.ExecuteFile @"'+path.as_posix()+'"')
for relative,variable in [('tools/refine0791/layer_undo_probe.ms','L791Phase'),('tools/refine0792/radius_undo.ms','R792UndoPhase')]:
    path=adapt(relative)
    phases=['prepare','delete','undo','redo'] if 'layer_' in relative else ['prepare','edit','undo','redo']
    for phase in phases:execute(path.stem+'-'+phase,'global '+variable+'="'+phase+'";fileIn @"'+path.as_posix()+'"')
path=adapt('tools/refine0791/host_checks.py')
for phase in ('scene','falloff','points','reopen','empty','layout'):
    execute('features-'+phase,'global R791ExpectedVersion="0.79.5",R791Phase="'+phase+'";undo off (python.ExecuteFile @"'+path.as_posix()+'")')
failures=[];count=0
for name in ('display0792','invalidation0792','layer-lifecycle','scene-results','falloff-results','points-results','reopen-results','empty-results','layout-results'):
    value=json.loads((out/(name+'.json')).read_text());checks=value.get('assertions',value.get('checks',[]));count+=len(checks)
    failures.extend([name+': '+str(c) for c in checks if not c['passed']]);failures.extend(value.get('errors',[]))
    if not checks:failures.append('No assertions: '+name)
receipt.update(assertions=count,failures=failures);write()
if failures:raise RuntimeError('\n'.join(failures))
