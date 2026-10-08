"""Compile-only painter/undo layout witnesses using the installed Max SDK."""
import argparse
import hashlib
import importlib.util
import json
import shutil
import subprocess
from pathlib import Path

SOURCE='''#include <max.h>
#include <IPainterInterface.h>
class ForestBrushCanvasProbe : public IPainterCanvasInterface_V5 {};
class ForestBrushPainterProbe : public IPainterInterface_V5 {};
class ForestBrushPainterV7Probe : public IPainterInterface_V7 {};
class ForestBrushRestoreProbe : public RestoreObj {};
int witness(){return sizeof(ForestBrushCanvasProbe)+sizeof(ForestBrushPainterProbe)+sizeof(ForestBrushPainterV7Probe)+sizeof(ForestBrushRestoreProbe);}
'''

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();output=args.output.resolve();repo=Path.cwd()
    if not output.is_relative_to(repo/'build'):raise ValueError('Use build')
    output.mkdir(parents=True,exist_ok=False)
    source=output/'witness.cpp';source.write_text(SOURCE,encoding='utf-8')
    spec=importlib.util.spec_from_file_location('build_max',repo/'tools/build_max.py')
    build=importlib.util.module_from_spec(spec);spec.loader.exec_module(build)
    env=build.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
    compiler=shutil.which('cl.exe',path=env.get('PATH',env.get('Path','')))
    sdk=repo/'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk/include'
    records=[]
    for name in ['ForestBrushCanvasProbe','ForestBrushPainterProbe','ForestBrushPainterV7Probe','ForestBrushRestoreProbe']:
        command=[compiler,'/nologo','/c','/std:c++17','/EHsc','/D_UNICODE','/DUNICODE','/DNOMINMAX','/I'+str(sdk),
            '/Fo'+str(output/(name+'.obj')),'/d1reportSingleClassLayout'+name,str(source)]
        r=subprocess.run(command,env=env,cwd=output,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        log=output/(name+'.txt');log.write_text(r.stdout,encoding='utf-8')
        records.append(dict(name=name,exit_code=r.returncode,log_sha256=hashlib.sha256(log.read_bytes()).hexdigest()))
    (output/'receipt.json').write_text(json.dumps(dict(compiler='MSVC 14.38.33130',sdk='Max 2027',linked=False,executed=False,records=records),indent=2),encoding='utf-8')
    print(json.dumps(records));raise SystemExit(next((r['exit_code'] for r in records if r['exit_code']),0))

if __name__=='__main__':main()
