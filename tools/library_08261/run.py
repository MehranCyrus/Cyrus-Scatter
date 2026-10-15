"""Submit one owned operation and require its correlated qualification result."""
from pathlib import Path
import argparse,json,subprocess,sys
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('operation');p.add_argument('--label');p.add_argument('--count',type=int);p.add_argument('--demo');p.add_argument('--source-host');p.add_argument('--fixture',choices=('qualification','demos','demo_verify','demo_apply','layout'),default='qualification');p.add_argument('--timeout',type=int,default=120)
a=p.parse_args();host=(ROOT/'build/mcp-qualification'/a.host).resolve()
assert host.parent==ROOT/'build/mcp-qualification' and host.name.startswith('foundation-roadmap-library08261-')
command={'operation':a.operation,'label':a.label or a.operation}
if a.count is not None:command['count']=a.count
if a.demo:command['demo']=a.demo
if a.source_host:command['source_host']=a.source_host
(host/'command.json').write_text(json.dumps(command),encoding='utf-8')
subprocess.run([sys.executable,str(ROOT/'tools/eleven_phases/request.py'),str(host),str(ROOT/'tools/library_08261'/(a.fixture+('.ms' if a.fixture=='demo_apply' else '.py'))),'--timeout',str(a.timeout)],check=True)
if a.fixture=='demo_apply':
 text=(host/('demo-'+a.demo+'-apply.txt')).read_text(encoding='utf-8-sig');print(text)
 assert 'REQUEST: '+(host/'dev-request.txt').read_text(encoding='utf-8-sig') in text and 'DEMO: '+a.demo+'\n' in text
 assert 'PASS: complete' in text and 'FAIL:' not in text and 'ERROR:' not in text
 sys.exit(0)
name=('demo-'+a.demo if a.fixture=='demos' else 'demo-'+a.demo+'-'+a.operation if a.fixture=='demo_verify' else ('layout-' if a.fixture=='layout' else 'qualification-')+command['label'])+'.json'
record=json.loads((host/name).read_text(encoding='utf-8'));print(json.dumps({k:v for k,v in record.items() if k not in ('baseline_rows','rows','checks','baseline_counters','controls')},indent=2))
assert record['status']=='passed',name
