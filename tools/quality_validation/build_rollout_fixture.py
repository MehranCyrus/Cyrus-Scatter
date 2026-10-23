"""Build the private Max 2027 rollout-order witness, outside product payloads."""
from pathlib import Path
import argparse,hashlib,json,subprocess,sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
import build_max

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--output',type=Path,required=True)
    output=parser.parse_args().output.resolve()
    if not output.is_relative_to(ROOT/'build'):raise ValueError('Owned build output required')
    output.mkdir(exist_ok=True,parents=True)
    vs=Path('C:/Program Files/Microsoft Visual Studio/2022/Community')
    env=build_max.compiler_environment(vs,'14.38.33130','10.0.19041.0')
    sdk=ROOT/'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk'
    source=Path(__file__).with_name('rollout_fixture.cpp');managed=Path(__file__).with_name('RolloutChecks.cs')
    runtime=Path('C:/Program Files/dotnet/shared/Microsoft.NETCore.App/10.0.0')
    commands=[[
        str(vs/'VC/Tools/MSVC/14.38.33130/bin/Hostx64/x64/cl.exe'),'/nologo','/LD','/MD','/EHsc','/std:c++20','/DNOMINMAX','/DUNICODE','/D_UNICODE',
        '/I'+str(sdk/'include'),'/Fo'+str(output/'rollout_fixture.obj'),str(source),'/link',
        '/OUT:'+str(output/'OwnedRolloutSdk.dll'),'/IMPLIB:'+str(output/'rollout_fixture.lib'),'/LIBPATH:'+str(sdk/'lib/x64/Release'),'core.lib','user32.lib'],[
        str(vs/'MSBuild/Current/Bin/Roslyn/csc.exe'),'/nologo','/noconfig','/nostdlib+','/target:library','/platform:x64',
        '/out:'+str(output/'RolloutOrderFixture.dll'),'/reference:'+str(runtime/'System.Private.CoreLib.dll'),'/reference:'+str(runtime/'System.Runtime.dll'),str(managed)]]
    for index,command in enumerate(commands):
        result=subprocess.run(command,env=env,text=True,capture_output=True)
        (output/f'rollout-fixture-{index}.log').write_text(result.stdout+result.stderr)
        if result.returncode:raise RuntimeError(result.stdout+result.stderr)
    paths=[source,managed,output/'OwnedRolloutSdk.dll',output/'RolloutOrderFixture.dll']
    (output/'rollout-fixture-build.json').write_text(json.dumps({'max_year':2027,'commands':commands,
        'sha256':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}},indent=2))
    print('Built private rollout fixture',output)

if __name__=='__main__':main()
