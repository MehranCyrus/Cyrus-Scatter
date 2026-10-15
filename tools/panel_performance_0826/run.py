"""Run serial, correlated qualification requests in an owned Max host."""
import argparse,json,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('commands',help='JSON array of operation objects')
a=p.parse_args();host=ROOT/'build/mcp-qualification'/a.host
assert host.parent==ROOT/'build/mcp-qualification' and host.name.startswith('foundation-roadmap-panel0826-')
for command in json.loads(a.commands):
    layout=command.get('operation')=='layout'
    native=command.get('operation')=='undo_native'
    script='undo.ms' if native else 'layout_audit.py' if layout else 'qualification.py'
    (host/('layout-command.json' if layout else 'panel-command.json')).write_text(json.dumps(command))
    subprocess.run([sys.executable,str(ROOT/'tools/eleven_phases/request.py'),str(host),str(ROOT/'tools/panel_performance_0826'/script),'--timeout','240'],check=True)
    if not native:
        receipt=host/(('layout-' if layout else 'qualification-')+command.get('label',command['operation'])+'.json')
        result=json.loads(receipt.read_text())
        assert result['status']==('prepared' if command.get('prepare',False) else 'passed'),(str(receipt),result.get('error'),result.get('clipped_count'),result.get('overlap_count'))
        print(receipt.name+': '+result['status'],flush=True)
