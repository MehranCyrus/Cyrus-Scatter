"""Submit one correlated operation to an owned orientation profile."""
from pathlib import Path
import argparse,json,subprocess,sys
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('operation');p.add_argument('--label');p.add_argument('--timeout',type=int,default=90)
a=p.parse_args();host=ROOT/'build/mcp-qualification'/a.host
assert host.parent==ROOT/'build/mcp-qualification' and host.name.startswith('foundation-roadmap-orientation0830-')
command={'operation':a.operation,'label':a.label or a.operation};(host/'orientation-command.json').write_text(json.dumps(command),encoding='utf-8')
subprocess.run([sys.executable,str(ROOT/'tools/eleven_phases/request.py'),str(host),str(ROOT/'tools/orientation_0830/lifecycle.py'),'--timeout',str(a.timeout)],check=True)
record=json.loads((host/('lifecycle-'+command['label']+'.json')).read_text(encoding='utf-8'))
print(json.dumps(record,indent=2));assert record['status']=='passed'
