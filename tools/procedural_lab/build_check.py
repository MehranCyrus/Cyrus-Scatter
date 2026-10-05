"""Build/test the 0.7 candidate without launching or installing 3ds Max."""
import argparse
import importlib.util
import hashlib
import json
from pathlib import Path
import subprocess

ROOT=Path(__file__).resolve().parents[2]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--max-year',type=int,choices=(2026,2027))
    parser.add_argument('--package',action='store_true',help='Stage an MZP candidate; never installs or launches Max.')
    parser.add_argument('--package-only',action='store_true',help='Repackage a script-only update after verifying previously tested native source/binaries.')
    args=parser.parse_args()
    args.package=args.package or args.package_only
    if args.package and not args.max_year:parser.error('--package requires --max-year')
    spec=importlib.util.spec_from_file_location('cyrus_build',ROOT/'tools/build_max.py')
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    env=module.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
    dest=ROOT/'build/procedural-07'/('core' if not args.max_year else f'max{args.max_year}')
    dest.mkdir(parents=True,exist_ok=True)
    configure=['cmake','-S',str(ROOT/'AminScatter'),'-B',str(dest),'-G','NMake Makefiles','-DCMAKE_BUILD_TYPE=Release']
    if args.max_year:
        sdk=ROOT/f'build/tooling/max{args.max_year}-sdk/Program Files/Autodesk/3ds Max {args.max_year} SDK/maxsdk'
        configure += ['-DAMIN_BUILD_MAX=ON',f'-DCYRUS_MAX_YEAR={args.max_year}',f'-DMAXSDK_ROOT={sdk}']
    else:configure += ['-DAMIN_BUILD_MAX=OFF']
    stages=[('configure',configure),('build',['cmake','--build',str(dest)]),('tests',['ctest','--test-dir',str(dest),'--output-on-failure'])]
    if args.package_only:
        evidence=json.loads((ROOT/'docs/Procedural_Implementation_0.7_2026-10-04/evidence.json').read_text())
        inputs={p.relative_to(ROOT).as_posix() for folder in ('src','include','tests') for p in (ROOT/'AminScatter'/folder).rglob('*') if p.is_file() and p.suffix in ('.cpp','.h','.inc','.rc')}
        inputs.add('AminScatter/CMakeLists.txt')
        if inputs!=set(evidence['native_source_sha256']):raise RuntimeError('Native input inventory changed; rebuild first.')
        for name,expected in evidence['native_source_sha256'].items():
            if hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=expected:raise RuntimeError('Native source changed; rebuild first: '+name)
        tested=next(b for b in evidence['native_builds'] if b['max_sdk']==args.max_year)
        for name,expected in tested['native_files'].items():
            if hashlib.sha256((dest/name).read_bytes()).hexdigest()!=expected:raise RuntimeError('Native binary changed; rebuild first: '+name)
        stages=[]
        print('Reusing verified native build and test evidence for script-only packaging.',flush=True)
    for label,command in stages:
        run=subprocess.run(command,cwd=ROOT,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        (dest/(label+'.log')).write_text(run.stdout,encoding='utf-8')
        print(f'{label}: {run.returncode}',flush=True)
        if run.returncode or label=='tests':print(run.stdout,flush=True)
        if run.returncode:raise SystemExit(run.returncode)
    if args.package:
        import shutil
        from types import SimpleNamespace
        staging=dest/'packaging'/'AminScatter';staging.mkdir(parents=True,exist_ok=True)
        natives=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
        for name in natives:shutil.copy2(dest/name,staging/name)
        options=SimpleNamespace(max_year=args.max_year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',
                                output=ROOT/'dist/procedural-0.7-candidate')
        module.package('AminScatter','Cyrus Scatter',module.scatter_version(),natives,'AminScatterObject.ms',options,staging.parent)

if __name__=='__main__':main()
