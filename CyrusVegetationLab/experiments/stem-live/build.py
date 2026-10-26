from pathlib import Path
import argparse,hashlib,importlib.util,json,subprocess
ROOT=Path(__file__).resolve().parents[3];HERE=Path(__file__).resolve().parent
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--output',required=True,type=Path);args=ap.parse_args();out=args.output.resolve();out.mkdir(parents=True,exist_ok=False)
    spec=importlib.util.spec_from_file_location('stem_compiler',ROOT/'tools/build_max.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
    env=mod.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
    cmake=Path('C:/Users/Mehran/AppData/Local/Programs/Python/Python310/Scripts/cmake.exe');sdk=ROOT/'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk'
    sources={str(p.relative_to(ROOT)):sha(p) for p in HERE.rglob('*') if p.is_file() and p.suffix in ('.cpp','.hpp','.inl','.txt') and '__pycache__' not in p.parts}
    dependencies={str(p.relative_to(ROOT)):sha(p) for p in [ROOT/'build/vegetation-dense-probe-20261024-06/collision/cyrus_vegetation_collision.lib',ROOT/'build/vegetation-dense-probe-20261024-06/collision/jolt/Jolt.lib',ROOT/'build/vegetation-dense-probe-20261024-06/fitter/cyrus_vegetation_fitter.lib',ROOT/'CyrusVegetationLab/core/include/cyrus_vegetation/prototype_v1.hpp',ROOT/'CyrusVegetationLab/core/fitter/private/math.hpp',ROOT/'CyrusVegetationLab/core/delivery/src/geometry.hpp',ROOT/'CyrusLicensing/third_party/nlohmann/json.hpp',ROOT/'cmake/CyrusMaxSDK.cmake']}
    receipt={'dependencies':dependencies,'product':'Vegetation Stem Lab','version':'0.3.1','host':2027,'status':'incomplete','sources':sources,'stages':[]}
    for stage,cmd in [('configure',[cmake,'-S',HERE,'-B',out,'-G','Ninja','-DCMAKE_BUILD_TYPE=Release','-DCYRUS_MAX_YEAR=2027',f'-DMAXSDK_ROOT={sdk}']),('build',[cmake,'--build',out,'--parallel','6'])]:
        print(stage,flush=True)
        with (out/(stage+'.log')).open('w',encoding='utf-8') as log:r=subprocess.run(list(map(str,cmd)),cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT)
        receipt['stages'].append({'stage':stage,'exit_code':r.returncode,'command':list(map(str,cmd))});(out/'receipt.json').write_text(json.dumps(receipt,indent=2))
        if r.returncode:raise RuntimeError(f'{stage} failed: {out}')
    for name,expected in {**sources,**dependencies}.items():
        if sha(ROOT/name)!=expected:raise RuntimeError('Native input changed during build: '+name)
    receipt.update(status='complete',binaries={p.name:sha(p) for p in out.iterdir() if p.suffix in ('.dlx','.dlo')});(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(out,flush=True)
if __name__=='__main__':main()
