"""Serialize event-loop steps; never retry a request whose outcome is unknown."""
from pathlib import Path
import argparse,json,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);p.add_argument('operations',nargs='+');a=p.parse_args()
folder=a.profile.resolve();assert folder.parent==ROOT/'build/mcp-qualification' and folder.name.startswith('foundation-roadmap-grid0850-')
for index,op in enumerate(a.operations):
 label=op+'-'+str(time.time_ns())
 (folder/'grid-command.json').write_text(json.dumps({'operation':op,'label':label}),encoding='utf-8')
 subprocess.run([sys.executable,str(ROOT/'tools/eleven_phases/request.py'),str(folder),str(ROOT/'tools/grid_0850/lifecycle.py'),'--timeout','90'],cwd=ROOT,check=True)
 result=json.loads((folder/('lifecycle-'+label+'.json')).read_text(encoding='utf-8'));assert result['status']=='passed',result
 print(op,': passed',flush=True)
 time.sleep(1.5)
