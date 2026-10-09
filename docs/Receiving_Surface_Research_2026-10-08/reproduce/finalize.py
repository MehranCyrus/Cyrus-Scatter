"""Summarize owned receipts; copy hashes and small numeric evidence, not vendor listings."""
import argparse,csv,hashlib,json,re
from collections import Counter
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    p=argparse.ArgumentParser();p.add_argument('--run',type=Path,required=True);a=p.parse_args();run=a.run.resolve()
    if not run.is_relative_to(ROOT/'build'): raise ValueError('Owned ignored receipts only')
    capture=json.loads((run/'capture.json').read_text())
    data=dict(date='2026-10-08',run=str(run),source_head=capture['head'],source_branch=capture['branch'],inputs=capture['inputs'],sources=capture['sources'],host_launch=json.loads((run/'host/launch.json').read_text()),
        max_version=(run/'host/max-version.txt').read_text(encoding='utf-8-sig'),campaign_script_sha256=sha(Path(__file__).with_name('cyrus_surfaces.ms')),
        timing_scope='One timestamp around evaluateGroups, before TSV export. Aggregate synchronous host call, not stage timing, GPU upload or FPS.',
        exact_comparisons=list(csv.DictReader((run/'host/exact-comparisons.tsv').read_text(encoding='utf-8-sig').splitlines(),delimiter='\t')),captures=[])
    for path in sorted((run/'host').glob('*.tsv')):
        lines=path.read_text(encoding='utf-8-sig').splitlines()
        if not lines or not lines[0].startswith('milliseconds '): continue
        header=lines[0];m=re.match(r'milliseconds (\d+) count (\d+) receivers (\d+) area ([\d.]+)d0 statistics (.*)',header)
        if not m: raise ValueError(header)
        models=Counter(line.split('\t')[1] for line in lines[1:])
        data['captures'].append(dict(label=path.stem,milliseconds=int(m[1]),count=int(m[2]),receiver_count=int(m[3]),area_system_units_squared=float(m[4]),statistics=m[5],model_counts=dict(models),sha256=sha(path)))
    data['paint_guard']=(run/'host/paint-guard.txt').read_text(encoding='utf-8-sig')
    data['edit_guard']=(run/'host/edit-guard.txt').read_text(encoding='utf-8-sig')
    data['vendor_api_versions']=(run/'host/vendor-api-versions.txt').read_text(encoding='utf-8-sig')
    data['file_versions']=json.loads((run/'versions.json').read_text(encoding='utf-8-sig'))
    data['official_forest_sources']=json.loads((run/'official-docs/sources.json').read_text(encoding='utf-8-sig'))
    if (run/'cleanup.json').exists(): data['cleanup']=json.loads((run/'cleanup.json').read_text(encoding='utf-8-sig'))
    data['research_scripts']={p.name:sha(p) for p in sorted(Path(__file__).parent.glob('*')) if p.is_file()}
    core=ROOT/'build/receiving-surface-research-20261008-02'
    data['chaos_core_inspection']=dict(run=str(core),project=str(core/'projects/ReceivingSurfaceCore.gpr'),
        binary_sha256='069ababd0dbc09218928f24d5bdc860509b237f34af703581e3fd78ed5d3cf86',
        selections=[json.loads((core/name).read_text(encoding='utf-8-sig')) for name in ['core-selection.json','preparation-selection.json']],
        ledgers={name:(core/name/'ledger.tsv').read_text() for name in ['core-selected','core-preparation']},
        listings_sha256={str(path.relative_to(core)):sha(path) for folder in ['core-selected','core-preparation'] for path in sorted((core/folder).glob('*.c'))})
    data['vendor_host_attempts']=[dict(run='build/receiving-surface-research-20261008-02',result='API inventory and defaults succeeded; explicit Chaos FpInterface.update(interval 0 0,0) stayed RUNNING; no placement data.'),
        dict(run='build/receiving-surface-research-20261008-03',result='RUNNING at Forest receiving-surface configuration checkpoint; checkpoint covers two setters; no placement data.')]
    data['preservation']={n:sha(ROOT/n)==value for n,value in capture['sources'].items()}
    data['installed_inputs_preserved']={item['original']:sha(Path(item['original']))==item['sha256'] for item in capture['inputs']}
    destination=Path(__file__).parents[1]/'EVIDENCE.json';destination.write_text(json.dumps(data,indent=2)+'\n')
    print(json.dumps(dict(captures=len(data['captures']),models={r['label']:r['model_counts'] for r in data['captures'][:4]},sources_unchanged=all(data['preservation'].values()),installed_unchanged=all(data['installed_inputs_preserved'].values()))))
if __name__=='__main__': main()
