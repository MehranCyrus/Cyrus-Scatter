"""Owned 0.86.7 SDK builds. No packaging, installation or artist host access."""
from pathlib import Path
import argparse
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
import build_max

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--year',type=int,choices=(2024,2026,2027),required=True)
    p.add_argument('--configure',action='store_true')
    p.add_argument('--targets',nargs='+')
    a=p.parse_args()
    dest=ROOT/f'build/viewport-0867-20261020/max{a.year}'
    dest.mkdir(parents=True,exist_ok=True)
    sdk=ROOT/f'build/tooling/max{a.year}-sdk/Program Files/Autodesk/3ds Max {a.year} SDK/maxsdk'
    env=build_max.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
    commands=[]
    if a.configure or not (dest/'CMakeCache.txt').exists():
        commands.append(('configure',['cmake','-S',str(ROOT/'AminScatter'),'-B',str(dest),'-G','NMake Makefiles',
            '-DCMAKE_BUILD_TYPE=Release',f'-DCYRUS_MAX_YEAR={a.year}',f'-DMAXSDK_ROOT={sdk}',
            '-DCYRUS_TEAM_LICENSE=ON',f'-DCYRUS_TEAM_TRUST_DIR={ROOT/"CyrusLicensing/team"}',
            '-DCYRUS_NATIVE_LICENSE_EXPERIMENT=OFF','-DCYRUS_LICENSE_INSTALLATION_CONTEXT=OFF']))
    commands.append(('build',['cmake','--build',str(dest),*(['--target',*a.targets] if a.targets else [])]))
    for label,command in commands:
        with (dest/f'{label}.log').open('w',encoding='utf-8') as log:
            result=subprocess.run(command,cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT)
        print(label,result.returncode,flush=True)
        if result.returncode:
            print((dest/f'{label}.log').read_text(encoding='utf-8')[-12000:]);return result.returncode
    return 0

if __name__=='__main__':
    raise SystemExit(main())
