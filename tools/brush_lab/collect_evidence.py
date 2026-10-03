"""Collect concise, validated fixture results; leave scenes/binaries in build/."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
from build import ROOT, BASE


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--primary',required=True)
    parser.add_argument('--final',required=True)
    args=parser.parse_args()
    for run in (args.primary,args.final):
        if not re.fullmatch(r'[a-z0-9-]+',run):
            raise SystemExit('Use a lowercase run name')
    output=ROOT/'docs/Brush_Tool_2026-10-02/evidence/2026-10-03'
    output.mkdir(parents=True,exist_ok=True)
    verification=json.loads((BASE/args.primary/'verification.json').read_text())
    reopen=json.loads((BASE/args.final/'reopen.json').read_text())
    final=json.loads((BASE/args.final/'final.json').read_text())
    for key in ('flat_rows','curved_rows','flat_signature','curved_signature'):
        if not verification[key]==reopen[key]==final[key]:
            raise SystemExit(f'Persistence mismatch: {key}')
    for run,names in (
        (args.primary,('ready','identity','picking','verification','manual-erase','lifecycle')),
        (args.final,('ready','identity','reopen','cancel','lifecycle','final')),
    ):
        for name in names:
            value=json.loads((BASE/run/f'{name}.json').read_text())
            (output/f'{run}-{name}.json').write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')
        identity=json.loads((BASE/run/'identity.json').read_text())
        for name,expected in identity.items():
            actual=hashlib.sha256((BASE/run/'bin'/name).read_bytes()).hexdigest()
            if actual!=expected:
                raise SystemExit(f'Binary changed after launch: {run}/{name}')
    for year in (2026,2027):
        result=(BASE/f'max{year}/build-2.log').read_text()
        if '100% tests passed, 0 tests failed out of 11' not in result:
            raise SystemExit(f'Missing passing native suites for {year}')
        (output/f'max{year}-native-tests.txt').write_text(result,encoding='utf-8')
        identity=(BASE/f'max{year}/identity.json').read_text()
        (output/f'max{year}-final-binaries.json').write_text(identity,encoding='utf-8')
    raw=(BASE/'history.csv').read_bytes()
    history=raw.decode('utf-16' if raw.startswith(b'\xff\xfe') else 'utf-8-sig')
    (output/'history.csv').write_text(history,encoding='utf-8')
    paths=[ROOT/'AminScatter/CMakeLists.txt',ROOT/'AminScatter/include/brush.h',ROOT/'AminScatter/src/brush.cpp',ROOT/'AminScatter/src/brush_lab.cpp',ROOT/'AminScatter/src/brush_storage_plugin.cpp',ROOT/'AminScatter/tests/brush_tests.cpp',ROOT/'AminScatter/tests/data/brush_sphere_pole.txt']
    paths.extend(p for p in (ROOT/'tools/brush_lab').iterdir() if p.is_file())
    manifest={str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)}
    record={'base_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'primary_run':args.primary,'final_run':args.final,'fresh_process_signatures_match':True,'source_sha256':manifest,'scope':'Primary behavioral suite precedes the host-only right-click handler. Final run verifies the handler, lifecycle and fresh-process reconstruction. Native core source is identical.'}
    (output/'manifest.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
    print(f'Validated signatures, binary hashes and native suite logs; evidence: {output}')


if __name__=='__main__':
    main()
