"""Compile-only SDK type/field witnesses; no link, install or execution."""
import argparse
import hashlib
import importlib.util
import json
import shutil
import subprocess
from pathlib import Path

SOURCE='''#include <max.h>
#include <triobj.h>
#include <paramtype.h>
static_assert(TYPE_POINT3_TAB == 0x803);
static_assert(TYPE_POINT4_TAB == 0x816);
static_assert(TYPE_INT_TAB == 0x801);
static_assert(TYPE_INODE_TAB == 0x811);
int witness(const Mesh &m){return m.getNumFaces()+sizeof(TriObject);}
'''

def main():
    p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True)
    a=p.parse_args();root=Path(__file__).resolve().parents[3];out=a.output.resolve()
    assert out.is_relative_to(root/'build');out.mkdir(parents=True,exist_ok=False)
    source=out/'witness.cpp';source.write_text(SOURCE,encoding='utf-8')
    spec=importlib.util.spec_from_file_location('build_max',root/'tools/build_max.py')
    build=importlib.util.module_from_spec(spec);spec.loader.exec_module(build)
    env=build.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
    compiler=shutil.which('cl.exe',path=env.get('PATH',env.get('Path','')))
    sdk=root/'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk/include'
    records=[]
    for name in ['Mesh','TriObject','BlockWrite_Value']:
        cmd=[compiler,'/nologo','/c','/std:c++17','/EHsc','/D_UNICODE','/DUNICODE','/DNOMINMAX','/I'+str(sdk),
             '/Fo'+str(out/(name+'.obj')),'/d1reportSingleClassLayout'+name,str(source)]
        result=subprocess.run(cmd,env=env,cwd=out,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        log=out/(name+'.txt');log.write_text(result.stdout,encoding='utf-8')
        records.append(dict(name=name,command=cmd,exit_code=result.returncode,log_sha256=hashlib.sha256(log.read_bytes()).hexdigest()))
    receipt=dict(compiler='MSVC 14.38.33130',sdk='Max 2027',exit_code=max(r['exit_code'] for r in records),linked=False,executed=False,
                 records=records,source_sha256=hashlib.sha256(source.read_bytes()).hexdigest())
    (out/'receipt.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
    print(json.dumps(receipt));raise SystemExit(receipt['exit_code'])

if __name__=='__main__':main()
