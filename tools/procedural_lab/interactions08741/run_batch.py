"""Run distinct real models serially in an owned Max host; never target artist sessions."""
from argparse import ArgumentParser
from pathlib import Path
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
parser = ArgumentParser()
parser.add_argument('--host', type=Path, required=True)
parser.add_argument('--cases', nargs='+', required=True)
args = parser.parse_args()
host = args.host.resolve()
assert host.is_relative_to(ROOT / 'build') and (host/'launch.json').is_file()
runner = ROOT/'tools/procedural_lab/interactions08741/dispatch.py'
for case in args.cases:
    process = subprocess.run([sys.executable, str(runner), '--host', str(host), '--case', case, '--timeout', '600'], cwd=ROOT, capture_output=True, text=True)
    if process.returncode:
        print(case, 'DISPATCH ERROR; host must be inspected:', (process.stderr or process.stdout)[-1000:], flush=True)
        raise SystemExit(process.returncode)
    result = json.loads((host/'cases'/(case+'.json')).read_text(encoding='utf-8'))
    print(case, result.get('name'), result['status'], 'contacts', result.get('contact_count', 0), 'audits', result.get('valid_audit_count', 0), 'phase', result.get('phase'), flush=True)
