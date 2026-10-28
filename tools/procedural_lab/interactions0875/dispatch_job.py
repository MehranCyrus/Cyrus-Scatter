"""Send one diagnostic script to an idle, explicitly owned Max fixture host."""
from argparse import ArgumentParser
from pathlib import Path
import json
import time
import uuid

ROOT = Path(__file__).resolve().parents[3]
parser = ArgumentParser()
parser.add_argument('--host', required=True, type=Path)
parser.add_argument('--script', required=True, type=Path)
parser.add_argument('--case', required=True)
parser.add_argument('--direction', type=int, default=1)
parser.add_argument('--timeout', type=int, default=600)
args = parser.parse_args()
host = args.host.resolve()
script = args.script.resolve()
if not host.is_relative_to(ROOT / 'build') or not (host / 'launch.json').is_file():
    raise ValueError('An explicitly launched owned host is required')
if not script.is_relative_to(ROOT / 'tools' / 'procedural_lab' / 'interactions0875') or not script.is_file():
    raise ValueError('The diagnostic script must be a campaign-owned file')
if not args.case.replace('-', '').replace('_', '').isalnum() or args.direction not in range(1, 9):
    raise ValueError('Invalid recorded case or direction')
assert json.loads((host / 'ready.json').read_text(encoding='utf-8')).get('status') == 'ready'
request, response = host / 'dev-request.txt', host / 'dev-result.txt'
if request.exists():
    previous = request.read_text(encoding='utf-8')
    reply = response.read_text(encoding='utf-8') if response.exists() else ''
    if previous and previous not in reply:
        raise RuntimeError('An earlier request is pending; inspect the host before sending another')
command = host / ('job-' + uuid.uuid4().hex + '.ms')
command.write_text('global CVProfileCase="' + args.case + '";global CVCaptureDirection=' + str(args.direction)
                   + (';fileIn @"' if script.suffix=='.ms' else ';python.ExecuteFile @"') + script.as_posix() + '"', encoding='utf-8')
if args.case in ('undo-native','redo-native') and script.suffix=='.ms':command.write_text('max undo' if args.case=='undo-native' else 'max redo',encoding='utf-8')
request.write_text(command.as_posix(), encoding='utf-8')
until = time.monotonic() + args.timeout
while time.monotonic() < until:
    reply = response.read_text(encoding='utf-8') if response.exists() else ''
    if command.as_posix() in reply:
        if not reply.startswith('SUCCESS'):
            raise RuntimeError(reply)
        print(reply)
        break
    time.sleep(.25)
else:
    raise TimeoutError('The owned Max request is still pending; inspect the host before sending another')
