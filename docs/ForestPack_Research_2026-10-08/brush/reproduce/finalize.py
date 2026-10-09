"""Write a metadata-only brush receipt and verify preserved inputs/source."""
import argparse,ast,csv,hashlib,json,re,subprocess
from datetime import datetime,timezone
from pathlib import Path

def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def main():
 p=argparse.ArgumentParser();p.add_argument('--run',type=Path,required=True);a=p.parse_args();run=a.run.resolve()
 if not run.is_relative_to(Path.cwd()/'build'):raise ValueError('Use owned run')
 folder=Path(__file__).resolve().parents[1];target=folder/'EVIDENCE.json'
 if target.exists():raise ValueError('Preserve existing receipt')
 start=json.loads((run/'start-snapshot.json').read_text());checks=[]
 for r in start['originals']:
  checks.append(dict(path=r['path'],sha256=digest(r['path']),original_unchanged=digest(r['path'])==r['sha256'],copy_unchanged=digest(r['copy'])==r['copy_sha256']))
 source_checks=[dict(path=s,sha256=digest(s),unchanged=digest(s)==h) for s,h in start['source_hashes'].items()]
 brush_sources=[]
 for path in ['AminScatter/include/brush.h','AminScatter/src/brush.cpp','AminScatter/src/brush_host.cpp']:
  canonical=subprocess.check_output(['git','hash-object','--path',path,path],text=True).strip()
  baseline=subprocess.check_output(['git','rev-parse',start['git']['head']+':'+path],text=True).strip()
  brush_sources.append(dict(path=path,sha256=digest(path),git_blob=canonical,baseline_git_blob=baseline,unchanged_from_captured_HEAD=canonical==baseline))
 records=[];incomplete=[]
 for batch in sorted(run.glob('batch*')):
  if not (batch/'ledger.tsv').exists():incomplete.append(dict(batch=batch.name,response=(batch/'response.json').read_text()));continue
  with (batch/'ledger.tsv').open(encoding='utf-8',newline='') as f:records.extend(dict(batch=batch.name,**r) for r in csv.DictReader(f,delimiter='\t'))
 for path in folder.glob('reproduce/*.py'):ast.parse(path.read_text(encoding='utf-8'))
 missing=[]
 for path in folder.glob('*.md'):
  for link in re.findall(r'\]\(([^)]+)\)',path.read_text(encoding='utf-8')):
   if '://' not in link and link!='EVIDENCE.json' and not (path.parent/link.split('#')[0]).exists():missing.append((str(path),link))
 assert not missing,missing
 assert subprocess.run(['git','diff','--check'],capture_output=True).returncode==0
 assert subprocess.run(['git','check-ignore',str(run/'inputs/Contents/plugins/2027/ForestPackLite.dlo')],capture_output=True).returncode==0
 assert all(c['original_unchanged'] and c['copy_unchanged'] for c in checks)
 # Concurrent UI work may change repository state; record it rather than reverting it.
 assert all(c['unchanged_from_captured_HEAD'] for c in brush_sources)
 assert all(c['unchanged'] for c in source_checks if c['path'] not in ['AminScatter/tools/ui/templates/unified-core.ms','AminScatter/scripts/AminScatterObject.ms'])
 assert all(r['completed']=='true' and int(r['bytes'])==int(r['decoded_bytes']) for r in records)
 sdk=json.loads((run/'sdk-witness/receipt.json').read_text());assert all(r['exit_code']==0 for r in sdk['records'])
 final_git={name:subprocess.check_output(['git',*cmd],text=True).strip() for name,cmd in {'head':['rev-parse','HEAD'],'branch':['branch','--show-current'],'status':['status','--short']}.items()}
 metadata=dict(completed_utc=datetime.now(timezone.utc).isoformat(),run=str(run),baseline_git=start['git'],final_git=final_git,original_checks=checks,
  source_checks=source_checks,brush_source_checks=brush_sources,selected_records=records,selected_records_count=len(records),
  unique_entry_count=len({r['entry'] for r in records}),incomplete_attempts=incomplete,
  analysis=json.loads((run/'analysis-response.json').read_text()),sdk=sdk,
  official_sources=json.loads((run/'official-docs/sources.json').read_text()),
  constants=json.loads((run/'brush-constants.json').read_text()),
  protocol_attempts={name:json.loads((run/name).read_text()) for name in ['open-response.json','open-program-response.json','load-program-response.json']},
  save=json.loads((run/'save-response.json').read_text()),close=json.loads((run/'close-response.json').read_text()),
  stop=json.loads((run/'server-stop.json').read_text(encoding='utf-8-sig')),
  validation=dict(helper_syntax='pass',local_report_links='pass',diff_whitespace='pass',raw_vendor_inputs_ignored='pass'),
  target_executed_by_this_research=False,max_launched_by_this_research=False,product_implementation_changed_by_this_research=False)
 assert metadata['save']['success'] and metadata['close']['success']
 target.write_text(json.dumps(metadata,indent=2),encoding='utf-8')
 print(json.dumps(dict(originals_unchanged=len(checks),sources_unchanged=sum(c['unchanged'] for c in source_checks),brush_sources_match_captured_HEAD=len(brush_sources),
  selected=len(records),unique_entries=metadata['unique_entry_count'],sdk_compiles=len(sdk['records']),validation=metadata['validation'])))

if __name__=='__main__':main()
