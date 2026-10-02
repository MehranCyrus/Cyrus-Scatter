"""Submit one recipe at a time to a named private Max session."""
from pathlib import Path
import argparse
import time
import uuid
from build import BASE

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--run', required=True)
    parser.add_argument('--timeout', type=float, default=240)
    parser.add_argument('script', type=Path)
    args = parser.parse_args()
    output = (BASE / args.run).resolve()
    if output.parent != BASE.resolve() or not (output / 'transport-ready.txt').exists():
        raise SystemExit('No matching private transport')
    target = output / f'recipe-{args.script.stem}-{uuid.uuid4().hex[:8]}.ms'
    target.write_bytes(args.script.read_bytes())
    command = target.as_posix()
    temporary = output / 'request-next.txt'
    temporary.write_text(command, encoding='utf-8')
    temporary.replace(output / 'request.txt')
    deadline = time.monotonic() + args.timeout
    while time.monotonic() < deadline:
        response_file = output / 'response.txt'
        response = response_file.read_text(encoding='utf-8-sig') if response_file.exists() else ''
        if command in response and response.startswith(('SUCCESS', 'ERROR')):
            print(response)
            if response.startswith('ERROR'):
                raise SystemExit(1)
            return
        time.sleep(.25)
    raise SystemExit(f'Timeout; inspect {output} and Max before submitting another recipe')

if __name__ == '__main__':
    main()
