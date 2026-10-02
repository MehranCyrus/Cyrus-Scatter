"""Read-only source audit and isolated validation for the 2026-10-01 research.

This helper never installs a plugin or drives an existing Max process. Build
outputs belong in build/codebase-research-2026-10-01; evidence stays beside it.
"""
from pathlib import Path
import argparse
import datetime as dt
import hashlib
import json
import os
import re
import subprocess
import sys

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
EVIDENCE = HERE / 'evidence'
SCRATCH = ROOT / 'build' / 'codebase-research-2026-10-01'
RUN_TAG = os.environ.get('CYRUS_RESEARCH_RUN', '')
if RUN_TAG:
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]{0,63}', RUN_TAG):
        raise ValueError('CYRUS_RESEARCH_RUN must be a short alphanumeric/dash/underscore tag')
    EVIDENCE = EVIDENCE / 'reruns' / RUN_TAG
    SCRATCH = SCRATCH / RUN_TAG

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def record(name, value):
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    (EVIDENCE / name).write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')

def stamp():
    return dt.datetime.now(dt.timezone.utc).isoformat()

def read_file(path, start=1, end=None):
    path = Path(path)
    if not path.is_absolute():
        path = ROOT / path
    lines = path.read_text(encoding='utf-8-sig', errors='replace').splitlines()
    end = min(end or len(lines), len(lines))
    info = dict(path=str(path), start=start, end=end, total_lines=len(lines),
                sha256=digest(path), read_at_utc=stamp())
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    with (EVIDENCE / 'read-coverage.jsonl').open('a', encoding='utf-8') as out:
        out.write(json.dumps(info) + '\n')
    print(json.dumps(info))
    for n in range(start, end + 1):
        print(f'{n}: {lines[n-1]}')

def run_logged(label, argv, env=None, cwd=ROOT):
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    started = stamp()
    p = subprocess.run([str(x) for x in argv], cwd=cwd, env=env,
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (EVIDENCE / f'{label}.txt').write_bytes(p.stdout)
    record(f'{label}.json', dict(started_utc=started, finished_utc=stamp(),
           cwd=str(cwd), argv=[str(x) for x in argv], returncode=p.returncode,
           output=f'{label}.txt'))
    print(p.stdout.decode('utf-8', errors='replace'))
    if p.returncode:
        raise RuntimeError(f'{label}: exit {p.returncode}')

def snapshot():
    paths = []
    for top in ['AminScatter/src', 'AminScatter/include', 'AminScatter/tests',
                'AminScatter/tools', 'AminScatter/scripts', 'CyrusSurfaceAnalyzer/src',
                'CyrusSurfaceAnalyzer/tests', 'CyrusSurfaceAnalyzer/scripts', 'cmake', 'tools']:
        paths.extend(p for p in (ROOT / top).rglob('*') if p.is_file()
                     and '__pycache__' not in p.parts)
    paths.extend(ROOT / p for p in ['AminScatter/CMakeLists.txt', 'CyrusSurfaceAnalyzer/CMakeLists.txt'])
    items = [dict(path=p.relative_to(ROOT).as_posix(), size=p.stat().st_size,
                  sha256=digest(p)) for p in sorted(set(paths))]
    record('source-fingerprint.json', dict(captured_utc=stamp(), files=items))
    run_logged('git-status-before', ['git', 'status', '--porcelain=v1', '-uall'])
    run_logged('git-head', ['git', 'log', '-1', '--format=%H%n%cI%n%s'])
    run_logged('working-tree-diff', ['git', '-c', 'core.autocrlf=false', 'diff', '--no-ext-diff', '--binary'])
    print(f'Fingerprinted {len(items)} files')

def main():
    p = argparse.ArgumentParser()
    s = p.add_subparsers(dest='command', required=True)
    r = s.add_parser('read')
    r.add_argument('path')
    r.add_argument('--start', type=int, default=1)
    r.add_argument('--end', type=int)
    s.add_parser('snapshot')
    a = p.parse_args()
    if a.command == 'read':
        read_file(a.path, a.start, a.end)
    elif a.command == 'snapshot':
        snapshot()

if __name__ == '__main__':
    main()
