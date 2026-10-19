"""Serialize the frozen workflow, examples, Save and failure campaigns per host."""
from pathlib import Path
import argparse,json,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'));from run_generation import ready
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('--library',required=True,type=Path);a=p.parse_args();assert a.host.startswith('library-surface0861-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host);results=[]
for script,extra in [('run_workflow.py',[]),('run_examples.py',['--library',str(a.library.resolve())]),('run_save.py',['--library',str(a.library.resolve())]),('run_extra.py',[])]:
 start=time.monotonic();result=subprocess.run([sys.executable,str(ROOT/'tools/library_0861'/script),a.host,*extra],capture_output=True,text=True)
 (host/(script+'.log')).write_text(result.stdout+result.stderr,encoding='utf-8')
 results.append({'script':script,'exit_code':result.returncode,'seconds':time.monotonic()-start});(host/'final-campaign.json').write_text(json.dumps(results,indent=2)+'\n')
 print(script,result.returncode,flush=True)
 if result.returncode:print(result.stdout[-3000:]+result.stderr,flush=True);raise SystemExit(result.returncode)
print('FINAL MATCHED HOST CAMPAIGN PASSED',flush=True)
