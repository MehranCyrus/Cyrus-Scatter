"""Verify preserved inputs and publish metadata, never vendor code or listings."""
import argparse
import csv
import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--run', type=Path, required=True)
    args = parser.parse_args()
    run = args.run.resolve()
    if not run.is_relative_to(Path.cwd()/'build'):
        raise ValueError('Expected an owned run under build/')
    snapshot = json.loads((run/'start-snapshot.json').read_text())
    original_checks = [dict(path=x['path'], sha256=digest(x['path']),
        original_unchanged=digest(x['path']) == x['sha256'],
        copy_unchanged=digest(x['copy']) == x['copy_sha256']) for x in snapshot['originals']]
    source_checks = [dict(path=p,sha256=digest(p),unchanged=digest(p)==h)
        for p,h in snapshot['source_hashes'].items()]
    records = []
    for batch in sorted(run.glob('batch*')):
        with (batch/'ledger.tsv').open(encoding='utf-8', newline='') as stream:
            records.extend(dict(batch=batch.name,**row) for row in csv.DictReader(stream,delimiter='\t'))
    completed = [r for r in records if r['completed']=='true']
    receipts = json.loads((run/'sdk-witness-v2/receipt.json').read_text())
    sources = []
    for folder in ['official-docs','official-docs-supplement']:
        sources.extend(json.loads((run/folder/'sources.json').read_text()))
    git = {name:subprocess.check_output(['git',*command],text=True).strip() for name,command in {
        'head':['rev-parse','HEAD'], 'branch':['branch','--show-current'],
        'status':['status','--short']}.items()}
    modules = json.loads((run/'module-summary.json').read_text())
    receipt = dict(completed_utc=datetime.now(timezone.utc).isoformat(),run=str(run),
        baseline_git=snapshot['git'],final_git=git,original_checks=original_checks,
        source_checks=source_checks,modules=[{k:m[k] for k in ['name','bytes','sha256','image_base','clr_directory']} for m in modules],
        selected_records=records,selected_count=len(records),decompiled_count=len(completed),
        decoded_coverage_matches=sum(int(r['bytes'])==int(r['decoded_bytes']) for r in completed),
        sdk_compile_records=[dict(name=r['name'],exit_code=r['exit_code'],log_sha256=r['log_sha256']) for r in receipts['records']],
        linked=False,executed=False,official_sources=sources,
        save=json.loads((run/'save-response.json').read_text()),
        close=json.loads((run/'close-response.json').read_text()),
        backend_stop=json.loads((run/'server-stop.json').read_text(encoding='utf-8-sig')))
    target = Path(__file__).resolve().parents[1]/'EVIDENCE.json'
    if target.exists(): raise ValueError('Preserve existing evidence receipt')
    target.write_text(json.dumps(receipt,indent=2),encoding='utf-8')
    assert all(r['original_unchanged'] and r['copy_unchanged'] for r in original_checks)
    assert all(r['unchanged'] for r in source_checks)
    assert all(r['exit_code']==0 for r in receipts['records'])
    assert receipt['save']['success'] and receipt['close']['success']
    assert receipt['decoded_coverage_matches']==len(completed)
    print(json.dumps(dict(originals_unchanged=len(original_checks),sources_unchanged=len(source_checks),
        selected=len(records),decompiled=len(completed),sdk_compiles=len(receipts['records']),receipt=str(target))))


if __name__ == '__main__':
    main()
