from pathlib import Path
import argparse, hashlib, importlib.util, json, subprocess
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--output',type=Path,required=True);args=ap.parse_args();out=args.output.resolve();out.mkdir(parents=True,exist_ok=False)
    spec=importlib.util.spec_from_file_location('max_compiler',ROOT/'tools/build_max.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
    env=mod.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
    cmake=Path('C:/Users/Mehran/AppData/Local/Programs/Python/Python310/Scripts/cmake.exe')
    sdk=ROOT/'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk';jolt=ROOT/'build/physics-lab-dependencies/jolt-1b2e77e3c6c09709e5edc79dc208459b8ff32051'
    sources={str(p.relative_to(ROOT)):sha(p) for base in (HERE,ROOT/'CyrusVegetationLab/core') for p in base.rglob('*') if p.is_file() and p.suffix in ('.cpp','.hpp','.h','.cmake','.sha256','.py') or p.is_file() and p.name=='CMakeLists.txt'}
    receipt={'scope':'private dense live experiment; not a product release','host':2027,'sources':sources,'stages':[],'status':'incomplete'}
    for stage,cmd in [('configure',[cmake,'-S',HERE,'-B',out,'-G','Ninja','-DCMAKE_BUILD_TYPE=Release','-DCYRUS_MAX_YEAR=2027',f'-DMAXSDK_ROOT={sdk}',f'-DCYRUS_COLLISION_JOLT_SOURCE_ROOT={jolt}']),('build',[cmake,'--build',out,'--parallel','6']),('tests',[cmake.with_name('ctest.exe'),'--test-dir',out,'--output-on-failure'])]:
        print(stage,flush=True)
        with (out/(stage+'.log')).open('w',encoding='utf-8') as log:r=subprocess.run(list(map(str,cmd)),cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT)
        receipt['stages'].append({'stage':stage,'command':list(map(str,cmd)),'exit_code':r.returncode});(out/'probe-receipt.json').write_text(json.dumps(receipt,indent=2))
        if r.returncode:raise RuntimeError(stage+' failed: '+str(out))
    for name,expected in sources.items():
        if sha(ROOT/name)!=expected:raise RuntimeError('Native source changed during build: '+name)
    receipt.update(status='complete',binary_sha256=sha(out/'CyrusDenseVegetationProbe.dlx'));(out/'probe-receipt.json').write_text(json.dumps(receipt,indent=2));print(out,flush=True)
if __name__=='__main__':main()
