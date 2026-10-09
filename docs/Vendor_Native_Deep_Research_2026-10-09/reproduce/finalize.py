"""Publish receipts, not vendor disassembly or decompiler output."""
import argparse
import ast
import csv
import hashlib
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT,text=True).strip()

def main():
    p=argparse.ArgumentParser();p.add_argument('--run',type=Path,required=True);a=p.parse_args()
    run=a.run.resolve();assert run.is_relative_to(ROOT/'build') and run.is_dir()
    capture=json.loads((run/'capture.json').read_text())
    inputs=[]
    for entry in capture['inputs']:
        original=Path(entry['original']);copy=Path(entry['copy'])
        preserved=sha(original)==sha(copy)==entry['sha256'];assert preserved
        inputs.append(dict(path=str(original),sha256=entry['sha256'],bytes=entry['bytes'],preserved=preserved))
    sources=[dict(path=k,before=v,after=sha(ROOT/k),unchanged=v==sha(ROOT/k)) for k,v in capture['sources'].items()]
    exports=[];artifacts={}
    for batch in sorted(run.glob('*-batch*')):
        if not batch.is_dir():continue
        module='ForestPackLite.dlo' if batch.name.startswith('forest') else 'ScatterCore.ForScatter_Release.dll' if batch.name.startswith('core') else 'ScatterMax_Release-2027.dll'
        for row in csv.DictReader((batch/'ledger.tsv').open(),delimiter='\t'):
            if row.get('entry')=='missing':
                exports.append(dict(module=module,batch=batch.name,label=row['label'],requested=row['requested'],result='initially missing; recovered later by bounded leaf helper'));continue
            assert row['completed']=='true' and row['bytes']==row['decoded_bytes'],row
            exports.append(dict(module=module,batch=batch.name,label=row['label'],rva=hex(int(row['entry'],16)-0x180000000),bytes=int(row['bytes']),instructions=int(row['instructions']),completed=True))
        for name in ['manifest.json','ledger.tsv']:
            path=batch/name;artifacts[path.relative_to(run).as_posix()]=dict(sha256=sha(path),bytes=path.stat().st_size)
    complete=[e for e in exports if e.get('completed')];unique={(e['module'],e['rva']):e for e in complete}
    patterns=['capture.json','saved-paint-analysis.json','sdk-qualified/receipt.json','sdk-qualified/*.txt','host/saved-paint-decoded.tsv','host/launch.json','host/loaded.tsv','host/response.txt','host/cleanup.json','analysis-cleanup.json','*-save.json','*-close.json','field-*.tsv','leaf-*.txt']
    for pattern in patterns:
        for path in run.glob(pattern):
            if path.is_file():artifacts[path.relative_to(run).as_posix()]=dict(sha256=sha(path),bytes=path.stat().st_size)
    prior=ROOT/'build/vendor-surface-paint-20261009-01/host/vendor-fixture.max'
    previous=json.loads((ROOT/'docs/Vendor_Surface_Paint_Research_2026-10-09/EVIDENCE.json').read_text())
    assert sha(prior)==previous['local_artifacts']['host/vendor-fixture.max']['sha256']
    host_cleanup=json.loads((run/'host/cleanup.json').read_text(encoding='utf-8-sig'))
    analysis_cleanup=json.loads((run/'analysis-cleanup.json').read_text(encoding='utf-8-sig'))
    assert host_cleanup['stopped'] and analysis_cleanup['stopped']
    qualified=json.loads((run/'sdk-qualified/receipt.json').read_text());assert qualified['exit_code']==0
    source_inventory={}
    for folder in ['ForestPackLite2027','ChaosScatter3dsMax2027']:
        package=Path('C:/ProgramData/Autodesk/ApplicationPlugins')/folder
        paths=[p.relative_to(package).as_posix() for p in package.rglob('*') if p.is_file() and p.suffix.lower() in ['.h','.hpp','.cpp','.cc','.c','.pdb','.ms','.mse']]
        source_inventory[folder]=sorted(paths)
        assert not any(Path(p).suffix.lower() in ['.h','.hpp','.cpp','.cc','.c','.pdb'] for p in paths)
    for path in HERE.glob('reproduce/*.py'):ast.parse(path.read_text(encoding='utf-8'))
    # Relative report links must resolve; external URLs are not file paths.
    for path in HERE.glob('*.md'):
        for target in re.findall(r'\]\(([^)]+)\)',path.read_text(encoding='utf-8')):
            if '://' not in target and not target.startswith('#'):
                destination=(path.parent/target.split('#')[0]).resolve()
                if destination != HERE/'EVIDENCE.json':
                    assert destination.exists(),(path,target)
    result=dict(date='2026-10-09',completed_utc=datetime.now(timezone.utc).isoformat(),run=run.relative_to(ROOT).as_posix(),
                scope='Deeper static native research plus read-only reopening of prior owned paint fixture. No vendor implementation copied into Cyrus.',
                starting_branch=capture['branch'],starting_head=capture['head'],ending_branch=git('branch','--show-current'),ending_head=git('rev-parse','HEAD'),
                starting_status=capture['status'],ending_status=git('status','--short'),installed_inputs=inputs,source_comparisons=sources,
                concurrent_workspace_changes='Product files changed during this research; this pass edited only its research folder and docs navigation. Current source is not runtime-qualified by these results.',
                source_inventory=source_inventory,toolchain={'ghidra':'12.1.4','ghidra_mcp':'6.0.0','java':'21','max':'29.1.0.11426'},
                exports=exports,export_summary=dict(selected_records=len(exports),complete_records=len(complete),unique_functions=len(unique),unique_decoded_bytes=sum(e['bytes'] for e in unique.values()),unique_instructions=sum(e['instructions'] for e in unique.values()),not_source_coverage=True),
                sdk_witness=qualified,host_probe=json.loads((run/'saved-paint-analysis.json').read_text()),prior_owned_scene=dict(path=prior.relative_to(ROOT).as_posix(),sha256=sha(prior),preserved=True),
                cleanup=dict(max=host_cleanup,ghidra=analysis_cleanup),local_artifacts=artifacts,
                excluded=['Initial RTTI hierarchy-descriptor-as-vtable guesses: all inspected pointers non-executable.','Initial probe JSON receipt parsing failed; endpoint returns text. TSV output was valid, harness corrected.','Exploratory labels canvas_hit_path, canvas_hit_dispatch, canvas_node_map and stroke_layer_query do not describe actual roles; corrections in CODE_MAP.md.','No placement-cache hit rates, timings, FPS or buffer-upload counts measured.'],
                official_sources=[dict(url='https://docs.itoosoft.com/forestpack/forest-plugin/'+name,rechecked='2026-10-09') for name in ['areas','surfaces','animation']]+[dict(url='https://documentation.chaos.com/space/CRMAX/124525180/Chaos%20Scatter',rechecked='2026-10-09',limitation='Web text extraction returned zero lines in this pass; prior report remains the documented source.')])
    (HERE/'EVIDENCE.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(dict(exports=result['export_summary'],installed_preserved=len(inputs),source_unchanged=sum(s['unchanged'] for s in sources),source_changed=[s['path'] for s in sources if not s['unchanged']],scene_preserved=True,owned_processes_closed=True),indent=2))

if __name__=='__main__':main()
