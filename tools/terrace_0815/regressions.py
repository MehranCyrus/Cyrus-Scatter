"""Replay current-compatible established witnesses in an explicitly owned host."""
from pathlib import Path
import sys,json,hashlib,argparse
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/procedural_lab'))
from runtime_driver import run_script
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);args=p.parse_args();OUT=args.profile.resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-terrace0815-candidate')
data={'adapters':[],'steps':[]};report=OUT/'regressions-0815.json'
for name in ['regressions-0815.json','preview-oracle.json','retained-results.json','workflow.json','invalidation0792.json','publication-results.json']:
    path=OUT/name
    if path.exists():
        i=1
        while path.with_name(path.stem+'-previous-%02d.json'%i).exists():i+=1
        path.with_name(path.stem+'-previous-%02d.json'%i).write_bytes(path.read_bytes())
def save():report.write_text(json.dumps(data,indent=2)+'\n')
def adapt(relative,name=None):
    src=ROOT/relative;code=src.read_text(encoding='utf-8-sig').replace("ROOT = Path(__file__).resolve().parents[2]",'ROOT=Path('+repr(ROOT.as_posix())+')').replace("ROOT=Path(__file__).resolve().parents[2]",'ROOT=Path('+repr(ROOT.as_posix())+')')
    code=code.replace("startswith('refine0795-')","startswith('foundation-terrace0815-candidate')").replace("startswith('refine0791-layer0792-')","startswith('foundation-terrace0815-candidate')")
    target=OUT/(name or src.name);target.write_text(code,encoding='utf-8')
    data['adapters'].append({'source':relative,'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'adapter_sha256':hashlib.sha256(target.read_bytes()).hexdigest()});save();return target
adapt('tools/refine0795/common.py')
paths=[ROOT/'tools/terrace_0815/preview_oracle.py',ROOT/'tools/foundation_validation/retained.py',adapt('tools/refine0795/workflow.py'),adapt('tools/refine0792/invalidation.py'),ROOT/'tools/foundation_validation/publication.py']
for path in paths:
    result=run_script(OUT,'python.ExecuteFile @"'+path.as_posix()+'"',timeout=600)
    data['steps'].append({'file':path.as_posix(),'result':result});save();print(path.name+': '+result[:100],flush=True)
    if not result.startswith('SUCCESS '):raise RuntimeError(result)
failures=[]
for file in ['preview-oracle.json','retained-results.json','workflow.json','invalidation0792.json','publication-results.json']:
    value=json.loads((OUT/file).read_text());checks=value.get('checks',value.get('assertions',[]))
    failures.extend([file+': '+str(v) for v in checks if not v['passed']]);failures.extend(value.get('errors',[]))
data['failures']=failures;data['complete']=not failures;save()
result=run_script(OUT,'resetMaxFile #noPrompt;fileIn @"'+(ROOT/'AminScatter/scripts/AminScatterObject.ms').as_posix()+'"',timeout=120)
if failures:raise RuntimeError('\n'.join(failures))
