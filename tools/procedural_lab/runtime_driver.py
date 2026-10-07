"""Private Max fixture transport; never connects to an artist session or MCP tool."""
import argparse
from contextlib import contextmanager
import json
import msvcrt
from pathlib import Path
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]


@contextmanager
def _single_request(folder, timeout):
    # The fixture intentionally has one request slot. Serialize independent
    # diagnostic clients so a second caller cannot overwrite an in-flight file.
    with (folder / 'dev-client.lock').open('a+b') as stream:
        if stream.tell()==0:
            stream.write(b'\0');stream.flush()
        deadline=time.monotonic()+timeout
        while True:
            stream.seek(0)
            try:
                msvcrt.locking(stream.fileno(),msvcrt.LK_NBLCK,1)
                break
            except OSError:
                if time.monotonic()>=deadline:raise TimeoutError('Private fixture already has an active request')
                time.sleep(.1)
        try:yield
        finally:
            stream.seek(0);msvcrt.locking(stream.fileno(),msvcrt.LK_UNLCK,1)


def run_script(folder, script, timeout=45):
    folder = Path(folder).resolve()
    if not folder.is_relative_to(ROOT / 'build/mcp-qualification'):
        raise ValueError('A private qualification folder is required')
    metadata = json.loads((folder / 'launch.json').read_text())
    if Path(metadata['output']).resolve() != folder:
        raise ValueError('Fixture launch record does not match')
    with _single_request(folder,timeout):
        return _run_single(folder,script,timeout)


def _run_single(folder,script,timeout):
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
            # Current errors include the request path. Older private hosts only
            # expose a timestamp; the client lock still guarantees one caller.
            matching=text.startswith('SUCCESS '+path.as_posix()) or ('REQUEST: '+path.as_posix()) in text
            legacy_error=text.startswith('ERROR ') and 'REQUEST: ' not in text
            if result.stat().st_mtime_ns >= request.stat().st_mtime_ns and (matching or legacy_error):
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
