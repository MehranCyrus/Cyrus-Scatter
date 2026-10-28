"""Reproduce a heavy plant, then profile sync and warm source capture."""
from argparse import ArgumentParser
from pathlib import Path
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
parser = ArgumentParser()
parser.add_argument('--host', type=Path, required=True)
parser.add_argument('--case', required=True)
args = parser.parse_args()
host = args.host.resolve()
base = ROOT / 'tools/procedural_lab/interactions08741'


def run(script, extra):
    result = subprocess.run([sys.executable, str(base / script), '--host', str(host), '--case', args.case, *extra],
                            cwd=ROOT, capture_output=True, text=True)
    print(result.stdout, flush=True)
    if result.returncode:
        raise RuntimeError(result.stderr)


run('dispatch.py', [])
for kind in ('sync', 'source'):
    run('dispatch_job.py', ['--script', str(base / ('profile_' + kind + '_host.py'))])
    result = json.loads((host / (kind + '-profile-' + args.case + '.json')).read_text(encoding='utf-8'))
    if result.get('status') != 'complete':
        raise RuntimeError(kind + ' profiling failed: ' + str(result.get('error')))
