"""Correlated, serialized requests to an owned preset qualification profile."""
from pathlib import Path
import argparse, os, sys, time, uuid

ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('profile', type=Path)
a = p.parse_args()
out = a.profile.resolve()
assert out.parent == ROOT / 'build/mcp-qualification' and out.name.startswith('foundation-presets0853-')
assert (out / 'ready.json').exists() and not (out / 'startup-error.txt').exists()
pointer, response = out / 'dev-request.txt', out / 'dev-result.txt'
if pointer.exists():
    previous = pointer.read_text(encoding='utf-8-sig')
    state = response.read_text(encoding='utf-8-sig')
    assert previous in state and state.startswith(('SUCCESS', 'ERROR')), 'Inspect the prior request before retrying'
request = out / ('request-' + uuid.uuid4().hex + '.ms')
request.write_text(sys.stdin.read(), encoding='utf-8-sig')
pending = out / ('pointer-' + request.stem + '.tmp')
pending.write_text(request.as_posix(), encoding='utf-8-sig')
for attempt in range(100):
    try:
        os.replace(pending, pointer)
        break
    except PermissionError:
        if attempt == 99:
            raise RuntimeError('Request pointer was not published; inspect the unchanged prior request')
        time.sleep(.02)
print('Submitted', request.name, flush=True)
end = time.monotonic() + 45
while time.monotonic() < end:
    result = response.read_text(encoding='utf-8-sig') if response.exists() else ''
    if request.as_posix() in result:
        print(result)
        sys.exit(0 if result.startswith('SUCCESS') else 1)
    time.sleep(.2)
raise TimeoutError('Observe completion before retrying')
