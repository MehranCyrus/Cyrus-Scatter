"""Compile a frozen core snapshot and diagnose redundant hard-stroke history cost."""
import argparse
import csv
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import statistics
import subprocess
import shutil

ROOT = Path(__file__).resolve().parents[4]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    run = args.output.resolve()
    run.mkdir(parents=True, exist_ok=False)
    sources = list((ROOT/'AminScatter/include').rglob('*.h'))
    sources += list((ROOT/'AminScatter/src').glob('*.cpp'))
    sources += list((ROOT/'AminScatter/src').glob('*.inc'))
    sources += [Path(__file__).with_suffix('.cpp')]
    hashes = {}
    for source in sources:
        relative = source.relative_to(ROOT)
        payload = source.read_bytes()
        destination = run/'snapshot'/relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(payload)
        hashes[relative.as_posix()] = hashlib.sha256(payload).hexdigest()
    receipt = {
        'qualification': 'Frozen native core CPU experiment only. No Forest, polygon engine, Max, overlay, memory peak or FPS timing.',
        'head': subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        'status_before': subprocess.check_output(['git','status','--short'],cwd=ROOT,text=True),
        'sources': hashes,
    }
    spec = importlib.util.spec_from_file_location('build_max',ROOT/'tools/build_max.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    env = module.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
    core = run/'snapshot/AminScatter'
    compiler = shutil.which('cl.exe',path=env['PATH'])
    if not compiler:
        raise RuntimeError('Configured C++ compiler not found')
    command = [compiler,'/nologo','/O2','/EHsc','/std:c++17',f'/I{core / "include"}']
    command += [str(core/'src'/f'{name}.cpp') for name in ['scatter','execution','brush','group_spacing','procedural','diagnostics']]
    command += [str(run/'snapshot'/Path(__file__).with_suffix('.cpp').relative_to(ROOT)),f'/Fe:{run / "probe.exe"}']
    compiled = subprocess.run(command,cwd=run,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (run/'compile.log').write_text(compiled.stdout,encoding='utf-8')
    receipt['command'] = command
    receipt['compile_exit'] = compiled.returncode
    if compiled.returncode:
        (run/'receipt.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
        raise RuntimeError(compiled.stdout)
    result = subprocess.run([str(run/'probe.exe')],cwd=run,text=True,capture_output=True,check=True)
    (run/'results.csv').write_text(result.stdout,encoding='utf-8')
    rows = list(csv.DictReader(io.StringIO(result.stdout)))
    summary = []
    for count in [1,10,100,1000]:
        selected = [row for row in rows if int(row['strokes'])==count and int(row['repeat'])>0]
        summary.append({'strokes':count,'queries':10000,'warm_repetitions':len(selected),
            'build_ms_median':statistics.median(float(row['build_ms']) for row in selected),
            'query_ms_median':statistics.median(float(row['query_ms']) for row in selected),
            'query_ms_range':[min(float(row['query_ms']) for row in selected),max(float(row['query_ms']) for row in selected)],
            'serialized_bytes':int(selected[0]['bytes']),'accepted':int(selected[0]['accepted']),
            'max_error':max(float(row['max_error']) for row in selected)})
    receipt['summary'] = summary
    receipt['source_changes_during_run'] = [name for name,digest in hashes.items() if hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=digest]
    (run/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(summary,indent=2))

if __name__=='__main__':
    main()
