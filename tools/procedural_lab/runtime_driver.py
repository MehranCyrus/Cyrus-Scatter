"""Private Max fixture transport; never connects to an artist session or MCP tool."""
import argparse
import json
from pathlib import Path
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]


def run_script(folder, script, timeout=45):
    folder = Path(folder).resolve()
    if not folder.is_relative_to(ROOT / 'build/mcp-qualification'):
        raise ValueError('A private qualification folder is required')
    metadata = json.loads((folder / 'launch.json').read_text())
    if Path(metadata['output']).resolve() != folder:
        raise ValueError('Fixture launch record does not match')
    # The host fixture may reset its disposable scene during startup. Sending
    # an acceptance script before ready could be followed by that late reset.
    ready_deadline = time.monotonic() + timeout
    while not (folder / 'ready.json').exists():
        if time.monotonic() >= ready_deadline:
            raise TimeoutError('Private Max host has not finished startup')
        time.sleep(.1)
    name = 'probe-' + uuid.uuid4().hex + '.ms'
    path = folder / name
    path.write_text('(\n' + script + '\n)\n', encoding='utf-8')
    request = folder / 'dev-request.txt'
    temporary = request.with_suffix('.tmp')
    temporary.write_text(path.as_posix(), encoding='utf-8')
    temporary.replace(request)
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        result = folder / 'dev-result.txt'
        if result.exists():
            text = result.read_text(encoding='utf-8-sig')
            # Error responses from the fixture do not name the request. Waiting
            # for a newer mtime prevents attributing an earlier failure to this run.
            if result.stat().st_mtime_ns >= request.stat().st_mtime_ns:
                return text
        time.sleep(.1)
    raise TimeoutError(f'Private Max fixture did not complete: {name}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('folder', type=Path)
    parser.add_argument('script', type=Path)
    parser.add_argument('--timeout', type=float, default=45)
    args = parser.parse_args()
    result = run_script(args.folder, args.script.read_text(encoding='utf-8-sig'), timeout=args.timeout)
    print(result)
    raise SystemExit(0 if result.startswith('SUCCESS ') else 1)
