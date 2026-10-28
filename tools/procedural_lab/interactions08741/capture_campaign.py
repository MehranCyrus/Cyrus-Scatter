"""Serially reproduce baseline contacts, profile sync and freeze regressions."""
from argparse import ArgumentParser
from pathlib import Path
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
parser = ArgumentParser()
parser.add_argument('--host', type=Path, required=True)
args = parser.parse_args()
host = args.host.resolve()
runner = ROOT / 'tools/procedural_lab/interactions08741/dispatch.py'
job = ROOT / 'tools/procedural_lab/interactions08741/dispatch_job.py'
profile = ROOT / 'tools/procedural_lab/interactions08741/profile_sync_host.py'
capture = ROOT / 'tools/procedural_lab/interactions08741/capture_replay_host.py'


def run(command):
    process = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    if process.returncode:
        raise RuntimeError((process.stdout + '\n' + process.stderr)[-4000:])
    print(process.stdout.strip(), flush=True)


for case, kind, direction in [('S04-profile', 'profile', 1),
                              ('S02-regression', 'capture', 1),
                              ('A062-regression', 'capture', 1),
                              ('S06-regression', 'capture', 2)]:
    print('Reproducing', case, flush=True)
    run([sys.executable, str(runner), '--host', str(host), '--case', case])
    value = json.loads((host / 'cases' / (case + '.json')).read_text(encoding='utf-8'))
    if value.get('phase') != 'complete' or value['attempts'][direction-1].get('status') != 'contact':
        raise RuntimeError('The intended recorded contact could not be reproduced: ' + case)
    run([sys.executable, str(job), '--host', str(host), '--script', str(profile if kind == 'profile' else capture),
         '--case', case, '--direction', str(direction)])
    if kind == 'profile':
        observed = json.loads((host / ('sync-profile-' + case + '.json')).read_text(encoding='utf-8'))
        if observed.get('status') != 'complete':
            raise RuntimeError('The instrumented sync failed: ' + str(observed.get('error')))
    elif not (host / 'replays' / (case + '-direction' + str(direction)) / 'fixture.json').is_file():
        raise RuntimeError('The native replay fixture was not saved')
