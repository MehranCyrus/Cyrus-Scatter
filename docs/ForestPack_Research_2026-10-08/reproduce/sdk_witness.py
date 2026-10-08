"""Compile-only Max 2027 ABI witnesses for selected virtual calls."""
import argparse
import hashlib
import importlib.util
import json
import shutil
import subprocess
from pathlib import Path


SOURCE = '''#include <max.h>
#include <iparamb2.h>
#include <iparamm2.h>
#include <Graphics/ICustomRenderItem.h>
#include <Graphics/IVirtualDevice.h>
#include <Graphics/DrawContext.h>
class ForestCustomItemProbe : public MaxSDK::Graphics::ICustomRenderItem { public: ~ForestCustomItemProbe() override = default; };
class ForestVirtualDeviceProbe : public MaxSDK::Graphics::IVirtualDevice { public: ~ForestVirtualDeviceProbe() override = default; };
class ForestParamMapProbe : public IParamMap2 { public: ~ForestParamMapProbe() override = default; };
class ForestParamBlockProbe : public IParamBlock2 { public: ~ForestParamBlockProbe() override = default; };
int witness() { return sizeof(ForestCustomItemProbe)+sizeof(ForestVirtualDeviceProbe)+sizeof(ForestParamMapProbe)+sizeof(ForestParamBlockProbe); }
'''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output',type=Path,required=True)
    args = parser.parse_args()
    repo = Path.cwd()
    output = args.output.resolve()
    if not output.is_relative_to(repo/'build'): raise ValueError('Use ignored build/')
    output.mkdir(parents=True,exist_ok=False)
    source = output/'witness.cpp'
    source.write_text(SOURCE,encoding='utf-8')
    spec = importlib.util.spec_from_file_location('build_max',repo/'tools/build_max.py')
    build = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(build)
    environment = build.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
    compiler = shutil.which('cl.exe',path=environment.get('PATH',environment.get('Path','')))
    if not compiler: raise RuntimeError('Existing compiler unavailable')
    sdk = repo/'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk/include'
    records = []
    for name in ['ForestCustomItemProbe','ForestVirtualDeviceProbe','ForestParamMapProbe','ForestParamBlockProbe']:
        command = [compiler,'/nologo','/c','/std:c++17','/EHsc','/D_UNICODE','/DUNICODE','/DNOMINMAX',
                   '/I'+str(sdk),'/Fo'+str(output/(name+'.obj')),'/d1reportSingleClassLayout'+name,str(source)]
        result = subprocess.run(command,env=environment,cwd=output,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        log = output/(name+'.txt')
        log.write_text(result.stdout,encoding='utf-8')
        records.append(dict(name=name,command=command,exit_code=result.returncode,log_sha256=hashlib.sha256(log.read_bytes()).hexdigest()))
    receipt = dict(compiler='MSVC 14.38.33130',sdk='Max 2027 local headers',linked=False,executed=False,records=records)
    (output/'receipt.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
    print(json.dumps([(x['name'],x['exit_code']) for x in records]))
    raise SystemExit(next((x['exit_code'] for x in records if x['exit_code']),0))


if __name__ == '__main__': main()
