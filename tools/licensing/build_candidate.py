"""Freeze, build and test licensed native modules; never install into artist Max."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from build_max import compiler_environment

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--year',type=int,choices=(2026,2027),required=True)
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--trust-header',type=Path,required=True)
    a=p.parse_args();out=a.output.resolve();out.mkdir(parents=True,exist_ok=False)
    source=out/'source';records={}
    names=subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','--',
        'AminScatter','CyrusLicensing','cmake'],cwd=ROOT,text=True).splitlines()
    for name in sorted(set(names)):
        data=(ROOT/name).read_bytes();dest=source/name;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
        records[name]=hashlib.sha256(data).hexdigest()
    trust=out/'trust';trust.mkdir();shutil.copy2(a.trust_header,trust/'team_public_key.h')
    records['team_public_key.h']=hashlib.sha256((trust/'team_public_key.h').read_bytes()).hexdigest()
    (out/'source.json').write_text(json.dumps(records,indent=2)+'\n')
    env=compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
    sdk=ROOT/f'build/tooling/max{a.year}-sdk/Program Files/Autodesk/3ds Max {a.year} SDK/maxsdk'
    steps=[('configure',['cmake','-S',source/'AminScatter','-B',out/'native','-G','NMake Makefiles',
        '-DCMAKE_BUILD_TYPE=Release',f'-DCYRUS_MAX_YEAR={a.year}',f'-DMAXSDK_ROOT={sdk}',
        '-DCYRUS_TEAM_LICENSE=ON',f'-DCYRUS_TEAM_TRUST_DIR={trust}','-DCYRUS_NATIVE_LICENSE_EXPERIMENT=OFF']),
        ('build',['cmake','--build',out/'native']),
        ('tests',['ctest','--test-dir',out/'native','--output-on-failure'])]
    for label,command in steps:
        with (out/(label+'.log')).open('w',encoding='utf-8') as log:
            result=subprocess.run(list(map(str,command)),env=env,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
        print(label+': '+str(result.returncode),flush=True)
        if result.returncode:
            print((out/(label+'.log')).read_text(encoding='utf-8')[-8000:]);raise SystemExit(result.returncode)
    receipt={'year':a.year,'licensed':True,'host_tested':False,'installed':False,
        'files':{f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in (out/'native').glob('*.dl?')}}
    (out/'build.json').write_text(json.dumps(receipt,indent=2)+'\n')
    print(json.dumps(receipt),flush=True)

if __name__=='__main__':main()
