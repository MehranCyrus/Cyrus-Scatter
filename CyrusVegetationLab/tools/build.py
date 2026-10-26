"""Build the independent Max 2027 lab; never install into Max."""
from pathlib import Path
import argparse, hashlib, importlib.util, json, shutil, subprocess

ROOT=Path(__file__).resolve().parents[2]
PROJECT=ROOT/'CyrusVegetationLab'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def sources():return {p.relative_to(PROJECT).as_posix():sha(p) for p in sorted(PROJECT.rglob('*')) if p.is_file() and '__pycache__' not in p.parts and (p.relative_to(PROJECT).parts[0] in ('core','src','include','scripts','tests') or p.name=='CMakeLists.txt')}
def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--output',type=Path,required=True);args=parser.parse_args()
    out=args.output.resolve()
    if out.exists():raise RuntimeError('Choose a fresh build directory')
    out.mkdir(parents=True)
    spec=importlib.util.spec_from_file_location('cvl_build_max',ROOT/'tools/build_max.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
    env=mod.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
    cmake=Path('C:/Users/Mehran/AppData/Local/Programs/Python/Python310/Scripts/cmake.exe');ctest=cmake.with_name('ctest.exe')
    sdk=ROOT/'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk'
    jolt=ROOT/'build/physics-lab-dependencies/jolt-1b2e77e3c6c09709e5edc79dc208459b8ff32051'
    receipt={'version':'0.1.0','host':2027,'status':'incomplete','source_hashes':sources(),'shared_source_hashes':{p:sha(ROOT/p) for p in ['cmake/CyrusMaxSDK.cmake','CyrusLicensing/third_party/nlohmann/json.hpp','CyrusLicensing/third_party/nlohmann/LICENSE.MIT']},'stages':[]}
    commands=[('configure',[cmake,'-S',PROJECT,'-B',out,'-G','Ninja','-DCMAKE_BUILD_TYPE=Release','-DCYRUS_MAX_YEAR=2027',f'-DMAXSDK_ROOT={sdk}',f'-DCYRUS_COLLISION_JOLT_SOURCE_ROOT={jolt}','-DBUILD_TESTING=ON','-DCMAKE_EXPORT_COMPILE_COMMANDS=ON']),('build',[cmake,'--build',out,'--parallel','6']),('tests',[ctest,'--test-dir',out,'--output-on-failure'])]
    for stage,cmd in commands:
        cmd=list(map(str,cmd));print(stage,flush=True)
        with (out/(stage+'.log')).open('w',encoding='utf-8') as log:
            done=subprocess.run(cmd,cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT)
        receipt['stages'].append({'stage':stage,'command':cmd,'exit_code':done.returncode});(out/'receipt.json').write_text(json.dumps(receipt,indent=2))
        if done.returncode:raise RuntimeError(f'{stage} failed; inspect {out/(stage+".log")}')
    if receipt['source_hashes']!=sources():raise RuntimeError('Source changed during build')
    receipt['binaries']={name:sha(out/name) for name in ['CyrusVegetationLab.dlx','CyrusVegetationStorage.dlh']}
    receipt['status']='complete';(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(out,flush=True)
if __name__=='__main__':main()
