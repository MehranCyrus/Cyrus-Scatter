"""Submit one owned Python/MAXScript fixture; timeout is observation only."""
from pathlib import Path
import argparse
import json
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('folder', type=Path)
p.add_argument('fixture', type=Path)
p.add_argument('--timeout', type=float, default=60)
a = p.parse_args()
folder = a.folder.resolve()
fixture = a.fixture.resolve()
assert folder.parent == ROOT / 'build/mcp-qualification'
assert folder.name.startswith(('foundation-roadmap-', 'foundation-viewport0817-phase01-'))
assert fixture.is_relative_to(ROOT / 'tools') and fixture.suffix in ('.py', '.ms')
metadata = json.loads((folder / 'launch.json').read_text())
assert Path(metadata['output']).resolve() == folder and metadata['development_transport']
assert (folder / 'ready.json').exists()
pending_file = folder / 'dev-request.txt'
result_file = folder / 'dev-result.txt'
if pending_file.exists():
    previous = pending_file.read_text(encoding='utf-8-sig')
    previous_result = result_file.read_text(encoding='utf-8-sig') if result_file.exists() else ''
    assert previous_result == 'SUCCESS ' + previous or (previous_result.startswith('ERROR ') and previous in previous_result), \
        'Previous request has no correlated completion; inspect it before submitting another'
request = folder / ('request-' + uuid.uuid4().hex + '.ms')
command = 'python.ExecuteFile' if fixture.suffix == '.py' else 'fileIn'
request.write_text(command + ' @"' + fixture.as_posix() + '"\n', encoding='utf-8-sig')
pending_file.write_text(request.as_posix(), encoding='utf-8-sig')
print('Submitted ' + request.as_posix(), flush=True)
deadline = time.monotonic() + a.timeout
while time.monotonic() < deadline:
    result = folder / 'dev-result.txt'
    text = result.read_text(encoding='utf-8-sig') if result.exists() else ''
    if text == 'SUCCESS ' + request.as_posix():
        print(text, flush=True)
        break
    if text.startswith('ERROR ') and request.as_posix() in text:
        raise RuntimeError(text)
    time.sleep(.25)
else:
    raise TimeoutError('Request remains owned by this host; inspect progress before retrying')
