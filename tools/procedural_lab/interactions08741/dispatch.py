"""Run one serialized command in a verified owned Max test profile."""
from argparse import ArgumentParser
from pathlib import Path
import json
import time
import uuid

ROOT = Path(__file__).resolve().parents[3]
parser = ArgumentParser()
parser.add_argument('--host', type=Path, required=True)
parser.add_argument('--case', required=True)
parser.add_argument('--timeout', type=int, default=600)
args = parser.parse_args()
host = args.host.resolve()
assert host.is_relative_to(ROOT / 'build') and (host / 'launch.json').is_file()
assert args.case.replace('-', '').replace('_', '').isalnum()
ready = json.loads((host / 'ready.json').read_text(encoding='utf-8'))
assert ready.get('status') == 'ready', ready
case_dir = host / 'cases'
case_dir.mkdir(exist_ok=True)
report = case_dir / (args.case + '.json')
assert not report.exists(), 'Use a fresh host or a fresh case key'
command = host / ('case-' + args.case + '-' + uuid.uuid4().hex[:8] + '.ms')
script = ROOT / 'tools/procedural_lab/interactions08741/measure_case.py'
command.write_text('CVKey="' + args.case + '";python.ExecuteFile @"' + script.as_posix() + '"', encoding='utf-8')
(host / 'dev-request.txt').write_text(command.as_posix(), encoding='utf-8')
until = time.monotonic() + args.timeout
while True:
    reply = (host / 'dev-result.txt').read_text(encoding='utf-8') if (host / 'dev-result.txt').exists() else ''
    if command.as_posix() in reply:
        assert reply.startswith('SUCCESS'), reply
        break
    if time.monotonic() >= until:
        raise TimeoutError('The owned Max request is still pending: inspect this host before issuing another command')
    time.sleep(.25)
result = json.loads(report.read_text(encoding='utf-8'))
summary = {key: result.get(key) for key in ('key', 'name', 'status', 'phase', 'prepare_seconds', 'source_triangles', 'guides', 'contact_count', 'valid_audit_count', 'away_restored', 'error')}
summary['attempts'] = [{'status': a.get('status'), 'fit_ms': a.get('statistics', {}).get('fit_ms'), 'command_ms': a.get('command_ms'), 'audit_passed': a.get('audit', {}).get('passed')} for a in result.get('attempts', [])]
print(json.dumps(summary, indent=2))
