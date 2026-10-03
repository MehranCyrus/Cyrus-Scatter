"""Build the v1 product in isolated SDK-specific directories; no artist install."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'build/cyrus-v1'
sys.path.insert(0,str(ROOT/'tools'))
from build_max import compiler_environment

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--year',type=int,choices=(2026,2027),default=2027)
    parser.add_argument('--core-only',action='store_true')
    parser.add_argument('--skip-tests',action='store_true')
    args=parser.parse_args()
    output=BASE/('core' if args.core_only else f'max{args.year}')
    output.mkdir(parents=True,exist_ok=True)
    env=compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
    sdk=ROOT/f'build/tooling/max{args.year}-sdk/Program Files/Autodesk/3ds Max {args.year} SDK/maxsdk'
    commands=[['cmake','-S',str(ROOT/'AminScatter'),'-B',str(output),'-G','NMake Makefiles','-DCMAKE_BUILD_TYPE=Release',f'-DAMIN_BUILD_MAX={"OFF" if args.core_only else "ON"}',f'-DCYRUS_MAX_YEAR={args.year}',f'-DMAXSDK_ROOT={sdk}'],['cmake','--build',str(output)]]
    if not args.skip_tests:commands.append(['ctest','--test-dir',str(output),'--output-on-failure'])
    for i,command in enumerate(commands):
        result=subprocess.run(command,cwd=ROOT,env=env,capture_output=True,text=True)
        (output/f'build-{i}.log').write_text(result.stdout+result.stderr,encoding='utf-8')
        print((result.stdout+result.stderr)[-6000:],flush=True)
        result.check_returncode()
    (output/'identity.json').write_text(json.dumps({p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in output.glob('*.dl?')},indent=2))

if __name__=='__main__':main()
